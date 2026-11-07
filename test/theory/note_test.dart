import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/theory/note.dart';

double centsAbove(int midi, double cents) =>
    midiToFrequency(midi) * pow(2, cents / 1200);

void main() {
  test('N1 note names convert in both directions', () {
    const sharps = {
      12: 'C0',
      40: 'E2',
      45: 'A2',
      59: 'B3',
      60: 'C4',
      61: 'C#4',
      63: 'D#4',
      69: 'A4',
      70: 'A#4',
      88: 'E6',
    };
    const flats = {
      40: 'E2',
      60: 'C4',
      61: 'Db4',
      63: 'Eb4',
      66: 'Gb4',
      68: 'Ab4',
      70: 'Bb4',
    };

    sharps.forEach((midi, name) {
      expect(noteName(midi), name);
      expect(noteToMidi(name), midi);
    });
    flats.forEach((midi, name) {
      expect(noteName(midi, useFlats: true), name);
      expect(noteToMidi(name), midi);
    });
  });

  test('N2 frequencies convert in both directions, rounding at 50 cents', () {
    const frequencies = {
      40: 82.407,
      45: 110.0,
      57: 220.0,
      60: 261.626,
      64: 329.628,
      69: 440.0,
      81: 880.0,
      88: 1318.51,
    };

    frequencies.forEach((midi, hz) {
      expect(midiToFrequency(midi), closeTo(hz, 0.01));
      final note = frequencyToNote(midiToFrequency(midi));
      expect(note.midi, midi);
      expect(note.cents, closeTo(0, 1e-6));
    });

    const offsets = [
      (cents: 49.0, midi: 69, remainder: 49.0),
      (cents: 51.0, midi: 70, remainder: -49.0),
      (cents: -49.0, midi: 69, remainder: -49.0),
      (cents: -51.0, midi: 68, remainder: 49.0),
    ];
    for (final offset in offsets) {
      final note = frequencyToNote(centsAbove(69, offset.cents));
      expect(note.midi, offset.midi, reason: '${offset.cents} cents');
      expect(note.cents, closeTo(offset.remainder, 1e-6));
    }

    for (final (cents, candidates) in [
      (50.0, [69, 70]),
      (-50.0, [68, 69]),
    ]) {
      final tie = frequencyToNote(centsAbove(69, cents));
      expect(candidates, contains(tie.midi));
      expect(tie.cents.abs(), closeTo(50, 1e-6));
    }
  });
}
