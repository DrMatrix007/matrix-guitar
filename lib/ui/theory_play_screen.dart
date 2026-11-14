import 'package:flutter/material.dart';

import '../audio/audio_source.dart';
import '../audio/note_listener.dart';
import '../practice/practice_controller.dart';
import '../practice/practice_session.dart';
import '../theory/harmony.dart';
import '../theory/scale.dart';
import 'mic_gate.dart';
import 'summary_screen.dart';

class TheoryPlayScreen extends StatefulWidget {
  final List<HarmonyTarget> targets;
  final AudioSource Function(List<ScalePosition>) audioSourceFactory;

  const TheoryPlayScreen({
    super.key,
    required this.targets,
    required this.audioSourceFactory,
  });

  @override
  State<TheoryPlayScreen> createState() => _TheoryPlayScreenState();
}

class _TheoryPlayScreenState extends State<TheoryPlayScreen> {
  late final PracticeController _controller;
  int _attemptIndex = 0;
  NoteEvent? _lastEvent;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    final sequence = widget.targets.map((target) => target.position).toList();
    _controller = PracticeController(
      sequence: sequence,
      source: widget.audioSourceFactory(sequence),
    );
    _controller.addListener(_changed);
    _controller.start();
  }

  void _changed() {
    final event = _controller.lastEvent;
    if (event != null && event != _lastEvent) {
      final attempted = widget.targets[_attemptIndex];
      _feedback =
          '${_controller.lastResult == NoteResult.correct ? 'Correct' : 'Try again'}: ${attempted.chord.name} (${attempted.chord.function.roman}), ${attempted.tone.label}. ${attempted.explanation}';
      _lastEvent = event;
      _attemptIndex = _controller.session.index;
    }
    if (_controller.session.phase == SessionPhase.complete) {
      _controller.removeListener(_changed);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SummaryScreen(
            title: 'Theory practice',
            summary: _controller.session.summary,
            noteName: widget.targets.first.chord.keyScale.spelledNote,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Theory · play single notes')),
    body: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) =>
          MicGate(controller: _controller, child: _view(context)),
    ),
  );

  Widget _view(BuildContext context) {
    final index = _controller.session.index;
    if (index == widget.targets.length) {
      return const Center(child: Text('Complete'));
    }
    final target = widget.targets[index];
    final position = target.position;
    final chord = target.chord;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Chord ${index + 1} of ${widget.targets.length}'),
        LinearProgressIndicator(value: index / widget.targets.length),
        const SizedBox(height: 16),
        Text(
          '${chord.keyScale.noteNames.first} major · key-relative ${chord.function.roman}',
        ),
        Text(chord.name, style: Theme.of(context).textTheme.headlineMedium),
        Text(
          'Play the chord-relative ${target.tone.label}: ${chord.toneName(target.tone)}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          '${chord.keyScale.spelledNote(position.midi)} · string ${position.string}, fret ${position.fret} · fixed frets 3–7',
        ),
        const SizedBox(height: 12),
        Text(target.explanation),
        const SizedBox(height: 16),
        Text(switch (_controller.reading) {
          FrameReading(midi: final midi?, cents: final cents?) =>
            'Hearing ${chord.keyScale.spelledNote(midi)} · ${cents.round()} cents',
          _ => 'Listening…',
        }),
        if (_lastEvent != null && _controller.lastResult == NoteResult.wrong)
          Text(
            'Played ${chord.keyScale.spelledNote(_lastEvent!.midi)}; match the target octave too.',
          ),
        if (_feedback != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(_feedback!),
          ),
        const Text(
          'String 1 is the thinnest, highest string; string 6 is the thickest, lowest. The number after a note name identifies its octave: match that height, not just the note letter. Play one note, then mute it. Chords with several notes sounding together are ungraded.',
        ),
      ],
    );
  }
}
