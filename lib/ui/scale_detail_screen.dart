import 'package:flutter/material.dart';

import '../audio/audio_source.dart';
import '../theory/scale.dart';
import 'fretboard.dart';
import 'legend_entry.dart';
import 'practice_setup_screen.dart';

const _defaultRoot = 9;

class ScaleDetailScreen extends StatefulWidget {
  final PatternDefinition pattern;
  final AudioSource Function(List<ScalePosition>) audioSourceFactory;

  const ScaleDetailScreen({
    super.key,
    required this.pattern,
    required this.audioSourceFactory,
  });

  @override
  State<ScaleDetailScreen> createState() => _ScaleDetailScreenState();
}

class _ScaleDetailScreenState extends State<ScaleDetailScreen> {
  int _root = _defaultRoot;
  FretWindow _window = defaultFretWindow(_defaultRoot);

  void _selectRoot(int root) {
    if (root == _root) return;
    setState(() {
      _root = root;
      _window = defaultFretWindow(root);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scale = ScaleDefinition(widget.pattern, _root, _window);
    final notes = scale.noteNames.join(' ');

    return Scaffold(
      appBar: AppBar(title: Text(scale.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var pitchClass = 0; pitchClass < 12; pitchClass++)
                  ChoiceChip(
                    label: Text(rootName(pitchClass)),
                    selected: pitchClass == _root,
                    onSelected: (_) => _selectRoot(pitchClass),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final window in fretWindows(_root))
                  ChoiceChip(
                    label: Text('Frets ${window.minFret}-${window.maxFret}'),
                    selected: window == _window,
                    onSelected: (_) => setState(() => _window = window),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Fretboard(scale: scale),
            const SizedBox(height: 16),
            Text(notes, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                LegendEntry(color: colors.primary, label: 'Root'),
                const SizedBox(width: 16),
                LegendEntry(color: colors.secondaryContainer, label: 'Other'),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PracticeSetupScreen(
                    scale: scale,
                    audioSourceFactory: widget.audioSourceFactory,
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
}
