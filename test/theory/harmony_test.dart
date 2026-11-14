import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/theory/harmony.dart';
import 'package:matrix_guitar/theory/scale.dart';

const window = (minFret: 3, maxFret: 7);

void main() {
  test('the four progressions retain their functions and chord qualities in every key', () {
    const expected = [
      (
        [1, 4, 0],
        [
          HarmonyQuality.minor7,
          HarmonyQuality.dominant7,
          HarmonyQuality.major7,
        ],
      ),
      (
        [0, 5, 3, 4],
        [
          HarmonyQuality.major,
          HarmonyQuality.minor,
          HarmonyQuality.major,
          HarmonyQuality.major,
        ],
      ),
      (
        [0, 5, 1, 4, 0],
        [
          HarmonyQuality.major,
          HarmonyQuality.dominant7,
          HarmonyQuality.minor,
          HarmonyQuality.major,
          HarmonyQuality.major,
        ],
      ),
      (
        [0, 3, 3, 0],
        [
          HarmonyQuality.major,
          HarmonyQuality.major,
          HarmonyQuality.minor,
          HarmonyQuality.major,
        ],
      ),
    ];
    expect(harmonyProgressions, hasLength(4));
    for (
      var progressionIndex = 0;
      progressionIndex < harmonyProgressions.length;
      progressionIndex++
    ) {
      final progression = harmonyProgressions[progressionIndex];
      final (degrees, qualities) = expected[progressionIndex];
      expect(
        progression.functions.map((f) => f.degree),
        degrees,
        reason: progression.name,
      );
      expect(
        progression.functions.map((f) => f.quality),
        qualities,
        reason: progression.name,
      );
      for (var key = 0; key < 12; key++) {
        final chords = progression.chords(key, window);
        expect(
          chords,
          hasLength(degrees.length),
          reason: '${progression.name}, key $key',
        );
        for (var i = 0; i < chords.length; i++) {
          final chord = chords[i];
          expect(
            chord.root,
            (key + const [0, 2, 4, 5, 7, 9, 11][degrees[i]]) % 12,
          );
          expect(chord.intervals, qualities[i].pattern.intervals);
          expect(
            chord.tones,
            ChordTone.values.take(qualities[i].pattern.intervals.length),
          );
          expect(chord.noteNames, hasLength(chord.intervals.length));
        }
      }
    }
  });

  test('spelling preserves key letters for secondary and borrowed chords', () {
    final secondary = harmonyProgressions[2].chords(0, window)[1];
    expect(secondary.name, 'A7');
    expect(secondary.noteNames, ['A', 'C#', 'E', 'G']);
    final sharpSecondary = harmonyProgressions[2].chords(6, window)[1];
    expect(sharpSecondary.name, 'D#7');
    expect(sharpSecondary.noteNames, ['D#', 'F##', 'A#', 'C#']);

    final borrowed = harmonyProgressions[3];
    expect(borrowed.chords(5, window)[2].name, 'Bbm');
    expect(borrowed.chords(5, window)[2].noteNames, ['Bb', 'Db', 'F']);
    expect(borrowed.chords(1, window)[2].name, 'Gbm');
    expect(borrowed.chords(1, window)[2].noteNames, ['Gb', 'Bbb', 'Db']);
    expect(borrowed.chords(10, window)[2].name, 'Ebm');
    expect(borrowed.chords(10, window)[2].noteNames, ['Eb', 'Gb', 'Bb']);
    expect(borrowed.chords(6, window)[2].name, 'Bm');
    expect(borrowed.chords(6, window)[2].noteNames, ['B', 'D', 'F#']);
  });

  test(
    'targets stay in frets 3–7 and match their chord role and pitch class',
    () {
      for (var key = 0; key < 12; key++) {
        for (final progression in harmonyProgressions) {
          final chords = progression.chords(key, window);
          for (final chord in chords) {
            for (final tone in chord.tones) {
              final target = harmonyTargets([chord], tone: tone).single;
              expect(target.tone, tone);
              expect(target.position.fret, inInclusiveRange(3, 7));
              expect(target.position.midi % 12, target.chord.pitchClass(tone));
              expect(
                openStringMidi[target.position.string - 1] +
                    target.position.fret,
                target.position.midi,
              );
              expect(
                target.chord.noteNames[tone.index],
                target.chord.toneName(tone),
              );
            }
          }
        }
      }
    },
  );

  test('guide tones use the lower note on ties and minimize each movement', () {
    final chords = harmonyProgressions.first.chords(0, window);
    final tie = chords[0].nearestPosition([ChordTone.third], 59);
    expect(tie.midi, 53);
    final targets = harmonyTargets(chords, guideTones: true);
    for (var i = 1; i < targets.length; i++) {
      final previous = targets[i - 1].position.midi;
      final current = targets[i];
      final candidates = current.chord.scale.positions
          .where(
            (position) => [ChordTone.third, ChordTone.seventh]
                .where(current.chord.tones.contains)
                .any(
                  (tone) =>
                      position.midi % 12 == current.chord.pitchClass(tone),
                ),
          )
          .toList();
      final minimum = candidates
          .map((p) => (p.midi - previous).abs())
          .reduce((a, b) => a < b ? a : b);
      expect((current.position.midi - previous).abs(), minimum);
      expect(current.previousMidi, previous);
    }
    expect(targets[2].position.midi, targets[2].previousMidi);
    expect(
      targets[2].explanation,
      contains('Keep the common tone (0 semitones).'),
    );
    expect(targets[1].explanation, contains('Move down 1 semitone.'));
    expect(targets[0].explanation, contains('10 semitones above its root D'));
    expect(
      targets[0].explanation,
      contains('Formula: 1–b3–5–b7; notes: D–F–A–C'),
    );
    expect(targets[1].explanation, contains('4 semitones above its root G'));
  });

  test(
    'chord formulas and inversions keep chord tones ordered from the bass',
    () {
      expect(HarmonyQuality.major.formula, '1–3–5');
      expect(HarmonyQuality.minor.formula, '1–b3–5');
      expect(HarmonyQuality.major7.formula, '1–3–5–7');
      expect(HarmonyQuality.minor7.formula, '1–b3–5–b7');
      expect(HarmonyQuality.dominant7.formula, '1–3–5–b7');
      final chord = harmonyProgressions.first.chords(0, window).first;
      expect(chord.name, 'Dm7');
      expect(chord.inversionNames(0), ['D', 'F', 'A', 'C']);
      expect(chord.inversionNames(1), ['F', 'A', 'C', 'D']);
      expect(chord.inversionNames(2), ['A', 'C', 'D', 'F']);
      expect(chord.inversionNames(3), ['C', 'D', 'F', 'A']);
    },
  );
}
