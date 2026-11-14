import 'dart:math';
import 'dart:typed_data';

import '../theory/note.dart';
import 'note_listener.dart';
import 'pitch_detector.dart';

const _historySize = 8192;
const _onsetFftSize = 2048;
const _fluxBinHz = sampleRate / _onsetFftSize;
const _fluxMinFrequency = 80.0;
const _fluxMaxFrequency = 5000.0;
const _fluxThreshold = 0.2;
const _attackRatio = 1.2;
const _verdictDelayHops = 32;
const _peakBinHz = sampleRate / _historySize;
const _peakMinFrequency = 75.0;
const _peakMaxFrequency = 1100.0;
const _logFloor = 1e-30;
const _presentRangeDb = 30.0;
const _extraRangeDb = 26.0;
const _maxExtraMidi = 76;
const _harmonicOffsets = {12, 19, 24, 28, 31, 34, 36};

final _fluxFirstBin = (_fluxMinFrequency / _fluxBinHz).ceil();
final _fluxBinCount = _fluxMaxFrequency ~/ _fluxBinHz - _fluxFirstBin + 1;

class StrumEvent {
  final Set<int> missing;
  final Set<int> extra;
  final double time;

  const StrumEvent(this.missing, this.extra, this.time);

  bool get correct => missing.isEmpty && extra.isEmpty;
}

class StrumDetector {
  static final _onsetFft = _Fft(_onsetFftSize);
  static final _verdictFft = _Fft(_historySize);

  final List<int> notes;
  final void Function(StrumEvent) onStrum;

  final _history = Float64List(_historySize);
  var _filled = 0;
  var _sampleCount = 0;
  final _fluxRing = List.generate(
    attackLagFrames,
    (_) => Float64List(_fluxBinCount),
  );
  final _rmsRing = Float64List(attackLagFrames);
  var _ringIndex = 0;
  var _wasOnset = false;
  var _verdictCountdown = 0;

  StrumDetector({required this.notes, required this.onStrum});

  void addSamples(Float64List samples) {
    var offset = 0;
    while (offset < samples.length) {
      final count = min(hopSize - _filled, samples.length - offset);
      final start = _historySize - hopSize + _filled;
      _history.setRange(start, start + count, samples, offset);
      _filled += count;
      offset += count;
      _sampleCount += count;
      if (_filled == hopSize) {
        _processHop();
        _history.setRange(0, _historySize - hopSize, _history, hopSize);
        _filled = 0;
      }
    }
  }

  void reset() {
    _history.fillRange(0, _historySize, 0);
    _filled = 0;
    for (final magnitudes in _fluxRing) {
      magnitudes.fillRange(0, _fluxBinCount, 0);
    }
    _rmsRing.fillRange(0, attackLagFrames, 0);
    _wasOnset = false;
    _verdictCountdown = 0;
  }

  void _processHop() {
    final flux = _flux();
    final rms = _rms(windowSize);
    final onset =
        flux >= _fluxThreshold &&
        _toDb(rms) >= gateDb &&
        rms >= _attackRatio * _rmsRing[_ringIndex];
    _rmsRing[_ringIndex] = rms;
    _ringIndex = (_ringIndex + 1) % attackLagFrames;

    final rising = onset && !_wasOnset;
    _wasOnset = onset;
    if (_verdictCountdown > 0) {
      _verdictCountdown--;
      if (_verdictCountdown == 0) _verdict();
    } else if (rising) {
      _verdictCountdown = _verdictDelayHops;
    }
  }

  double _flux() {
    final magnitudes = _onsetFft.magnitudes(_history);
    final past = _fluxRing[_ringIndex];
    var rise = 0.0;
    var total = 0.0;
    for (var i = 0; i < _fluxBinCount; i++) {
      final magnitude = sqrt(magnitudes[_fluxFirstBin + i]);
      rise += max(0.0, magnitude - past[i]);
      total += magnitude;
      past[i] = magnitude;
    }
    return rise / total;
  }

  double _rms(int count) {
    var sum = 0.0;
    for (var i = _historySize - count; i < _historySize; i++) {
      sum += _history[i] * _history[i];
    }
    return sqrt(sum / count);
  }

  double _toDb(double rms) => 20 * log(rms) / ln10;

