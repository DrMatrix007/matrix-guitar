import 'scale.dart';

enum ChordTone {
  root('root'),
  third('third'),
  fifth('fifth'),
  seventh('seventh');

  const ChordTone(this.label);
  final String label;
}

enum HarmonyQuality {
  major('Major', '', '1–3–5'),
  minor('Minor', 'm', '1–b3–5'),
  major7('Maj7', 'maj7', '1–3–5–7'),
  minor7('Min7', 'm7', '1–b3–5–b7'),
  dominant7('Dom7', '7', '1–3–5–b7');

  const HarmonyQuality(this.patternName, this.suffix, this.formula);
  final String patternName;
  final String suffix;
  final String formula;
  PatternDefinition get pattern => patterns.firstWhere(
    (p) => p.kind == PatternKind.arpeggio && p.name == patternName,
  );
}

class FunctionalChord {
  final String roman;
  final int degree;
  final HarmonyQuality quality;
  final String explanation;

  const FunctionalChord(
    this.roman,
    this.degree,
    this.quality,
    this.explanation,
  );
}

class HarmonyProgression {
  final String name;
  final List<FunctionalChord> functions;

  const HarmonyProgression(this.name, this.functions);

  bool get hasSevenths =>
      functions.every((f) => f.quality.pattern.intervals.length == 4);

  List<HarmonyChord> chords(int key, FretWindow window) => [
    for (final function in functions) HarmonyChord(key, function, window),
  ];
}

const harmonyProgressions = [
  HarmonyProgression('ii7–V7–Imaj7', [
    FunctionalChord(
      'ii7',
      1,
      HarmonyQuality.minor7,
      'ii is the minor chord on the second note of the key. It prepares V, the chord on the fifth note.',
    ),
    FunctionalChord(
      'V7',
      4,
      HarmonyQuality.dominant7,
      'V is the chord on the fifth note of the key. Its tension leads toward I, the home chord.',
    ),
    FunctionalChord(
      'Imaj7',
      0,
      HarmonyQuality.major7,
      'The tonic is home in this major key.',
    ),
  ]),
  HarmonyProgression('I–vi–IV–V', [
    FunctionalChord(
      'I',
      0,
      HarmonyQuality.major,
      'The tonic establishes home.',
    ),
    FunctionalChord(
      'vi',
      5,
      HarmonyQuality.minor,
      'The relative minor shares two notes with I.',
    ),
    FunctionalChord(
      'IV',
      3,
      HarmonyQuality.major,
      'The subdominant moves away from home.',
    ),
    FunctionalChord(
      'V',
      4,
      HarmonyQuality.major,
      'The dominant leads back to I.',
    ),
  ]),
  HarmonyProgression('I–V/ii–ii–V–I', [
    FunctionalChord(
      'I',
      0,
      HarmonyQuality.major,
      'The tonic establishes home.',
    ),
    FunctionalChord(
      'V/ii',
      5,
      HarmonyQuality.dominant7,
      'V/ii means “five of two”: a dominant seventh chord that leads to ii as a temporary home. Its third raises the first note of the major key by one semitone.',
    ),
    FunctionalChord(
      'ii',
      1,
      HarmonyQuality.minor,
      'The temporary target of V/ii prepares V.',
    ),
    FunctionalChord(
      'V',
      4,
      HarmonyQuality.major,
      'The dominant leads back to I.',
    ),
    FunctionalChord(
      'I',
      0,
      HarmonyQuality.major,
      'The tonic resolves the progression.',
    ),
  ]),
  HarmonyProgression('I–IV–iv–I', [
    FunctionalChord(
      'I',
      0,
      HarmonyQuality.major,
      'The tonic establishes home.',
    ),
    FunctionalChord(
      'IV',
      3,
      HarmonyQuality.major,
      'The major subdominant introduces the key sixth.',
    ),
    FunctionalChord(
      'iv',
      3,
      HarmonyQuality.minor,
      'iv is borrowed from the minor key with the same home note. Lowering the third of IV by one semitone makes iv; this lowered key sixth can fall to the fifth of I.',
    ),
    FunctionalChord(
      'I',
      0,
      HarmonyQuality.major,
      'The tonic resolves the borrowed minor color.',
    ),
  ]),
];

