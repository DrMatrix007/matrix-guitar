import 'package:flutter/material.dart';

import '../audio/audio_source.dart';
import '../theory/chord.dart';
import '../theory/scale.dart';
import 'chord_list_screen.dart';
import 'library_tile.dart';
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
      animationDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.graphic_eq_rounded, color: Color(0xFF60A5FA)),
              SizedBox(width: 10),
              Text('Matrix Guitar'),
            ],
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(64),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerHeight: 0,
                indicatorPadding: EdgeInsets.symmetric(horizontal: 3),
                tabs: [
                  Tab(text: 'Scales'),
                  Tab(text: 'Arpeggios'),
                  Tab(text: 'Chords'),
                  Tab(text: 'Theory'),
                ],
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final (index, pattern) in kindPatterns.indexed) ...[
          if (index == 0 || kindPatterns[index - 1].group != pattern.group)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
              child: Text(
                pattern.group,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          LibraryTile(
            title: pattern.name,
            icon: kind == PatternKind.scale
                ? Icons.stairs_rounded
                : Icons.piano_rounded,
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
