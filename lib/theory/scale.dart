import 'note.dart';

const openStringMidi = [64, 59, 55, 50, 45, 40];

const _blackKeys = {1, 3, 6, 8, 10};
const _fSharp = 6;
const _flatMajorKeys = {5, 10, 3, 8, 1};
const _letters = 'CDEFGAB';
const _letterPitches = [0, 2, 4, 5, 7, 9, 11];
const _fallbackCost = 100;

class ScalePosition {
  final int string;
  final int fret;
  final int midi;

  const ScalePosition({
    required this.string,
    required this.fret,
    required this.midi,
  });
}

enum PatternKind { scale, arpeggio }

typedef FretWindow = ({int minFret, int maxFret});

class PatternDefinition {
  final String name;
  final PatternKind kind;
  final String group;
  final List<int> intervals;
  final List<int> letterSteps;
  final int parentMajorOffset;
  final bool flatLeaning;

  const PatternDefinition({
    required this.name,
    required this.kind,
    required this.group,
    required this.intervals,
    required this.letterSteps,
    required this.parentMajorOffset,
    this.flatLeaning = false,
  });
}

const List<PatternDefinition> patterns = [
  PatternDefinition(
    name: 'Major',
    kind: PatternKind.scale,
    group: 'Major and minor',
    intervals: [0, 2, 4, 5, 7, 9, 11],
    letterSteps: [0, 1, 2, 3, 4, 5, 6],
    parentMajorOffset: 0,
  ),
  PatternDefinition(
    name: 'Natural minor',
    kind: PatternKind.scale,
    group: 'Major and minor',
    intervals: [0, 2, 3, 5, 7, 8, 10],
    letterSteps: [0, 1, 2, 3, 4, 5, 6],
    parentMajorOffset: 3,
  ),
  PatternDefinition(
    name: 'Harmonic minor',
    kind: PatternKind.scale,
    group: 'Major and minor',
    intervals: [0, 2, 3, 5, 7, 8, 11],
    letterSteps: [0, 1, 2, 3, 4, 5, 6],
    parentMajorOffset: 3,
  ),
  PatternDefinition(
    name: 'Melodic minor',
    kind: PatternKind.scale,
    group: 'Major and minor',
    intervals: [0, 2, 3, 5, 7, 9, 11],
    letterSteps: [0, 1, 2, 3, 4, 5, 6],
    parentMajorOffset: 3,
  ),
  PatternDefinition(
    name: 'Ionian',
    kind: PatternKind.scale,
    group: 'Modes',
    intervals: [0, 2, 4, 5, 7, 9, 11],
    letterSteps: [0, 1, 2, 3, 4, 5, 6],
    parentMajorOffset: 0,
  ),
  PatternDefinition(
    name: 'Dorian',
    kind: PatternKind.scale,
    group: 'Modes',
    intervals: [0, 2, 3, 5, 7, 9, 10],
    letterSteps: [0, 1, 2, 3, 4, 5, 6],
    parentMajorOffset: 10,
  ),
  PatternDefinition(
    name: 'Phrygian',
    kind: PatternKind.scale,
    group: 'Modes',
    intervals: [0, 1, 3, 5, 7, 8, 10],
    letterSteps: [0, 1, 2, 3, 4, 5, 6],
    parentMajorOffset: 8,
  ),
  PatternDefinition(
    name: 'Lydian',
    kind: PatternKind.scale,
    group: 'Modes',
    intervals: [0, 2, 4, 6, 7, 9, 11],
    letterSteps: [0, 1, 2, 3, 4, 5, 6],
    parentMajorOffset: 7,
  ),
  PatternDefinition(
    name: 'Mixolydian',
    kind: PatternKind.scale,
    group: 'Modes',
    intervals: [0, 2, 4, 5, 7, 9, 10],
    letterSteps: [0, 1, 2, 3, 4, 5, 6],
    parentMajorOffset: 5,
  ),
  PatternDefinition(
    name: 'Aeolian',
    kind: PatternKind.scale,
    group: 'Modes',
    intervals: [0, 2, 3, 5, 7, 8, 10],
    letterSteps: [0, 1, 2, 3, 4, 5, 6],
    parentMajorOffset: 3,
  ),
  PatternDefinition(
    name: 'Locrian',
    kind: PatternKind.scale,
    group: 'Modes',
    intervals: [0, 1, 3, 5, 6, 8, 10],
    letterSteps: [0, 1, 2, 3, 4, 5, 6],
    parentMajorOffset: 1,
  ),
  PatternDefinition(
    name: 'Major pentatonic',
    kind: PatternKind.scale,
    group: 'Pentatonic',
    intervals: [0, 2, 4, 7, 9],
    letterSteps: [0, 1, 2, 4, 5],
    parentMajorOffset: 0,
  ),
  PatternDefinition(
    name: 'Minor pentatonic',
    kind: PatternKind.scale,
    group: 'Pentatonic',
    intervals: [0, 3, 5, 7, 10],
    letterSteps: [0, 2, 3, 4, 6],
    parentMajorOffset: 3,
  ),
  PatternDefinition(
    name: 'Major blues',
    kind: PatternKind.scale,
    group: 'Blues',
    intervals: [0, 2, 3, 4, 7, 9],
    letterSteps: [0, 1, 2, 2, 4, 5],
    parentMajorOffset: 0,
  ),
  PatternDefinition(
    name: 'Minor blues',
    kind: PatternKind.scale,
    group: 'Blues',
    intervals: [0, 3, 5, 6, 7, 10],
    letterSteps: [0, 2, 3, 4, 4, 6],
    parentMajorOffset: 3,
    flatLeaning: true,
  ),
  PatternDefinition(
    name: 'Whole tone',
    kind: PatternKind.scale,
    group: 'Symmetric',
    intervals: [0, 2, 4, 6, 8, 10],
    letterSteps: [0, 1, 2, 3, 4, 6],
    parentMajorOffset: 0,
  ),
  PatternDefinition(
    name: 'Diminished half-whole',
    kind: PatternKind.scale,
    group: 'Symmetric',
    intervals: [0, 1, 3, 4, 6, 7, 9, 10],
    letterSteps: [0, 1, 2, 2, 3, 4, 5, 6],
    parentMajorOffset: 0,
    flatLeaning: true,
  ),
  PatternDefinition(
    name: 'Diminished whole-half',
    kind: PatternKind.scale,
    group: 'Symmetric',
    intervals: [0, 2, 3, 5, 6, 8, 9, 11],
    letterSteps: [0, 1, 2, 3, 4, 5, 5, 6],
    parentMajorOffset: 0,
    flatLeaning: true,
  ),
  PatternDefinition(
    name: 'Major',
    kind: PatternKind.arpeggio,
    group: 'Triads',
    intervals: [0, 4, 7],
    letterSteps: [0, 2, 4],
    parentMajorOffset: 0,
  ),
  PatternDefinition(
    name: 'Minor',
    kind: PatternKind.arpeggio,
    group: 'Triads',
    intervals: [0, 3, 7],
    letterSteps: [0, 2, 4],
    parentMajorOffset: 3,
  ),
  PatternDefinition(
    name: 'Diminished',
    kind: PatternKind.arpeggio,
    group: 'Triads',
    intervals: [0, 3, 6],
    letterSteps: [0, 2, 4],
    parentMajorOffset: 0,
    flatLeaning: true,
  ),
  PatternDefinition(
    name: 'Augmented',
    kind: PatternKind.arpeggio,
    group: 'Triads',
    intervals: [0, 4, 8],
    letterSteps: [0, 2, 4],
    parentMajorOffset: 0,
  ),
  PatternDefinition(
    name: 'Maj7',
    kind: PatternKind.arpeggio,
    group: 'Seventh chords',
    intervals: [0, 4, 7, 11],
    letterSteps: [0, 2, 4, 6],
    parentMajorOffset: 0,
  ),
  PatternDefinition(
    name: 'Min7',
    kind: PatternKind.arpeggio,
    group: 'Seventh chords',
    intervals: [0, 3, 7, 10],
    letterSteps: [0, 2, 4, 6],
    parentMajorOffset: 3,
  ),
  PatternDefinition(
    name: 'Dom7',
    kind: PatternKind.arpeggio,
    group: 'Seventh chords',
    intervals: [0, 4, 7, 10],
    letterSteps: [0, 2, 4, 6],
    parentMajorOffset: 5,
  ),
  PatternDefinition(
    name: 'm7b5',
    kind: PatternKind.arpeggio,
    group: 'Seventh chords',
    intervals: [0, 3, 6, 10],
    letterSteps: [0, 2, 4, 6],
    parentMajorOffset: 1,
  ),
  PatternDefinition(
    name: 'Dim7',
    kind: PatternKind.arpeggio,
    group: 'Seventh chords',
    intervals: [0, 3, 6, 9],
    letterSteps: [0, 2, 4, 6],
    parentMajorOffset: 0,
    flatLeaning: true,
  ),
  PatternDefinition(
    name: 'Sus2',
    kind: PatternKind.arpeggio,
    group: 'Suspended',
    intervals: [0, 2, 7],
    letterSteps: [0, 1, 4],
    parentMajorOffset: 0,
  ),
  PatternDefinition(
    name: 'Sus4',
    kind: PatternKind.arpeggio,
    group: 'Suspended',
    intervals: [0, 5, 7],
    letterSteps: [0, 3, 4],
    parentMajorOffset: 0,
  ),
];

