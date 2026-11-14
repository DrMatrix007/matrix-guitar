import 'package:flutter/material.dart';

import '../audio/audio_source.dart';
import '../theory/chord.dart';
import 'chord_detail_screen.dart';
import 'library_tile.dart';

class ChordListScreen extends StatelessWidget {
  final AudioSource Function(ChordVoicing) chordAudioSourceFactory;

  const ChordListScreen({super.key, required this.chordAudioSourceFactory});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final (index, chord) in chordLibrary.indexed) ...[
          if (index == 0 || chordLibrary[index - 1].group != chord.group)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
              child: Text(
                chord.group,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          LibraryTile(
            title: chord.name,
            subtitle: chord.quality.label,
            icon: Icons.grid_view_rounded,
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
