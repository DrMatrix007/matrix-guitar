import 'dart:typed_data';

const sampleRate = 44100;
const windowSize = 1536;
const hopSize = 512;
const attackLagFrames = 2048 ~/ hopSize;

const _minFrequency = 70.0;
const _maxFrequency = 1500.0;
const _threshold = 0.15;
const _octaveSearchRadius = 3;
const _octaveDifferenceRatio = 0.3;
const _octaveMinCmnd = 0.03;

class PitchDetector {
  static final _tauMin = (sampleRate / _maxFrequency).floor();
  static final _tauMax = (sampleRate / _minFrequency).ceil();

  final _differenceBuffer = Float64List(_tauMax + 1);
  final _cmndBuffer = Float64List(_tauMax + 1);

  double? detect(Float64List frame) {
    final difference = _difference(frame);
    final cmnd = _cumulativeMeanNormalized(difference);
    final tau = _firstDip(cmnd);
    if (tau == null) return null;
    return sampleRate / _interpolate(cmnd, _octaveGuard(difference, cmnd, tau));
  }

  Float64List _difference(Float64List frame) {
    final difference = _differenceBuffer;
    final width = windowSize - _tauMax;
    for (var tau = 1; tau <= _tauMax; tau++) {
      var sum = 0.0;
      for (var i = 0; i < width; i++) {
        final delta = frame[i] - frame[i + tau];
        sum += delta * delta;
      }
      difference[tau] = sum;
    }
    return difference;
  }

  Float64List _cumulativeMeanNormalized(Float64List difference) {
    final cmnd = _cmndBuffer;
    var runningSum = 0.0;
    for (var tau = 1; tau <= _tauMax; tau++) {
      runningSum += difference[tau];
      cmnd[tau] = runningSum == 0 ? 1 : difference[tau] * tau / runningSum;
    }
    return cmnd;
  }

  int? _firstDip(Float64List cmnd) {
    for (var tau = _tauMin; tau < _tauMax; tau++) {
      if (cmnd[tau] < _threshold) {
        var best = tau;
        while (tau + 1 < _tauMax && cmnd[tau + 1] < _threshold) {
          tau++;
          if (cmnd[tau] < cmnd[best]) best = tau;
        }
        return best;
      }
    }
    return null;
  }

  int _octaveGuard(Float64List difference, Float64List cmnd, int tau) {
    if (2 * tau + _octaveSearchRadius >= _tauMax ||
        cmnd[tau] < _octaveMinCmnd) {
      return tau;
    }
    var doubled = 2 * tau - _octaveSearchRadius;
    for (var t = doubled; t <= 2 * tau + _octaveSearchRadius; t++) {
      if (difference[t] < difference[doubled]) doubled = t;
    }
    return difference[doubled] / difference[tau] < _octaveDifferenceRatio
        ? doubled
        : tau;
  }

  double _interpolate(Float64List cmnd, int tau) {
    final before = cmnd[tau - 1];
    final after = cmnd[tau + 1];
    final curvature = before - 2 * cmnd[tau] + after;
    return curvature == 0
        ? tau.toDouble()
        : tau + 0.5 * (before - after) / curvature;
  }
}
