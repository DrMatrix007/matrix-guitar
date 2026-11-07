import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import '../theory/note.dart';
import '../theory/scale.dart';
import 'audio_source.dart';
import 'pitch_detector.dart';

const _noteDuration = 0.7;
const _chunkInterval = Duration(
  microseconds: hopSize * Duration.microsecondsPerSecond ~/ sampleRate,
);

Float64List synthPluck({
  required int midi,
  List<double> harmonics = const [1.0, 0.8, 0.5, 0.3, 0.2, 0.1],
  double noise = 0,
  int seed = 1,
  double amplitude = 0.5,
  double duration = 1,
  double decay = 1,
}) {
  final frequency = midiToFrequency(midi);
  final scale = amplitude / harmonics.reduce((a, b) => a + b);
  final random = Random(seed);
  final samples = Float64List((duration * sampleRate).round());
  for (var i = 0; i < samples.length; i++) {
    final t = i / sampleRate;
    var sum = noise * (random.nextDouble() * 2 - 1);
    for (var k = 0; k < harmonics.length; k++) {
      final number = k + 1;
      sum +=
          harmonics[k] *
          exp(-t * decay * (1 + 0.6 * number)) *
          sin(2 * pi * frequency * number * t + k);
    }
    samples[i] = scale * sum;
  }
  return samples;
}

class DebugToneSource implements AudioSource {
  late final Float64List _audio;
  var _cursor = 0;
  Timer? _timer;
  StreamController<Float64List>? _controller;

  DebugToneSource(List<ScalePosition> sequence) {
    final midis = sequence.map((position) => position.midi).toList();
    midis.insert(2, midis[2] + 1);
    _audio = Float64List.fromList([
      for (final midi in midis)
        ...synthPluck(midi: midi, duration: _noteDuration),
    ]);
  }

  @override
  Future<MicPermission> requestPermission() async => MicPermission.granted;

  @override
  Future<void> openSettings() async {}

  @override
  Future<Stream<Float64List>> start() async {
    final controller = _controller = StreamController<Float64List>();
    _timer = Timer.periodic(_chunkInterval, (_) {
      final chunk = Float64List(hopSize);
      final end = min(_cursor + hopSize, _audio.length);
      chunk.setRange(0, end - _cursor, _audio, _cursor);
      _cursor = end;
      controller.add(chunk);
    });
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _controller?.close();
  }
}
