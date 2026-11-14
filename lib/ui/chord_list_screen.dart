import 'package:flutter/material.dart';

import '../audio/audio_source.dart';
import '../theory/chord.dart';
import 'chord_detail_screen.dart';
import 'progression_explorer.dart';

class ChordListScreen extends StatelessWidget {
  final AudioSource Function(ChordVoicing) chordAudioSourceFactory;

  const ChordListScreen({super.key, required this.chordAudioSourceFactory});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ExpansionTile(
          leading: Icon(Icons.route),
          title: Text('Explore chord progressions'),
          subtitle: Text('Chord roles, shared notes and voice leading'),
          childrenPadding: EdgeInsets.all(16),
          children: [ProgressionExplorer()],
        ),
        for (final (index, chord) in chordLibrary.indexed) ...[
          if (index == 0 || chordLibrary[index - 1].group != chord.group)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                chord.group,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ListTile(
            leading: const Icon(Icons.piano),
            title: Text(chord.name),
            subtitle: Text(chord.quality.label),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChordDetailScreen(
                  chord: chord,
                  chordAudioSourceFactory: chordAudioSourceFactory,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
