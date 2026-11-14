import 'dart:math';
import 'dart:typed_data';

import 'package:matrix_guitar/audio/debug_tone_source.dart';
import 'package:matrix_guitar/audio/note_listener.dart';
import 'package:matrix_guitar/audio/pitch_detector.dart';
import 'package:matrix_guitar/audio/strum_detector.dart';
import 'package:matrix_guitar/theory/note.dart';

const pureProfile = [1.0];
const guitarProfile = [1.0, .8, .5, .3, .2, .1];
const weakProfile = [.15, 1.0, .7, .4, .25, .1];
const hardProfile = [.05, 1.0, .1, .3, .1, .1];

Float64List sine(
  double frequency, {
  double amplitude = 0.5,
  double duration = 1,
}) {
  final samples = silence(duration);
  for (var i = 0; i < samples.length; i++) {
    samples[i] = amplitude * sin(2 * pi * frequency * i / sampleRate);
  }
  return samples;
}

Float64List silence(double duration) =>
    Float64List((duration * sampleRate).round());

Float64List whiteNoise({
  double amplitude = 0.5,
  double duration = 1,
  int seed = 1,
}) {
  final random = Random(seed);
  final samples = silence(duration);
  for (var i = 0; i < samples.length; i++) {
    samples[i] = amplitude * (random.nextDouble() * 2 - 1);
  }
  return samples;
}

Float64List glide(
  double startFrequency,
  double endFrequency, {
  required int length,
  double amplitude = 0.5,
}) {
  final samples = Float64List(length);
  var phase = 0.0;
  for (var i = 0; i < length; i++) {
    samples[i] = amplitude * sin(phase);
    final frequency =
        startFrequency + (endFrequency - startFrequency) * i / length;
    phase += 2 * pi * frequency / sampleRate;
  }
  return samples;
}

Float64List concat(List<Float64List> parts) =>
    Float64List.fromList([for (final part in parts) ...part]);

Float64List mix(List<Float64List> parts) {
  final samples = Float64List(parts.map((part) => part.length).reduce(max));
  for (final part in parts) {
    for (var i = 0; i < part.length; i++) {
      samples[i] += part[i];
    }
  }
  return samples;
}

Float64List detunedPluck(
  int midi,
  double cents, {
  List<double> harmonics = guitarProfile,
  double amplitude = 0.5,
  double duration = 1,
}) {
  final frequency = midiToFrequency(midi + cents / 100);
  final scale = amplitude / harmonics.reduce((a, b) => a + b);
  final samples = silence(duration);
  for (var i = 0; i < samples.length; i++) {
    final t = i / sampleRate;
    var sum = 0.0;
    for (var k = 0; k < harmonics.length; k++) {
      final number = k + 1;
      sum +=
          harmonics[k] *
          exp(-t * (1 + 0.6 * number)) *
          sin(2 * pi * frequency * number * t + k);
    }
    samples[i] = scale * sum;
  }
  return samples;
}

Float64List overlapStrums(
  List<int> notes, {
  required double gap,
  required int count,
  double duration = 2,
}) {
  final strum = synthStrum(notes, duration: duration);
  return mix([
    for (var i = 0; i < count; i++) concat([silence(i * gap), strum]),
  ]);
}

List<StrumEvent> runStrums(
  Float64List samples,
  List<int> notes, {
  int? chunkSize,
}) {
  final events = <StrumEvent>[];
  final detector = StrumDetector(notes: notes, onStrum: events.add);
  final step = chunkSize ?? samples.length;
  for (var start = 0; start < samples.length; start += step) {
    detector.addSamples(
      samples.sublist(start, min(start + step, samples.length)),
    );
  }
  return events;
}

({List<NoteEvent> events, List<FrameReading> readings}) runListener(
  Float64List samples, {
  int? chunkSize,
  int? expectedMidi,
}) {
  final events = <NoteEvent>[];
  final readings = <FrameReading>[];
  final listener = NoteListener(onNote: events.add, onReading: readings.add)
    ..expectedMidi = expectedMidi;
  final step = chunkSize ?? samples.length;
  for (var start = 0; start < samples.length; start += step) {
    listener.addSamples(
      samples.sublist(start, min(start + step, samples.length)),
    );
  }
  return (events: events, readings: readings);
}
