import 'dart:math';
import 'dart:typed_data';

import '../theory/note.dart';
import 'pitch_detector.dart';

const gateDb = -45.0;
const _confirmFrames = 3;
const _attackRatio = 2.0;
const _phantomIntervals = {12, 19, 24};

class NoteEvent {
  final int midi;
  final double cents;
  final double time;

  const NoteEvent(this.midi, this.cents, this.time);
}

class FrameReading {
  final double levelDb;
  final int? midi;
  final double? cents;

  const FrameReading({required this.levelDb, this.midi, this.cents});
}

class NoteListener {
  final void Function(NoteEvent) onNote;
  final void Function(FrameReading) onReading;
  int? expectedMidi;

  final _detector = PitchDetector();
  final _frame = Float64List(windowSize);
  var _filled = 0;
  var _sampleCount = 0;
  final _rmsRing = Float64List(attackLagFrames);
  var _rmsIndex = 0;
  var _wasAttacking = false;
  int? _heldMidi;
  int? _confirmingMidi;
  var _confirmCount = 0;
  var _confirmCentsSum = 0.0;

  NoteListener({required this.onNote, required this.onReading});

  void addSamples(Float64List samples) {
    var offset = 0;
    while (offset < samples.length) {
      final count = min(windowSize - _filled, samples.length - offset);
      _frame.setRange(_filled, _filled + count, samples, offset);
      _filled += count;
      offset += count;
      _sampleCount += count;
      if (_filled == windowSize) {
        _processFrame();
        _frame.setRange(0, windowSize - hopSize, _frame, hopSize);
        _filled = windowSize - hopSize;
      }
    }
  }

  void reset() {
    _filled = 0;
    _rmsRing.fillRange(0, attackLagFrames, 0);
    _heldMidi = null;
    _confirmCount = 0;
  }

  void _processFrame() {
    final rms = _frameRms();
    final levelDb = 20 * log(rms) / ln10;
    final audible = levelDb >= gateDb;
    final frequency = audible ? _detector.detect(_frame) : null;
    final note = frequency == null ? null : frequencyToNote(frequency);
    onReading(
      FrameReading(levelDb: levelDb, midi: note?.midi, cents: note?.cents),
    );

    final past = _rmsRing[_rmsIndex];
    final attacking = audible && rms >= _attackRatio * past;
    if (attacking && !_wasAttacking) _heldMidi = null;
    _wasAttacking = attacking;
    _rmsRing[_rmsIndex] = rms;
    _rmsIndex = (_rmsIndex + 1) % attackLagFrames;

    if (note == null || note.midi == _heldMidi) {
      _confirmCount = 0;
    } else {
      _confirm(note.midi, note.cents);
    }
  }

  double _frameRms() {
    var sum = 0.0;
    for (final sample in _frame) {
      sum += sample * sample;
    }
    return sqrt(sum / windowSize);
  }

  void _confirm(int midi, double cents) {
    if (midi != _confirmingMidi || _confirmCount == 0) {
      _confirmingMidi = midi;
      _confirmCount = 0;
      _confirmCentsSum = 0;
    }
    _confirmCount++;
    _confirmCentsSum += cents;
    if (_confirmCount < _confirmFrames) return;

    _confirmCount = 0;
    if (_isPhantom(midi)) return;
    _heldMidi = midi;
    onNote(
      NoteEvent(
        midi,
        _confirmCentsSum / _confirmFrames,
        _sampleCount / sampleRate,
      ),
    );
  }

  bool _isPhantom(int midi) {
    final held = _heldMidi;
    return held != null &&
        midi != expectedMidi &&
        _phantomIntervals.contains((midi - held).abs());
  }
}
