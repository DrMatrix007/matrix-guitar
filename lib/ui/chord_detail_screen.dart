import 'package:flutter/material.dart';

import '../audio/audio_source.dart';
import '../theory/chord.dart';
import 'chord_diagram.dart';
import 'chord_practice_screen.dart';
import 'fretboard.dart';
import 'legend_entry.dart';

class ChordDetailScreen extends StatelessWidget {
  final ChordVoicing chord;
  final AudioSource Function(ChordVoicing) chordAudioSourceFactory;

  const ChordDetailScreen({
    super.key,
    required this.chord,
    required this.chordAudioSourceFactory,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final notes = chord.noteNames.join('  ');

    return Scaffold(
      appBar: AppBar(title: Text(chord.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              chord.displayName,
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: Center(
                child: SizedBox(
                  width: 200,
                  child: ChordDiagram(chord: chord),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Notes: $notes', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _stringsDescription(),
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                LegendEntry(color: colors.primary, label: 'Root'),
                const SizedBox(width: 16),
                const LegendEntry(color: highlightFill, label: 'Other'),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChordPracticeScreen(
                    chord: chord,
                    chordAudioSourceFactory: chordAudioSourceFactory,
                  ),
                ),
              ),
              child: const Text('Practice'),
            ),
          ],
        ),
      ),
    );
  }

  String _stringsDescription() {
    final parts = <String>[];
    for (var i = 0; i < 6; i++) {
      final stringNum = 6 - i;
      final fret = chord.frets[i];
      if (fret < 0) {
        parts.add('String $stringNum: muted');
      } else if (fret == 0) {
        parts.add('String $stringNum: open');
      } else {
        final midi = chord.midiNotes[i]!;
        parts.add('String $stringNum: fret $fret (${chord.spell(midi)})');
      }
    }
    return parts.join('\n');
  }
}
