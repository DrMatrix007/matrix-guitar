import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/audio/debug_tone_source.dart';
import 'package:matrix_guitar/audio/pitch_detector.dart';
import 'package:matrix_guitar/theory/note.dart';

import '../helpers/signals.dart';

Iterable<Float64List> frames(Float64List samples) sync* {
  for (var i = 0; i + windowSize <= samples.length; i += hopSize) {
    yield samples.sublist(i, i + windowSize);
  }
}

const attackOffsets = [0, 997, 1994, 2991, 3988, 4985];

void main() {
  final detector = PitchDetector();

  test('P1 a 440 Hz sine reads 440 Hz and synthPluck agrees', () {
    final independent = sine(440).sublist(0, windowSize);
    final synthesized = synthPluck(
      midi: 69,
      harmonics: pureProfile,
      decay: 0,
    ).sublist(0, windowSize);

    expect(detector.detect(independent), closeTo(440, 0.5));
    expect(detector.detect(synthesized), closeTo(440, 0.5));
  });

  test('P2 attack frames read the exact semitone within 8 cents', () {
    const notes = [
      40,
      45,
      49,
      50,
      55,
      57,
      59,
      60,
      64,
      67,
      72,
      73,
      76,
      78,
      86,
      87,
      88,
    ];
    const profiles = {
      'pure': pureProfile,
      'guitar': guitarProfile,
      'weak': weakProfile,
      'hard': hardProfile,
    };

    for (final midi in notes) {
      for (final MapEntry(key: name, value: harmonics) in profiles.entries) {
        for (final noise in [0.0, 0.002, 0.02]) {
          final label = 'midi $midi, $name, noise $noise';
          final pluck = synthPluck(
            midi: midi,
            harmonics: harmonics,
            noise: noise,
          );
          for (final offset in attackOffsets) {
            final frequency = detector.detect(
              pluck.sublist(offset, offset + windowSize),
            );
            expect(frequency, isNotNull, reason: label);
            final note = frequencyToNote(frequency!);
            expect(note.midi, midi, reason: label);
            expect(note.cents.abs(), lessThanOrEqualTo(8), reason: label);
          }
        }
      }
    }
  });

  test('P3 zeros and white noise return null', () {
    expect(detector.detect(Float64List(windowSize)), isNull);

    for (var seed = 1; seed <= 5; seed++) {
      for (final frame in frames(whiteNoise(seed: seed))) {
        expect(detector.detect(frame), isNull, reason: 'seed $seed');
      }
    }
  });
}
