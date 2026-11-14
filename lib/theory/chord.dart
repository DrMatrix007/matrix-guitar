import 'scale.dart';

const chordStrumCount = 10;

enum ChordQuality {
  major('Major', 'Major'),
  minor('Minor', 'Minor'),
  dom7('Dominant 7th', 'Dom7'),
  min7('Minor 7th', 'Min7'),
  maj7('Major 7th', 'Maj7'),
  power('Power chord', 'Major');

  const ChordQuality(this.label, this.arpeggioName);

  final String label;
  final String arpeggioName;
}

/// A single chord voicing on the guitar fretboard.
///
/// [frets] has 6 entries (index 0 = low E, index 5 = high E).
/// A value of -1 means the string is muted / not played.
class ChordVoicing {
  final String name;
  final ChordQuality quality;
  final String group;
  final int root;
  final List<int> frets;

  const ChordVoicing({
    required this.name,
    required this.quality,
    required this.group,
    required this.root,
    required this.frets,
  });

  List<int?> get midiNotes => [
    for (var i = 0; i < 6; i++)
      frets[i] >= 0 ? openStringMidi[5 - i] + frets[i] : null,
  ];

  List<int> get playedNotes => midiNotes.nonNulls.toList();

  String spell(int midi) {
    final arpeggioPattern = patterns.firstWhere(
      (pattern) =>
          pattern.kind == PatternKind.arpeggio &&
          pattern.name == quality.arpeggioName,
    );
    return ScaleDefinition(
      arpeggioPattern,
      root,
      defaultFretWindow(root),
    ).spelledPitchClass(midi);
  }

  String get displayName => '${spell(root)} ${quality.label.toLowerCase()}';

  List<String> get noteNames => playedNotes.map(spell).toList();
}

const List<ChordVoicing> chordLibrary = [
  // ── Open major chords ──
  ChordVoicing(
    name: 'C', quality: ChordQuality.major, group: 'Open chords',
    root: 0, frets: [-1, 3, 2, 0, 1, 0],
  ),
  ChordVoicing(
    name: 'D', quality: ChordQuality.major, group: 'Open chords',
    root: 2, frets: [-1, -1, 0, 2, 3, 2],
  ),
  ChordVoicing(
    name: 'E', quality: ChordQuality.major, group: 'Open chords',
    root: 4, frets: [0, 2, 2, 1, 0, 0],
  ),
  ChordVoicing(
    name: 'G', quality: ChordQuality.major, group: 'Open chords',
    root: 7, frets: [3, 2, 0, 0, 0, 3],
  ),
  ChordVoicing(
    name: 'A', quality: ChordQuality.major, group: 'Open chords',
    root: 9, frets: [-1, 0, 2, 2, 2, 0],
  ),

  // ── Open minor chords ──
  ChordVoicing(
    name: 'Dm', quality: ChordQuality.minor, group: 'Open chords',
    root: 2, frets: [-1, -1, 0, 2, 3, 1],
  ),
  ChordVoicing(
    name: 'Em', quality: ChordQuality.minor, group: 'Open chords',
    root: 4, frets: [0, 2, 2, 0, 0, 0],
  ),
  ChordVoicing(
    name: 'Am', quality: ChordQuality.minor, group: 'Open chords',
    root: 9, frets: [-1, 0, 2, 2, 1, 0],
  ),

  // ── Open 7th chords ──
  ChordVoicing(
    name: 'D7', quality: ChordQuality.dom7, group: 'Seventh chords',
    root: 2, frets: [-1, -1, 0, 2, 1, 2],
  ),
  ChordVoicing(
    name: 'E7', quality: ChordQuality.dom7, group: 'Seventh chords',
    root: 4, frets: [0, 2, 0, 1, 0, 0],
  ),
  ChordVoicing(
    name: 'G7', quality: ChordQuality.dom7, group: 'Seventh chords',
    root: 7, frets: [3, 2, 0, 0, 0, 1],
  ),
  ChordVoicing(
    name: 'A7', quality: ChordQuality.dom7, group: 'Seventh chords',
    root: 9, frets: [-1, 0, 2, 0, 2, 0],
  ),
  ChordVoicing(
    name: 'B7', quality: ChordQuality.dom7, group: 'Seventh chords',
    root: 11, frets: [-1, 2, 1, 2, 0, 2],
  ),

  // ── Minor 7th ──
  ChordVoicing(
    name: 'Am7', quality: ChordQuality.min7, group: 'Seventh chords',
    root: 9, frets: [-1, 0, 2, 0, 1, 0],
  ),
  ChordVoicing(
    name: 'Em7', quality: ChordQuality.min7, group: 'Seventh chords',
    root: 4, frets: [0, 2, 0, 0, 0, 0],
  ),
  ChordVoicing(
    name: 'Dm7', quality: ChordQuality.min7, group: 'Seventh chords',
    root: 2, frets: [-1, -1, 0, 2, 1, 1],
  ),

  // ── Major 7th ──
  ChordVoicing(
    name: 'Cmaj7', quality: ChordQuality.maj7, group: 'Seventh chords',
    root: 0, frets: [-1, 3, 2, 0, 0, 0],
  ),
  ChordVoicing(
    name: 'Fmaj7', quality: ChordQuality.maj7, group: 'Seventh chords',
    root: 5, frets: [-1, -1, 3, 2, 1, 0],
  ),

  // ── Barre chords (E and A shapes) ──
  ChordVoicing(
    name: 'F', quality: ChordQuality.major, group: 'Barre chords',
    root: 5, frets: [1, 3, 3, 2, 1, 1],
  ),
  ChordVoicing(
    name: 'F#', quality: ChordQuality.major, group: 'Barre chords',
    root: 6, frets: [2, 4, 4, 3, 2, 2],
  ),
  ChordVoicing(
    name: 'Bb', quality: ChordQuality.major, group: 'Barre chords',
    root: 10, frets: [-1, 1, 3, 3, 3, 1],
  ),
  ChordVoicing(
    name: 'Bm', quality: ChordQuality.minor, group: 'Barre chords',
    root: 11, frets: [-1, 2, 4, 4, 3, 2],
  ),
  ChordVoicing(
    name: 'Fm', quality: ChordQuality.minor, group: 'Barre chords',
    root: 5, frets: [1, 3, 3, 1, 1, 1],
  ),
  ChordVoicing(
    name: 'C7', quality: ChordQuality.dom7, group: 'Barre chords',
    root: 0, frets: [-1, 3, 5, 3, 5, 3],
  ),

  // ── Power chords ──
  ChordVoicing(
    name: 'E5', quality: ChordQuality.power, group: 'Power chords',
    root: 4, frets: [0, 2, 2, -1, -1, -1],
  ),
  ChordVoicing(
    name: 'A5', quality: ChordQuality.power, group: 'Power chords',
    root: 9, frets: [-1, 0, 2, 2, -1, -1],
  ),
  ChordVoicing(
    name: 'D5', quality: ChordQuality.power, group: 'Power chords',
    root: 2, frets: [-1, -1, 0, 2, 3, -1],
  ),
  ChordVoicing(
    name: 'G5', quality: ChordQuality.power, group: 'Power chords',
    root: 7, frets: [3, 5, 5, -1, -1, -1],
  ),
  ChordVoicing(
    name: 'C5', quality: ChordQuality.power, group: 'Power chords',
    root: 0, frets: [-1, 3, 5, 5, -1, -1],
  ),
];
