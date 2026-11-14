import 'package:flutter/material.dart';

import '../audio/audio_source.dart';
import '../theory/chord.dart';
import 'chord_detail_screen.dart';

class ChordListScreen extends StatelessWidget {
  final AudioSource Function(ChordVoicing) chordAudioSourceFactory;

  const ChordListScreen({super.key, required this.chordAudioSourceFactory});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final (index, chord) in chordLibrary.indexed) ...[
          if (index == 0 ||
              chordLibrary[index - 1].group != chord.group)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                chord.group,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ListTile(
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
