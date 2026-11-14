import 'package:flutter/material.dart';

import '../audio/audio_source.dart';
import '../theory/chord.dart';
import '../theory/scale.dart';
import 'chord_list_screen.dart';
import 'scale_detail_screen.dart';
import 'theory_practice_screen.dart';

class ScaleListScreen extends StatelessWidget {
  final AudioSource Function(List<ScalePosition>) audioSourceFactory;
  final AudioSource Function(ChordVoicing) chordAudioSourceFactory;

  const ScaleListScreen({
    super.key,
    required this.audioSourceFactory,
    required this.chordAudioSourceFactory,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Matrix Guitar'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.stairs), text: 'Scales'),
              Tab(icon: Icon(Icons.show_chart), text: 'Arpeggios'),
              Tab(icon: Icon(Icons.piano), text: 'Chords'),
              Tab(icon: Icon(Icons.school), text: 'Theory'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _patternList(context, PatternKind.scale),
            _patternList(context, PatternKind.arpeggio),
            ChordListScreen(chordAudioSourceFactory: chordAudioSourceFactory),
            TheoryPracticeScreen(audioSourceFactory: audioSourceFactory),
          ],
        ),
      ),
    );
  }

  Widget _patternList(BuildContext context, PatternKind kind) {
    final kindPatterns = patterns.where((p) => p.kind == kind).toList();
    return ListView(
      children: [
        for (final (index, pattern) in kindPatterns.indexed) ...[
          if (index == 0 || kindPatterns[index - 1].group != pattern.group)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                pattern.group,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ListTile(
            leading: Icon(
              kind == PatternKind.scale ? Icons.stairs : Icons.show_chart,
            ),
            title: Text(pattern.name),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ScaleDetailScreen(
                  pattern: pattern,
                  audioSourceFactory: audioSourceFactory,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
