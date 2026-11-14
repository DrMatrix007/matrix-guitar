import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'audio/audio_source.dart';
import 'audio/debug_tone_source.dart';
import 'audio/mic_audio_source.dart';
import 'theory/chord.dart';
import 'theory/scale.dart';
import 'ui/scale_list_screen.dart';

const _fakeAudio = kDebugMode && bool.fromEnvironment('FAKE_AUDIO');
const _seedColor = Color(0xFFC026D3);

void main() {
  runApp(
    MatrixGuitarApp(
      audioSourceFactory: _fakeAudio
          ? DebugToneSource.new
          : (_) => MicAudioSource(),
      chordAudioSourceFactory: _fakeAudio
          ? DebugToneSource.strums
          : (_) => MicAudioSource(),
    ),
  );
}

class MatrixGuitarApp extends StatelessWidget {
  final AudioSource Function(List<ScalePosition>) audioSourceFactory;
  final AudioSource Function(ChordVoicing) chordAudioSourceFactory;

  const MatrixGuitarApp({
    super.key,
    required this.audioSourceFactory,
    required this.chordAudioSourceFactory,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matrix Guitar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      ),
      builder: _fakeAudio
          ? (_, child) => _SimulatedAudioStrip(child: child!)
          : null,
      home: ScaleListScreen(
        audioSourceFactory: audioSourceFactory,
        chordAudioSourceFactory: chordAudioSourceFactory,
      ),
    );
  }
}

class _SimulatedAudioStrip extends StatelessWidget {
  final Widget child;

  const _SimulatedAudioStrip({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: colors.tertiaryContainer,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                'Simulated audio',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onTertiaryContainer),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
