import 'package:flutter/material.dart';

import '../theory/chord.dart';
import 'staff_notation.dart';

class ChordExplanation extends StatelessWidget {
  final ChordVoicing chord;

  const ChordExplanation({super.key, required this.chord});

  @override
  Widget build(BuildContext context) {
    final intervals = switch (chord.quality) {
      ChordQuality.major => [0, 4, 7],
      ChordQuality.minor => [0, 3, 7],
      ChordQuality.dom7 => [0, 4, 7, 10],
      ChordQuality.min7 => [0, 3, 7, 10],
      ChordQuality.maj7 => [0, 4, 7, 11],
      ChordQuality.power => [0, 7],
    };
    final degrees = switch (chord.quality) {
      ChordQuality.major => ['1', '3', '5'],
      ChordQuality.minor => ['1', 'b3', '5'],
      ChordQuality.dom7 => ['1', '3', '5', 'b7'],
      ChordQuality.min7 => ['1', 'b3', '5', 'b7'],
      ChordQuality.maj7 => ['1', '3', '5', '7'],
      ChordQuality.power => ['1', '5'],
    };
    final rootMidi = 60 + chord.root;
    final explanation = switch (chord.quality) {
      ChordQuality.major => 'The major third (4 semitones) defines the major quality. The fifth supports the root.',
      ChordQuality.minor => 'The minor third is 3 semitones above the root, one fret lower than a major third. That change defines the minor quality.',
      ChordQuality.dom7 => 'A major triad plus a flat seventh. The third and flat seventh form a tritone (6 semitones), which often resolves toward a tonic chord a fifth below the root.',
      ChordQuality.min7 => 'A minor triad plus a flat seventh. In a major key, a minor seventh chord on degree ii often prepares V7.',
      ChordQuality.maj7 => 'A major triad plus a major seventh, 11 semitones above the root. Compare this with a dominant seventh: its seventh is one semitone lower.',
      ChordQuality.power => 'Only root and fifth: there is no third, so this shape is neither major nor minor. The octave doubles the root without adding a new chord tone.',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(
          'How this chord is built',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(explanation),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (index, interval) in intervals.indexed)
              Chip(
                label: Text(
                  '${degrees[index]} · ${chord.spell(rootMidi + interval)} · $interval semitones',
                ),
              ),
          ],
        ),
        const Text(
          'Formula numbers are relative to this chord’s root. One semitone equals one fret on a string.',
        ),
        StaffNotation(
          selectedIndex: 0,
          stacked: true,
          notes: [
            for (final interval in intervals)
              StaffNote(rootMidi + interval, chord.spell(rootMidi + interval)),
          ],
        ),
        const Text(
          'Chord tones stacked vertically are played together. The guitar shape above may repeat notes in several octaves.',
        ),
        const SizedBox(height: 12),
        Text(
          'How it fits a progression',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Text(
          'A chord name describes its notes, not a fixed job. In C major, C is I (home), F is IV (departure), and G or G7 is V (tension leading home). Am is vi, the relative minor. In another key those roles change. Open the progression explorer in Chords to see why each change connects.',
        ),
      ],
    );
  }
}
