import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/theory/scale.dart';

const c = 0;
const dFlat = 1;
const d = 2;
const eFlat = 3;
const e = 4;
const f = 5;
const fSharp = 6;
const g = 7;
const aFlat = 8;
const a = 9;
const bFlat = 10;
const b = 11;

const letterPitches = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};

int pitchClassOf(String name) {
  final accidentals = name.substring(1);
  final shift =
      '#'.allMatches(accidentals).length - 'b'.allMatches(accidentals).length;
  return (letterPitches[name[0]]! + shift) % 12;
}

ScaleDefinition scaleOf(
  String pattern,
  int root, {
  PatternKind kind = PatternKind.scale,
}) => ScaleDefinition(
  patterns.singleWhere((p) => p.name == pattern && p.kind == kind),
  root,
  defaultFretWindow(root),
);

void main() {
  test('SC1 each scale produces its expected midi list', () {
    const expected = {
      'A minor pentatonic': (
        pattern: 'Minor pentatonic',
        root: a,
        midis: '45 48 50 52 55 57 60 62 64 67 69 72',
      ),
      'E minor pentatonic': (
        pattern: 'Minor pentatonic',
        root: e,
        midis: '40 43 45 47 50 52 55 57 59 62 64 67',
      ),
      'A minor blues': (
        pattern: 'Minor blues',
        root: a,
        midis: '45 48 50 51 52 55 57 60 62 63 64 67 69 72',
      ),
      'C major': (
        pattern: 'Major',
        root: c,
        midis: '40 41 43 45 47 48 50 52 53 55 57 59 60 62 64 65 67',
      ),
      'G major': (
        pattern: 'Major',
        root: g,
        midis: '40 42 43 45 47 48 50 52 54 55 57 59 60 62 64 66 67',
      ),
      'A natural minor': (
        pattern: 'Natural minor',
        root: a,
        midis: '45 47 48 50 52 53 55 57 59 60 62 64 65 67 69 71 72',
      ),
    };

    expected.forEach((name, entry) {
      final scale = scaleOf(entry.pattern, entry.root);
      expect(scale.name, name);
      expect(
        scale.positions.map((position) => position.midi).join(' '),
        entry.midis,
      );
    });
  });

  test('SC2 duplicate pitches keep the higher string', () {
    const spotChecks = [
      (pattern: 'Major', root: g, midi: 59, string: 2, fret: 0),
      (pattern: 'Major', root: g, midi: 64, string: 1, fret: 0),
      (pattern: 'Major', root: g, midi: 40, string: 6, fret: 0),
      (pattern: 'Natural minor', root: a, midi: 59, string: 3, fret: 4),
      (pattern: 'Minor pentatonic', root: a, midi: 45, string: 6, fret: 5),
      (pattern: 'Minor pentatonic', root: a, midi: 50, string: 5, fret: 5),
      (pattern: 'Minor pentatonic', root: a, midi: 72, string: 1, fret: 8),
    ];

    for (final check in spotChecks) {
      final position = scaleOf(
        check.pattern,
        check.root,
      ).positions.singleWhere((position) => position.midi == check.midi);
      expect(position.string, check.string, reason: '$check');
      expect(position.fret, check.fret, reason: '$check');
    }
  });

  test('SC4 the catalogue lists every pattern in order', () {
    const scale = PatternKind.scale;
    const arpeggio = PatternKind.arpeggio;
    const majorAndMinor = 'Major and minor';
    const expected = [
      (
        name: 'Major',
        kind: scale,
        group: majorAndMinor,
        intervals: [0, 2, 4, 5, 7, 9, 11],
      ),
      (
        name: 'Natural minor',
        kind: scale,
        group: majorAndMinor,
        intervals: [0, 2, 3, 5, 7, 8, 10],
      ),
      (
        name: 'Harmonic minor',
        kind: scale,
        group: majorAndMinor,
        intervals: [0, 2, 3, 5, 7, 8, 11],
      ),
      (
        name: 'Melodic minor',
        kind: scale,
        group: majorAndMinor,
        intervals: [0, 2, 3, 5, 7, 9, 11],
      ),
      (
        name: 'Ionian',
        kind: scale,
        group: 'Modes',
        intervals: [0, 2, 4, 5, 7, 9, 11],
      ),
      (
        name: 'Dorian',
        kind: scale,
        group: 'Modes',
        intervals: [0, 2, 3, 5, 7, 9, 10],
      ),
      (
        name: 'Phrygian',
        kind: scale,
        group: 'Modes',
        intervals: [0, 1, 3, 5, 7, 8, 10],
      ),
      (
        name: 'Lydian',
        kind: scale,
        group: 'Modes',
        intervals: [0, 2, 4, 6, 7, 9, 11],
      ),
      (
        name: 'Mixolydian',
        kind: scale,
        group: 'Modes',
        intervals: [0, 2, 4, 5, 7, 9, 10],
      ),
      (
        name: 'Aeolian',
        kind: scale,
        group: 'Modes',
        intervals: [0, 2, 3, 5, 7, 8, 10],
      ),
      (
        name: 'Locrian',
        kind: scale,
        group: 'Modes',
        intervals: [0, 1, 3, 5, 6, 8, 10],
      ),
      (
        name: 'Major pentatonic',
        kind: scale,
        group: 'Pentatonic',
        intervals: [0, 2, 4, 7, 9],
      ),
      (
        name: 'Minor pentatonic',
        kind: scale,
        group: 'Pentatonic',
        intervals: [0, 3, 5, 7, 10],
      ),
      (
        name: 'Major blues',
        kind: scale,
        group: 'Blues',
        intervals: [0, 2, 3, 4, 7, 9],
      ),
      (
        name: 'Minor blues',
        kind: scale,
        group: 'Blues',
        intervals: [0, 3, 5, 6, 7, 10],
      ),
      (
        name: 'Whole tone',
        kind: scale,
        group: 'Symmetric',
        intervals: [0, 2, 4, 6, 8, 10],
      ),
      (
        name: 'Diminished half-whole',
        kind: scale,
        group: 'Symmetric',
        intervals: [0, 1, 3, 4, 6, 7, 9, 10],
      ),
      (
        name: 'Diminished whole-half',
        kind: scale,
        group: 'Symmetric',
        intervals: [0, 2, 3, 5, 6, 8, 9, 11],
      ),
      (name: 'Major', kind: arpeggio, group: 'Triads', intervals: [0, 4, 7]),
      (name: 'Minor', kind: arpeggio, group: 'Triads', intervals: [0, 3, 7]),
      (
        name: 'Diminished',
        kind: arpeggio,
        group: 'Triads',
        intervals: [0, 3, 6],
      ),
      (
        name: 'Augmented',
        kind: arpeggio,
        group: 'Triads',
        intervals: [0, 4, 8],
      ),
      (
        name: 'Maj7',
        kind: arpeggio,
        group: 'Seventh chords',
        intervals: [0, 4, 7, 11],
      ),
      (
        name: 'Min7',
        kind: arpeggio,
        group: 'Seventh chords',
        intervals: [0, 3, 7, 10],
      ),
      (
        name: 'Dom7',
        kind: arpeggio,
        group: 'Seventh chords',
        intervals: [0, 4, 7, 10],
      ),
      (
        name: 'm7b5',
        kind: arpeggio,
        group: 'Seventh chords',
        intervals: [0, 3, 6, 10],
      ),
      (
        name: 'Dim7',
        kind: arpeggio,
        group: 'Seventh chords',
        intervals: [0, 3, 6, 9],
      ),
      (name: 'Sus2', kind: arpeggio, group: 'Suspended', intervals: [0, 2, 7]),
      (name: 'Sus4', kind: arpeggio, group: 'Suspended', intervals: [0, 5, 7]),
    ];

    expect(patterns, hasLength(29));
    expect(patterns.where((pattern) => pattern.kind == scale), hasLength(18));
    expect(
      patterns.where((pattern) => pattern.kind == arpeggio),
      hasLength(11),
    );
    for (var i = 0; i < expected.length; i++) {
      final row = expected[i];
      expect(patterns[i].name, row.name, reason: 'row $i');
      expect(patterns[i].kind, row.kind, reason: 'row $i ${row.name}');
      expect(patterns[i].group, row.group, reason: 'row $i ${row.name}');
      expect(
        patterns[i].intervals,
        row.intervals,
        reason: 'row $i ${row.name}',
      );
    }
  });

  test('SC5 every pattern, root and window combination is playable', () {
    var combinations = 0;

    for (final pattern in patterns) {
      for (var root = 0; root < 12; root++) {
        for (final window in fretWindows(root)) {
          combinations++;
          final scale = ScaleDefinition(pattern, root, window);
          final label = '${scale.name} $window';
          final midis = scale.positions.map((p) => p.midi).toList();

          expect(midis.length, greaterThanOrEqualTo(6), reason: label);
          expect(
            midis.where((midi) => midi % 12 == root).length,
            greaterThanOrEqualTo(2),
            reason: label,
          );
          expect(midis.last, lessThanOrEqualTo(79), reason: label);
          for (var i = 1; i < midis.length; i++) {
            expect(midis[i], greaterThan(midis[i - 1]), reason: label);
          }
          for (final position in scale.positions) {
            expect(
              position.fret,
              inInclusiveRange(window.minFret, window.maxFret),
              reason: label,
            );
            expect(
              scale.intervals,
              contains((position.midi - root) % 12),
              reason: label,
            );
          }
        }
      }
    }

    expect(combinations, 754);
  });

  test('SC6 fret windows follow the root anchors on strings 6 and 5', () {
    const expectedWindows = {
      e: [
        (minFret: 0, maxFret: 4),
        (minFret: 6, maxFret: 10),
        (minFret: 11, maxFret: 15),
      ],
      a: [
        (minFret: 0, maxFret: 4),
        (minFret: 4, maxFret: 8),
        (minFret: 11, maxFret: 15),
      ],
      c: [(minFret: 0, maxFret: 4), (minFret: 7, maxFret: 11)],
      g: [(minFret: 0, maxFret: 4), (minFret: 9, maxFret: 13)],
      aFlat: [(minFret: 3, maxFret: 7), (minFret: 10, maxFret: 14)],
      b: [(minFret: 0, maxFret: 4), (minFret: 6, maxFret: 10)],
    };
    const expectedDefaults = {
      a: (minFret: 4, maxFret: 8),
      c: (minFret: 0, maxFret: 4),
      e: (minFret: 0, maxFret: 4),
      g: (minFret: 0, maxFret: 4),
      f: (minFret: 0, maxFret: 4),
      eFlat: (minFret: 5, maxFret: 9),
      aFlat: (minFret: 3, maxFret: 7),
      b: (minFret: 6, maxFret: 10),
    };

    expect([
      for (var root = 0; root < 12; root++) ...fretWindows(root),
    ], hasLength(26));
    expectedWindows.forEach((root, windows) {
      expect(fretWindows(root), windows, reason: 'root $root');
    });
    expectedDefaults.forEach((root, window) {
      expect(defaultFretWindow(root), window, reason: 'root $root');
    });
  });

  group('SC7 spelling', () {
    const scale = PatternKind.scale;
    const arpeggio = PatternKind.arpeggio;
    const spellings = [
      (
        pattern: 'Harmonic minor',
        kind: scale,
        root: d,
        notes: 'D E F G A Bb C#',
      ),
      (
        pattern: 'Harmonic minor',
        kind: scale,
        root: g,
        notes: 'G A Bb C D Eb F#',
      ),
      (pattern: 'Melodic minor', kind: scale, root: d, notes: 'D E F G A B C#'),
      (
        pattern: 'Melodic minor',
        kind: scale,
        root: g,
        notes: 'G A Bb C D E F#',
      ),
      (pattern: 'Locrian', kind: scale, root: f, notes: 'F Gb Ab Bb Cb Db Eb'),
      (pattern: 'm7b5', kind: arpeggio, root: f, notes: 'F Ab Cb Eb'),
      (
        pattern: 'Natural minor',
        kind: scale,
        root: dFlat,
        notes: 'C# D# E F# G# A B',
      ),
      (pattern: 'Minor', kind: arpeggio, root: dFlat, notes: 'C# E G#'),
      (pattern: 'Augmented', kind: arpeggio, root: f, notes: 'F A C#'),
      (pattern: 'Major blues', kind: scale, root: c, notes: 'C D Eb E G A'),
      (pattern: 'Minor blues', kind: scale, root: a, notes: 'A C D Eb E G'),
      (pattern: 'Minor pentatonic', kind: scale, root: a, notes: 'A C D E G'),
      (
        pattern: 'Major',
        kind: scale,
        root: fSharp,
        notes: 'F# G# A# B C# D# E#',
      ),
      (pattern: 'Major', kind: scale, root: dFlat, notes: 'Db Eb F Gb Ab Bb C'),
      (
        pattern: 'Harmonic minor',
        kind: scale,
        root: aFlat,
        notes: 'Ab Bb Cb Db Eb Fb G',
      ),
      (
        pattern: 'Natural minor',
        kind: scale,
        root: aFlat,
        notes: 'G# A# B C# D# E F#',
      ),
      (pattern: 'Dim7', kind: arpeggio, root: c, notes: 'C Eb Gb A'),
      (pattern: 'Dorian', kind: scale, root: c, notes: 'C D Eb F G A Bb'),
      (pattern: 'Dorian', kind: scale, root: d, notes: 'D E F G A B C'),
      (pattern: 'Locrian', kind: scale, root: b, notes: 'B C D E F G A'),
      (
        pattern: 'Harmonic minor',
        kind: scale,
        root: a,
        notes: 'A B C D E F G#',
      ),
      (pattern: 'Dom7', kind: arpeggio, root: g, notes: 'G B D F'),
      (pattern: 'Dom7', kind: arpeggio, root: c, notes: 'C E G Bb'),
      (
        pattern: 'Diminished half-whole',
        kind: scale,
        root: c,
        notes: 'C Db Eb E F# G A Bb',
      ),
      (
        pattern: 'Diminished whole-half',
        kind: scale,
        root: c,
        notes: 'C D Eb F Gb Ab A B',
      ),
      (pattern: 'Whole tone', kind: scale, root: c, notes: 'C D E F# G# Bb'),
      (pattern: 'Ionian', kind: scale, root: c, notes: 'C D E F G A B'),
      (pattern: 'Aeolian', kind: scale, root: a, notes: 'A B C D E F G'),
      (pattern: 'Major', kind: scale, root: eFlat, notes: 'Eb F G Ab Bb C D'),
      (pattern: 'Major', kind: scale, root: bFlat, notes: 'Bb C D Eb F G A'),
      (pattern: 'Major', kind: scale, root: f, notes: 'F G A Bb C D E'),
      (pattern: 'Major', kind: scale, root: c, notes: 'C D E F G A B'),
      (pattern: 'Natural minor', kind: scale, root: d, notes: 'D E F G A Bb C'),
      (pattern: 'Mixolydian', kind: scale, root: c, notes: 'C D E F G A Bb'),
    ];
    const spelledNotes = [
      (pattern: 'Minor pentatonic', root: a, midi: 51, note: 'D#3'),
      (pattern: 'Minor blues', root: a, midi: 51, note: 'Eb3'),
      (pattern: 'Locrian', root: f, midi: 59, note: 'Cb4'),
      (pattern: 'Locrian', root: f, midi: 47, note: 'Cb3'),
      (pattern: 'Harmonic minor', root: dFlat, midi: 60, note: 'B#3'),
      (pattern: 'Harmonic minor', root: dFlat, midi: 72, note: 'B#4'),
      (pattern: 'Major', root: fSharp, midi: 65, note: 'E#4'),
    ];
    const offScaleNotes = [
      (pattern: 'Major', kind: scale, root: eFlat, midi: 54, note: 'Gb3'),
      (pattern: 'Major', kind: scale, root: bFlat, midi: 54, note: 'Gb3'),
      (
        pattern: 'Minor blues',
        kind: scale,
        root: fSharp,
        midi: 51,
        note: 'D#3',
      ),
      (
        pattern: 'Diminished half-whole',
        kind: scale,
        root: fSharp,
        midi: 56,
        note: 'G#3',
      ),
      (pattern: 'Minor blues', kind: scale, root: a, midi: 58, note: 'Bb3'),
      (
        pattern: 'Minor pentatonic',
        kind: scale,
        root: a,
        midi: 58,
        note: 'A#3',
      ),
      (pattern: 'Major', kind: scale, root: f, midi: 54, note: 'Gb3'),
      (pattern: 'Natural minor', kind: scale, root: d, midi: 54, note: 'Gb3'),
      (pattern: 'Major', kind: scale, root: c, midi: 54, note: 'F#3'),
      (pattern: 'Mixolydian', kind: scale, root: c, midi: 54, note: 'Gb3'),
      (pattern: 'Dorian', kind: scale, root: d, midi: 54, note: 'F#3'),
      (
        pattern: 'Diminished half-whole',
        kind: scale,
        root: a,
        midi: 56,
        note: 'Ab3',
      ),
      (
        pattern: 'Natural minor',
        kind: scale,
        root: dFlat,
        midi: 58,
        note: 'Bb3',
      ),
      (pattern: 'Dorian', kind: scale, root: c, midi: 54, note: 'Gb3'),
      (pattern: 'Locrian', kind: scale, root: a, midi: 54, note: 'Gb3'),
      (pattern: 'Harmonic minor', kind: scale, root: d, midi: 54, note: 'Gb3'),
      (pattern: 'Dom7', kind: arpeggio, root: c, midi: 54, note: 'Gb3'),
    ];
    const names = [
      (
        pattern: 'Natural minor',
        kind: scale,
        root: dFlat,
        name: 'C# natural minor',
      ),
      (
        pattern: 'Minor',
        kind: arpeggio,
        root: dFlat,
        name: 'C# minor arpeggio',
      ),
      (pattern: 'Major', kind: scale, root: dFlat, name: 'Db major'),
      (
        pattern: 'Harmonic minor',
        kind: scale,
        root: aFlat,
        name: 'Ab harmonic minor',
      ),
      (
        pattern: 'Natural minor',
        kind: scale,
        root: aFlat,
        name: 'G# natural minor',
      ),
      (
        pattern: 'Minor pentatonic',
        kind: PatternKind.scale,
        root: a,
        name: 'A minor pentatonic',
      ),
      (pattern: 'Dorian', kind: PatternKind.scale, root: d, name: 'D dorian'),
      (
        pattern: 'Maj7',
        kind: PatternKind.arpeggio,
        root: a,
        name: 'A maj7 arpeggio',
      ),
      (
        pattern: 'm7b5',
        kind: PatternKind.arpeggio,
        root: a,
        name: 'A m7b5 arpeggio',
      ),
      (
        pattern: 'Minor blues',
        kind: PatternKind.scale,
        root: a,
        name: 'A minor blues',
      ),
      (pattern: 'Major', kind: PatternKind.scale, root: c, name: 'C major'),
      (
        pattern: 'Major',
        kind: PatternKind.scale,
        root: fSharp,
        name: 'F# major',
      ),
      (
        pattern: 'Major',
        kind: PatternKind.scale,
        root: eFlat,
        name: 'Eb major',
      ),
      (
        pattern: 'Major',
        kind: PatternKind.arpeggio,
        root: a,
        name: 'A major arpeggio',
      ),
    ];

    for (final check in spellings) {
      test('${check.pattern} ${check.kind.name} root ${check.root}', () {
        final scale = scaleOf(check.pattern, check.root, kind: check.kind);

        expect(scale.noteNames.join(' '), check.notes);
      });
    }

    for (final check in spelledNotes) {
      test('${check.pattern} root ${check.root} midi ${check.midi}', () {
        final scale = scaleOf(check.pattern, check.root);

        expect(scale.spelledNote(check.midi), check.note);
      });
    }

    for (final check in offScaleNotes) {
      final spelled = scaleOf(check.pattern, check.root, kind: check.kind);

      test('${spelled.name} off-scale midi ${check.midi} is ${check.note}', () {
        expect(
          spelled.intervals,
          isNot(contains((check.midi - check.root) % 12)),
        );
        expect(spelled.spelledNote(check.midi), check.note);
      });
    }

    for (final check in names) {
      test(check.name, () {
        expect(
          scaleOf(check.pattern, check.root, kind: check.kind).name,
          check.name,
        );
      });
    }
  });

  group('SC8 spelling properties', () {
    test('seven-note patterns use each letter once on every root', () {
      final repeated = <String>[];

      for (final pattern in patterns.where((p) => p.intervals.length == 7)) {
        for (var root = 0; root < 12; root++) {
          final scale = ScaleDefinition(pattern, root, defaultFretWindow(root));
          final letters = scale.noteNames.map((name) => name[0]).toSet();
          if (letters.length != 7) {
            repeated.add('${scale.name}: ${scale.noteNames.join(' ')}');
          }
        }
      }

      expect(repeated, isEmpty);
    });

    test('every name matches its pitch with at most one accidental', () {
      final wrong = <String>[];

      for (final pattern in patterns) {
        for (var root = 0; root < 12; root++) {
          final scale = ScaleDefinition(pattern, root, defaultFretWindow(root));
          final names = scale.noteNames;
          final label = '${scale.name}: ${names.join(' ')}';

          if (!scale.name.startsWith('${names.first} ')) wrong.add(label);
          for (final (index, name) in names.indexed) {
            final pitchClass = (root + scale.intervals[index]) % 12;
            if (name.length > 2 || pitchClassOf(name) != pitchClass) {
              wrong.add('$label ($name)');
            }
          }
        }
      }

      expect(wrong, isEmpty);
    });
  });
}
