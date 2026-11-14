import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/theory/chord.dart';

const openStrings = [40, 45, 50, 55, 59, 64];

const qualityTones = {
  ChordQuality.major: {0, 4, 7},
  ChordQuality.minor: {0, 3, 7},
  ChordQuality.dom7: {0, 4, 7, 10},
  ChordQuality.min7: {0, 3, 7, 10},
  ChordQuality.maj7: {0, 4, 7, 11},
  ChordQuality.power: {0, 7},
};

ChordVoicing chordNamed(String name) =>
    chordLibrary.firstWhere((chord) => chord.name == name);

void main() {
  test('CH1 all 29 voicings are playable and hold exactly their tones', () {
    expect(chordLibrary, hasLength(29));

    for (final chord in chordLibrary) {
      final reason = chord.name;

      expect(chord.frets, hasLength(6), reason: reason);
      expect(
        chord.frets,
        everyElement(inInclusiveRange(-1, 5)),
        reason: reason,
      );
      expect(chord.midiNotes, [
        for (var i = 0; i < 6; i++)
          chord.frets[i] < 0 ? null : openStrings[i] + chord.frets[i],
      ], reason: reason);

      final played = chord.midiNotes.nonNulls.toList()..sort();

      expect(played.first % 12, chord.root, reason: reason);
      expect(
        {for (final midi in played) (midi - chord.root) % 12},
        qualityTones[chord.quality],
        reason: reason,
      );
    }
  });

  group('CH2 spelling and display names', () {
    const rows = [
      ('B7', 'B D# A B F#', 'B dominant 7th'),
      ('E', 'E B E G# B E', 'E major'),
      ('C7', 'C E Bb C G', 'C dominant 7th'),
      ('Bb', 'Bb F Bb D F', 'Bb major'),
      ('F#', 'F# C# F# A# C# F#', 'F# major'),
      ('Fm', 'F C F Ab C F', 'F minor'),
      ('E5', 'E B E', 'E power chord'),
      ('C', 'C E G C E', 'C major'),
      ('Am7', 'A E G C E', 'A minor 7th'),
      ('Cmaj7', 'C E G B E', 'C major 7th'),
    ];

    for (final (name, spelling, displayName) in rows) {
      test(name, () {
        final chord = chordNamed(name);

        expect(chord.noteNames.join(' '), spelling);
        expect(chord.displayName, displayName);
      });
    }
  });
}