List<int> _rootFrets(int root, int string) => [
  for (var fret = 0; fret <= 12; fret++)
    if ((openStringMidi[string - 1] + fret) % 12 == root) fret,
];

FretWindow _windowAround(int anchor) => anchor <= 3
    ? (minFret: 0, maxFret: 4)
    : (minFret: anchor - 1, maxFret: anchor + 3);

List<FretWindow> fretWindows(int root) =>
    [..._rootFrets(root, 6), ..._rootFrets(root, 5)].map(_windowAround).toList()
      ..sort((a, b) => a.minFret.compareTo(b.minFret));

FretWindow defaultFretWindow(int root) {
  final anchor = _rootFrets(root, 6).first;
  return _windowAround(anchor <= 7 ? anchor : _rootFrets(root, 5).first);
}

String rootName(int pitchClass) =>
    pitchClassName(pitchClass, useFlats: pitchClass != _fSharp);

String _spellOnLetter(int pitchClass, int letter) {
  final name = _letters[letter];
  final shift = (pitchClass - _letterPitches[letter] + 6) % 12 - 6;
  return switch (shift) {
    0 => name,
    1 => '$name#',
    -1 => '${name}b',
    _ => pitchClassName(pitchClass, useFlats: shift < 0),
  };
}

class ScaleDefinition {
  ScaleDefinition(this.pattern, this.root, FretWindow window)
    : minFret = window.minFret,
      maxFret = window.maxFret;