  void _verdict() {
    if (_toDb(_rms(_historySize)) < gateDb) return;
    final peaks = _peaks();
    if (peaks.isEmpty) return;

    final strongest = peaks.values.reduce(max);
    final pitchClasses = {for (final note in notes) note % 12};
    final present = {
      for (final note in notes)
        if (_isPresent(note, peaks, strongest - _presentRangeDb)) note % 12,
    };
    final extra = {
      for (final MapEntry(key: midi, value: level) in peaks.entries)
        if (midi <= _maxExtraMidi &&
            level >= strongest - _extraRangeDb &&
            !pitchClasses.contains(midi % 12) &&
            !_isHarmonic(midi, notes))
          midi % 12,
    };
    onStrum(
      StrumEvent(
        pitchClasses.difference(present),
        extra,
        _sampleCount / sampleRate,
      ),
    );
  }

  Map<int, double> _peaks() {
    final magnitudes = _verdictFft.magnitudes(_history);
    final peaks = <int, double>{};
    final end = _peakMaxFrequency ~/ _peakBinHz;
    for (var i = _peakMinFrequency ~/ _peakBinHz; i < end; i++) {
      if (magnitudes[i] > magnitudes[i - 1] &&
          magnitudes[i] >= magnitudes[i + 1]) {
        final a = log(magnitudes[i - 1] + _logFloor);
        final b = log(magnitudes[i] + _logFloor);
        final c = log(magnitudes[i + 1] + _logFloor);
        final d = 0.5 * (a - c) / (a - 2 * b + c);
        final midi = frequencyToNote((i + d) * _peakBinHz).midi;
        final level = 20 * (b - 0.25 * (a - c) * d) / ln10;
        peaks[midi] = max(level, peaks[midi] ?? level);
      }
    }
    return peaks;
  }

  bool _isPresent(int note, Map<int, double> peaks, double floor) {
    if ((peaks[note] ?? double.negativeInfinity) >= floor) return true;
    final octave = note + 12;
    return (peaks[octave] ?? double.negativeInfinity) >= floor &&
        !_isHarmonic(octave, notes.where((other) => other % 12 != note % 12));
  }

  bool _isHarmonic(int midi, Iterable<int> sources) =>
      sources.any((source) => _harmonicOffsets.contains(midi - source));
}

class _Fft {
  final int size;
  final Float64List _window;
  final Float64List _cos;
  final Float64List _sin;
  final Int32List _reversed;
  final Float64List _real;
  final Float64List _imaginary;
  final Float64List _magnitudes;

  _Fft(this.size)
    : _window = Float64List(size),
      _cos = Float64List(size ~/ 2),
      _sin = Float64List(size ~/ 2),
      _reversed = Int32List(size),
      _real = Float64List(size),
      _imaginary = Float64List(size),
      _magnitudes = Float64List(size ~/ 2 + 1) {
    for (var i = 0; i < size; i++) {
      _window[i] = 0.5 - 0.5 * cos(2 * pi * i / size);
    }
    for (var i = 0; i < size ~/ 2; i++) {
      _cos[i] = cos(2 * pi * i / size);
      _sin[i] = sin(2 * pi * i / size);
    }
    var reversed = 0;
    for (var i = 1; i < size; i++) {
      var bit = size >> 1;
      while (reversed & bit != 0) {
        reversed ^= bit;
        bit >>= 1;
      }
      reversed ^= bit;
      _reversed[i] = reversed;
    }
  }

  Float64List magnitudes(Float64List history) {
    final start = history.length - size;
    for (var i = 0; i < size; i++) {
      _real[_reversed[i]] = history[start + i] * _window[i];
    }
    _imaginary.fillRange(0, size, 0);

    for (var half = 1; half < size; half *= 2) {
      final stride = size ~/ (2 * half);
      for (var block = 0; block < size; block += 2 * half) {
        for (var k = 0; k < half; k++) {
          final twiddleCos = _cos[k * stride];
          final twiddleSin = _sin[k * stride];
          final top = block + k;
          final bottom = top + half;
          final real =
              twiddleCos * _real[bottom] + twiddleSin * _imaginary[bottom];
          final imaginary =
              twiddleCos * _imaginary[bottom] - twiddleSin * _real[bottom];
          _real[bottom] = _real[top] - real;
          _imaginary[bottom] = _imaginary[top] - imaginary;
          _real[top] += real;
          _imaginary[top] += imaginary;
        }
      }
    }

    for (var i = 0; i <= size ~/ 2; i++) {
      _magnitudes[i] = sqrt(
        _real[i] * _real[i] + _imaginary[i] * _imaginary[i],
      );
    }
    return _magnitudes;
  }
}
