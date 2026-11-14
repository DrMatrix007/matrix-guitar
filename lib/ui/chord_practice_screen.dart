import 'dart:math';

import 'package:flutter/material.dart';

import '../audio/audio_source.dart';
import '../audio/strum_detector.dart';
import '../practice/chord_practice_controller.dart';
import '../theory/chord.dart';
import 'chord_diagram.dart';
import 'mic_gate.dart';
import 'summary_screen.dart';

class ChordPracticeScreen extends StatefulWidget {
  final ChordVoicing chord;
  final AudioSource Function(ChordVoicing) chordAudioSourceFactory;

  const ChordPracticeScreen({
    super.key,
    required this.chord,
    required this.chordAudioSourceFactory,
  });

  @override
  State<ChordPracticeScreen> createState() => _ChordPracticeScreenState();
}

class _ChordPracticeScreenState extends State<ChordPracticeScreen> {
  late final ChordPracticeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChordPracticeController(
      chord: widget.chord,
      source: widget.chordAudioSourceFactory(widget.chord),
    );
    _controller.addListener(_onControllerChanged);
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!_controller.isComplete) return;
    _controller.removeListener(_onControllerChanged);
    final summaryScreen = SummaryScreen(
      title: widget.chord.displayName,
      summary: _controller.summary,
    );
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => summaryScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.chord.name} practice')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => MicGate(
          controller: _controller,
          child: _ChordPracticeView(
            controller: _controller,
            chord: widget.chord,
          ),
        ),
      ),
    );
  }
}

class _ChordPracticeView extends StatelessWidget {
  final ChordPracticeController controller;
  final ChordVoicing chord;

  const _ChordPracticeView({required this.controller, required this.chord});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final correct = controller.correct;
    final strum = controller.lastStrum;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Strum ${min(correct + 1, chordStrumCount)} of $chordStrumCount',
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: correct / chordStrumCount),
          const SizedBox(height: 16),
          Text(
            'Play the ${chord.name} chord',
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: Center(
              child: SizedBox(width: 180, child: ChordDiagram(chord: chord)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Listening...', style: textTheme.titleLarge),
          if (strum != null) ...[
            const SizedBox(height: 8),
            Text(
              strum.correct ? 'Correct' : _wrongText(strum),
              style: textTheme.titleMedium?.copyWith(
                color: strum.correct
                    ? correctColor
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _wrongText(StrumEvent strum) {
    final parts = [
      if (strum.missing.isNotEmpty) 'missing ${_names(strum.missing)}',
      if (strum.extra.isNotEmpty) 'extra ${_names(strum.extra)}',
    ];
    return 'Wrong: ${parts.join(', ')}';
  }

  String _names(Set<int> pitchClasses) =>
      pitchClasses.map(chord.spell).join(' ');
}