  final PatternDefinition pattern;
  final int root;
  final int minFret;
  final int maxFret;

  String get name {
    final suffix = pattern.kind == PatternKind.arpeggio ? ' arpeggio' : '';
    return '${noteNames.first} ${pattern.name.toLowerCase()}$suffix';
  }

  List<int> get intervals => pattern.intervals;

  bool get _useFlats => _blackKeys.contains(root)
      ? root != _fSharp
      : pattern.flatLeaning ||
            _flatMajorKeys.contains((root + pattern.parentMajorOffset) % 12);

  late final List<String> noteNames = _chooseSpelling();

  List<String> _chooseSpelling() {
    final preferred = _spellFrom(rootName(root));
    if (!_blackKeys.contains(root)) return preferred;
    final other = _spellFrom(pitchClassName(root, useFlats: root == _fSharp));
    return _spellingCost(other) < _spellingCost(preferred) ? other : preferred;
  }

  int _letterOf(int index, String spelledRoot) =>
      (_letters.indexOf(spelledRoot[0]) + pattern.letterSteps[index]) % 7;

  List<String> _spellFrom(String spelledRoot) => [
    for (final (index, interval) in intervals.indexed)
      _spellOnLetter((root + interval) % 12, _letterOf(index, spelledRoot)),
  ];

  int _spellingCost(List<String> names) {
    final fallbacks = names.indexed.where(
      (note) => note.$2[0] != _letters[_letterOf(note.$1, names.first)],
    );
    final accidentals = names.where((name) => name.length > 1);
    return fallbacks.length * _fallbackCost + accidentals.length;
  }

  String spelledPitchClass(int midi) {
    final index = intervals.indexOf((midi - root) % 12);
    return index >= 0
        ? noteNames[index]
        : pitchClassName(midi, useFlats: _useFlats);
  }

  String spelledNote(int midi) {
    final name = spelledPitchClass(midi);
    final shift = name.endsWith('#')
        ? 1
        : name.endsWith('b')
        ? -1
        : 0;
    return '$name${(midi - shift) ~/ 12 - 1}';
  }

  late final List<ScalePosition> positions = _findPositions();

  List<ScalePosition> _findPositions() {
    final byMidi = <int, ScalePosition>{};
    for (var string = openStringMidi.length; string >= 1; string--) {
      for (var fret = minFret; fret <= maxFret; fret++) {
        final midi = openStringMidi[string - 1] + fret;
        if (intervals.contains((midi - root) % 12)) {
          byMidi[midi] = ScalePosition(string: string, fret: fret, midi: midi);
        }
      }
    }
    return byMidi.values.toList()..sort((a, b) => a.midi.compareTo(b.midi));
  }

  bool isRoot(int midi) => midi % 12 == root;
}
