import 'dart:math';

const _sharpNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];
const _flatNames = [
  'C',
  'Db',
  'D',
  'Eb',
  'E',
  'F',
  'Gb',
  'G',
  'Ab',
  'A',
  'Bb',
  'B',
];

String pitchClassName(int midi, {bool useFlats = false}) =>
    (useFlats ? _flatNames : _sharpNames)[midi % 12];

String noteName(int midi, {bool useFlats = false}) =>
    '${pitchClassName(midi, useFlats: useFlats)}${midi ~/ 12 - 1}';

int noteToMidi(String name) {
  final octaveStart = name.indexOf(RegExp(r'-?\d'));
  final pitchClass = name.substring(0, octaveStart);
  final octave = int.parse(name.substring(octaveStart));
  final names = _sharpNames.contains(pitchClass) ? _sharpNames : _flatNames;
  return (octave + 1) * 12 + names.indexOf(pitchClass);
}

double midiToFrequency(num midi) => 440.0 * pow(2, (midi - 69) / 12);

({int midi, double cents}) frequencyToNote(double hz) {
  final exactMidi = 69 + 12 * log(hz / 440) / ln2;
  final midi = exactMidi.round();
  return (midi: midi, cents: (exactMidi - midi) * 100);
}