class HarmonyChord {
  final int key;
  final FunctionalChord function;
  final FretWindow window;

  HarmonyChord(this.key, this.function, this.window);

  late final keyScale = ScaleDefinition(patterns.first, key, window);
  late final int root = (key + keyScale.intervals[function.degree]) % 12;
  late final scale = ScaleDefinition(function.quality.pattern, root, window);
  String get name =>
      '${keyScale.noteNames[function.degree]}${function.quality.suffix}';
  List<int> get intervals => scale.intervals;
  List<ChordTone> get tones => ChordTone.values.take(intervals.length).toList();
  late final List<String> noteNames = [
    for (final (index, interval) in intervals.indexed)
      _spell(interval, function.quality.pattern.letterSteps[index]),
  ];

  String _spell(int interval, int step) {
    const letters = 'CDEFGAB';
    const pitches = [0, 2, 4, 5, 7, 9, 11];
    final letter =
        (letters.indexOf(keyScale.noteNames[function.degree][0]) + step) % 7;
    final shift = (root + interval - pitches[letter] + 6) % 12 - 6;
    return '${letters[letter]}${shift >= 0 ? '#' * shift : 'b' * -shift}';
  }

  String toneName(ChordTone tone) => noteNames[tone.index];
  int pitchClass(ChordTone tone) => (root + intervals[tone.index]) % 12;

  List<String> inversionNames(int index) => [
    ...noteNames.skip(index),
    ...noteNames.take(index),
  ];

  ScalePosition nearestPosition(Iterable<ChordTone> tones, int previousMidi) {
    final pitches = tones.map(pitchClass).toSet();
    final positions = scale.positions
        .where((p) => pitches.contains(p.midi % 12))
        .toList();
    positions.sort((a, b) {
      final distance = (a.midi - previousMidi).abs().compareTo(
        (b.midi - previousMidi).abs(),
      );
      return distance == 0 ? a.midi.compareTo(b.midi) : distance;
    });
    return positions.first;
  }
}

class HarmonyTarget {
  final HarmonyChord chord;
  final ChordTone tone;
  final ScalePosition position;
  final int? previousMidi;

  const HarmonyTarget(this.chord, this.tone, this.position, this.previousMidi);

  String get explanation {
    final movement = previousMidi == null
        ? 'Start here.'
        : switch (position.midi - previousMidi!) {
            0 => 'Keep the common tone (0 semitones).',
            final distance when distance > 0 =>
              'Move up $distance semitone${distance == 1 ? '' : 's'}.',
            final distance =>
              'Move down ${-distance} semitone${distance == -1 ? '' : 's'}.',
          };
    return '${chord.toneName(tone)} is the chord-relative ${tone.label} of ${chord.name}: ${chord.intervals[tone.index]} semitones above its root ${chord.noteNames.first}. '
        'Formula: ${chord.function.quality.formula}; notes: ${chord.noteNames.join('–')}. $movement ${chord.function.explanation}';
  }
}

List<HarmonyTarget> harmonyTargets(
  List<HarmonyChord> chords, {
  ChordTone tone = ChordTone.third,
  bool guideTones = false,
}) {
  final targets = <HarmonyTarget>[];
  for (final chord in chords) {
    final previous = targets.isEmpty ? null : targets.last.position.midi;
    final choices = guideTones
        ? [
            ChordTone.third,
            if (chord.tones.contains(ChordTone.seventh)) ChordTone.seventh,
          ]
        : [tone];
    final position = chord.nearestPosition(choices, previous ?? 60);
    final selected = choices.firstWhere(
      (t) => chord.pitchClass(t) == position.midi % 12,
    );
    targets.add(HarmonyTarget(chord, selected, position, previous));
  }
  return targets;
}
