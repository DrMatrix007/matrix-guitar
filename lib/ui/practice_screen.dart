import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../audio/audio_source.dart';
import '../audio/note_listener.dart';
import '../practice/practice_controller.dart';
import '../practice/practice_options.dart';
import '../practice/practice_session.dart';
import '../theory/scale.dart';
import 'fretboard.dart';
import 'summary_screen.dart';

const _correctColor = Color(0xFF66BB6A);
const _inTuneLimit = 3;

String _centsLabel(double cents) {
  final rounded = cents.round();
  if (rounded.abs() < _inTuneLimit) return 'in tune';
  return rounded > 0 ? '+$rounded cents sharp' : '$rounded cents flat';
}

class PracticeScreen extends StatefulWidget {
  final ScaleDefinition scale;
  final List<ScalePosition> sequence;
  final HintLevel hints;
  final AudioSource Function(List<ScalePosition>) audioSourceFactory;

  const PracticeScreen({
    super.key,
    required this.scale,
    required this.sequence,
    required this.hints,
    required this.audioSourceFactory,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PracticeController _controller;
  late final int _noteCount;

  @override
  void initState() {
    super.initState();
    final sequence = widget.sequence;
    _noteCount = sequence.length;
    _controller = PracticeController(
      sequence: sequence,
      source: widget.audioSourceFactory(sequence),
    );
    _controller.addListener(_onControllerChanged);
    _controller.start();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller.session.phase != SessionPhase.complete) return;
    _controller.removeListener(_onControllerChanged);
    final summaryScreen = SummaryScreen(
      scale: widget.scale,
      summary: _controller.session.summary,
    );
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => summaryScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.scale.name)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final practiceView = _PracticeView(
      controller: _controller,
      scale: widget.scale,
      noteCount: _noteCount,
      hints: widget.hints,
    );
    if (_controller.session.phase == SessionPhase.complete) return practiceView;
    return switch (_controller.micState) {
      MicState.requesting => const Center(child: CircularProgressIndicator()),
      MicState.denied => _MicMessage(
        message: 'Microphone access is needed to hear your playing.',
        actionLabel: 'Try again',
        onAction: _controller.start,
      ),
      MicState.permanentlyDenied => _MicMessage(
        message: 'Microphone access is blocked. Allow it in settings.',
        actionLabel: 'Open settings',
        onAction: _controller.openSettings,
      ),
      MicState.listening => practiceView,
      MicState.paused => const Center(child: Text('Paused')),
      MicState.error => _MicMessage(
        message: 'The microphone could not be started.',
        actionLabel: 'Try again',
        onAction: _controller.start,
      ),
    };
  }
}

class _PracticeView extends StatelessWidget {
  final PracticeController controller;
  final ScaleDefinition scale;
  final int noteCount;
  final HintLevel hints;

  const _PracticeView({
    required this.controller,
    required this.scale,
    required this.noteCount,
    required this.hints,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final session = controller.session;
    final expected = session.expected;
    final event = controller.lastEvent;
    final correct = controller.lastResult == NoteResult.correct;
    final resultColor = correct
        ? _correctColor
        : Theme.of(context).colorScheme.error;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Note ${min(session.index + 1, noteCount)} of $noteCount'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: session.index / noteCount),
          const SizedBox(height: 16),
          if (hints != HintLevel.fromMemory) ...[
            Fretboard(
              scale: scale,
              highlight: expected,
              showNames: hints == HintLevel.full,
            ),
            const SizedBox(height: 16),
            if (expected != null)
              Text(_nextNoteText(expected), style: textTheme.titleLarge),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: switch (controller.reading) {
              FrameReading(midi: final midi?, cents: final cents?) => [
                Text(_name(midi), style: textTheme.titleLarge),
                Text(_centsLabel(cents)),
              ],
              _ => [Text('Listening...', style: textTheme.titleLarge)],
            },
          ),
          if (event != null) ...[
            const SizedBox(height: 8),
            Text(
              correct ? 'Correct' : 'Wrong: played ${_name(event.midi)}',
              style: textTheme.titleMedium?.copyWith(color: resultColor),
            ),
            Text(
              _centsLabel(event.cents),
              style: TextStyle(color: resultColor),
            ),
          ],
        ],
      ),
    );
  }

  String _nextNoteText(ScalePosition expected) {
    final location = 'string ${expected.string}, fret ${expected.fret}';
    return hints == HintLevel.full
        ? '${_name(expected.midi)} - $location'
        : location;
  }

  String _name(int midi) => scale.spelledNote(midi);
}

class _MicMessage extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MicMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
