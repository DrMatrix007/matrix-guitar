import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/audio/debug_tone_source.dart';
import 'package:matrix_guitar/audio/note_listener.dart';
import 'package:matrix_guitar/audio/pitch_detector.dart';
import 'package:matrix_guitar/practice/practice_options.dart';
import 'package:matrix_guitar/theory/note.dart';
import 'package:matrix_guitar/theory/scale.dart';

import '../helpers/signals.dart';

List<int> midis(Float64List samples) =>
    runListener(samples).events.map((event) => event.midi).toList();

Float64List held(int midi, {double amplitude = 0.5, double duration = 0.5}) =>
    synthPluck(midi: midi, amplitude: amplitude, duration: duration, decay: 0);

double sinePeakForRmsDb(double db) => pow(10, db / 20) * sqrt2;

Float64List levelStep(int midi, double ratio, int stepSample) {
  final tone = held(midi, amplitude: 0.2, duration: 1.5);
  for (var i = stepSample; i < tone.length; i++) {
    tone[i] *= ratio;
  }
  return tone;
}

Float64List levelRamp(int midi, double hopRatio, int startSample, int hops) {
  final tone = held(midi, amplitude: 0.1, duration: 1.5);
  for (var i = startSample; i < tone.length; i++) {
    final hopsRisen = min((i - startSample) / hopSize, hops);
    tone[i] *= pow(hopRatio, hopsRisen);
  }
  return tone;
}

double peakFrameRatio(
  List<FrameReading> readings, {
  int lag = attackLagFrames,
}) {
  var peak = 0.0;
  for (var t = lag; t < readings.length; t++) {
    final decibels = readings[t].levelDb - readings[t - lag].levelDb;
    peak = max(peak, pow(10, decibels / 20).toDouble());
  }
  return peak;
}

Float64List ringing(List<ScalePosition> sequence, double gap) {
  final step = (gap * sampleRate).round();
  final samples = Float64List(sequence.length * step + 2 * sampleRate);
  for (var i = 0; i < sequence.length; i++) {
    final nextOnString = sequence.indexWhere(
      (position) => position.string == sequence[i].string,
      i + 1,
    );
    final ringLength = nextOnString < 0
        ? 3 * sampleRate
        : (nextOnString - i) * step;
    final pluck = synthPluck(midi: sequence[i].midi, duration: 3);
    final length = min(
      min(ringLength, pluck.length),
      samples.length - i * step,
    );
    for (var j = 0; j < length; j++) {
      samples[i * step + j] += pluck[j];
    }
  }
  return samples;
}

Float64List muted(List<ScalePosition> sequence, double gap) => concat([
  for (final position in sequence)
    synthPluck(midi: position.midi, duration: gap),
]);

ScaleDefinition legacyScale(String name, int root) => ScaleDefinition(
  patterns.firstWhere(
    (pattern) => pattern.name == name && pattern.kind == PatternKind.scale,
  ),
  root,
  defaultFretWindow(root),
);

ScaleDefinition arpeggio(String name, int root) => ScaleDefinition(
  patterns.firstWhere(
    (pattern) => pattern.name == name && pattern.kind == PatternKind.arpeggio,
  ),
  root,
  defaultFretWindow(root),
);

void main() {
  test('L1 chunk size does not change the events', () {
    final pluck = synthPluck(midi: 57);
    final whole = runListener(pluck).events;

    expect(whole.map((event) => event.midi), [57]);
    expect(whole.single.time, 2560 / sampleRate);

    for (final chunkSize in [100, 512, 777, 1000, 5000]) {
      final chunked = runListener(pluck, chunkSize: chunkSize).events;
      expect(chunked, hasLength(1), reason: 'chunk $chunkSize');
      expect(chunked.single.midi, whole.single.midi);
      expect(chunked.single.cents, whole.single.cents);
      expect(chunked.single.time, whole.single.time);
    }
  });

  test('L2 one pluck gives one event with and without lead-in silence', () {
    final pluck = synthPluck(midi: 57);

    expect(midis(pluck), [57]);
    expect(midis(concat([silence(0.3), pluck])), [57]);
  });

  test('L3 the level gate passes -44 dBFS and blocks -46 dBFS', () {
    final above = runListener(sine(440, amplitude: sinePeakForRmsDb(-44)));
    final below = runListener(sine(440, amplitude: sinePeakForRmsDb(-46)));

    expect(above.events.map((event) => event.midi), [69]);
    expect(above.readings.first.levelDb, closeTo(-44, 0.2));

    expect(below.events, isEmpty);
    expect(below.readings, isNotEmpty);
    for (final reading in below.readings) {
      expect(reading.levelDb, closeTo(-46, 0.2));
      expect(reading.midi, isNull);
      expect(reading.cents, isNull);
    }

    expect(runListener(silence(1)).events, isEmpty);
    expect(runListener(whiteNoise()).events, isEmpty);
  });

  test(
    'L4 two-hop bursts at sample 0 and later half-hop bursts give no events',
    () {
      for (final midi in [45, 64, 88]) {
        final burst = synthPluck(midi: midi).sublist(0, 2 * hopSize);

        expect(
          midis(concat([burst, silence(1)])),
          isEmpty,
          reason: 'midi $midi',
        );
        for (var i = 0; i < 16; i++) {
          final short = synthPluck(midi: midi).sublist(0, hopSize ~/ 2);
          final lead = Float64List(26 * hopSize + i * hopSize ~/ 16);

          expect(
            midis(concat([lead, short, silence(0.5)])),
            isEmpty,
            reason: 'midi $midi, alignment $i',
          );
        }
      }
    },
  );

  test('L5 the same note re-arms only on an attack', () {
    final afterSilence = concat([
      synthPluck(midi: 57),
      silence(0.5),
      synthPluck(midi: 57),
    ]);
    final rePluck = concat([
      held(57, amplitude: 0.2),
      held(57, amplitude: 1.0, duration: 1),
    ]);
    final swell = concat([
      held(57, amplitude: 0.2, duration: 20 * hopSize / sampleRate),
      held(57, amplitude: 0.3, duration: 1),
    ]);

    expect(midis(afterSilence), [57, 57]);
    expect(midis(rePluck), [57, 57]);
    expect(midis(swell), [57]);
  });

  test('L6 legato to a new note gives both notes', () {
    expect(midis(concat([held(45), held(47)])), [45, 47]);
  });

  test('L7 harmonic jumps at equal level give no new event', () {
    for (final target in [76, 83, 88, 52, 45, 40]) {
      expect(midis(concat([held(64), held(target)])), [
        64,
      ], reason: 'switch to $target');
    }
  });

  test('L7b a fresh pluck an octave up at 4.9x the decayed level counts', () {
    final freshPluck = concat([
      synthPluck(midi: 64, amplitude: 0.25, duration: 0.5),
      synthPluck(midi: 76, amplitude: 0.5, duration: 0.5),
    ]);
    final result = runListener(freshPluck);

    expect(peakFrameRatio(result.readings), closeTo(4.87, 0.01));
    expect(result.events.map((event) => event.midi), [64, 76]);
  });

  test('L8 hard-profile plucks give exactly one correct event', () {
    for (final midi in [40, 45, 52, 57, 64, 72, 76]) {
      for (var seed = 1; seed <= 3; seed++) {
        final pluck = synthPluck(
          midi: midi,
          harmonics: hardProfile,
          noise: 0.02,
          seed: seed,
        );

        expect(midis(pluck), [midi], reason: 'midi $midi, seed $seed');
      }
    }
  });

  test('L9 a noisy 4 s ring gives exactly one event', () {
    const notes = [40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 52, 57];
    final wrong = <String, List<int>>{};

    for (final midi in notes) {
      for (var seed = 1; seed <= 3; seed++) {
        final heard = midis(
          synthPluck(midi: midi, noise: 0.02, seed: seed, duration: 4),
        );
        if (heard.length != 1 || heard.single != midi) {
          wrong['midi $midi, seed $seed'] = heard;
        }
      }
    }

    expect(wrong, isEmpty);
  });

  group('L10 attack rule on sustained notes', () {
    const notes = [45, 57, 64];
    const stepSample = 30 * hopSize;
    const steps = [stepSample, stepSample + hopSize, 2 * stepSample];
    final alignments = [for (var i = 0; i <= 16; i++) i * hopSize ~/ 16];

    test('a hop-aligned step just above 2x fires', () {
      for (final midi in notes) {
        final result = runListener(levelStep(midi, 2.1, stepSample));

        expect(peakFrameRatio(result.readings), closeTo(2.1, 0.07));
        expect(result.events.map((event) => event.midi), [
          midi,
          midi,
        ], reason: 'midi $midi');
      }
    });

    test('a hop-aligned step just below 2x does not fire', () {
      for (final midi in notes) {
        final result = runListener(levelStep(midi, 1.9, stepSample));

        expect(peakFrameRatio(result.readings), closeTo(1.9, 0.06));
        expect(result.events.map((event) => event.midi), [
          midi,
        ], reason: 'midi $midi');
      }
    });

    test('a 2.5x step fires at every alignment', () {
      for (final midi in notes) {
        for (final alignment in alignments) {
          for (final step in steps) {
            final samples = levelStep(midi, 2.5, step + alignment);

            expect(midis(samples), [
              midi,
              midi,
            ], reason: 'midi $midi, step $step, alignment $alignment');
          }
        }
      }
    });

    test('a 1.8x step never fires at any alignment', () {
      for (final midi in notes) {
        for (final alignment in alignments) {
          for (final step in steps) {
            final samples = levelStep(midi, 1.8, step + alignment);

            expect(midis(samples), [
              midi,
            ], reason: 'midi $midi, step $step, alignment $alignment');
          }
        }
      }
    });

    test('a ramp reaching 2x only over the full lag fires', () {
      for (final midi in notes) {
        final result = runListener(levelRamp(midi, 1.21, stepSample, 10));

        expect(peakFrameRatio(result.readings), greaterThan(2));
        expect(
          peakFrameRatio(result.readings, lag: attackLagFrames - 1),
          lessThan(2),
        );
        expect(result.events.map((event) => event.midi), [
          midi,
          midi,
        ], reason: 'midi $midi');
      }
    });

    test('a rise that stays below the gate is not an attack', () {
      final lag = (windowSize + attackLagFrames * hopSize) / sampleRate;

      expect(
        midis(
          concat([
            sine(220, duration: 0.5),
            sine(220, amplitude: sinePeakForRmsDb(-60), duration: lag),
            sine(220, amplitude: sinePeakForRmsDb(-46), duration: lag),
            sine(220, amplitude: sinePeakForRmsDb(-44), duration: 0.5),
          ]),
        ),
        [57],
      );
    });
  });

  test('L11 event cents are the mean over the confirming frames', () {
    for (final detune in [20, -20]) {
      final result = runListener(
        glide(
          midiToFrequency(69 + (detune - 12) / 100),
          midiToFrequency(69 + (detune + 18) / 100),
          length: windowSize + 2 * hopSize,
        ),
      );
      final frameCents = [
        for (final reading in result.readings) reading.cents!,
      ];
      final mean = frameCents.reduce((a, b) => a + b) / frameCents.length;
      final event = result.events.single;

      expect(frameCents, hasLength(3));
      expect(event.midi, 69);
      expect(event.cents, closeTo(mean, 1e-9), reason: 'detune $detune');
      expect(event.cents, closeTo(detune, 2.5), reason: 'detune $detune');
      expect(
        (event.cents - frameCents.last).abs(),
        greaterThan(5),
        reason: 'detune $detune',
      );
    }
  });

  group('L12 reset', () {
    late List<NoteEvent> events;
    late NoteListener listener;

    setUp(() {
      events = [];
      listener = NoteListener(onNote: events.add, onReading: (_) {});
    });

    test('restarts framing, re-arms and keeps the sample counter', () {
      final first = held(57);

      listener.addSamples(first);
      listener.reset();
      listener.addSamples(held(57));

      expect(events.map((event) => event.midi), [57, 57]);
      expect(
        events.last.time,
        (first.length + windowSize + 2 * hopSize) / sampleRate,
      );
    });

    test('forgets the held note when no attack follows', () {
      final belowGate = sine(
        220,
        amplitude: sinePeakForRmsDb(-46),
        duration: (windowSize + attackLagFrames * hopSize) / sampleRate,
      );
      final aboveGate = sine(220, amplitude: sinePeakForRmsDb(-44));

      listener.addSamples(sine(220));
      listener.reset();
      listener.addSamples(concat([belowGate, aboveGate]));

      expect(events.map((event) => event.midi), [57, 57]);
    });

    test('drops a half-confirmed note', () {
      final tone = sine(440);

      listener.addSamples(tone.sublist(0, windowSize + hopSize));
      listener.reset();
      listener.addSamples(tone.sublist(0, windowSize));

      expect(events, isEmpty);
    });
  });

  test('L13 a pluck is reported within the latency budget', () {
    for (final midi in [40, 45, 57, 64, 76]) {
      for (final harmonics in [guitarProfile, hardProfile]) {
        final pluck = synthPluck(midi: midi, harmonics: harmonics);

        expect(
          runListener(pluck).events.single.time * sampleRate,
          closeTo(2560, 1e-6),
          reason: 'midi $midi',
        );

        for (var i = 0; i < 16; i++) {
          final onset = 13312 + i * hopSize ~/ 16;
          final events = runListener(concat([Float64List(onset), pluck]))
              .events;

          expect(events.map((event) => event.midi), [
            midi,
          ], reason: 'midi $midi, lead-in $i');
          expect(
            events.single.time * sampleRate - onset,
            lessThanOrEqualTo(windowSize + 3 * hopSize),
            reason: 'midi $midi, lead-in $i',
          );
        }
      }
    }
  });

  test('L14 fast changes in an up-and-down run give exactly the sequence', () {
    const pentatonic = [45, 48, 50, 52, 55, 57, 60, 62, 64, 67, 69, 72];
    const cMajor = [
      40,
      41,
      43,
      45,
      47,
      48,
      50,
      52,
      53,
      55,
      57,
      59,
      60,
      62,
      64,
      65,
      67,
    ];

    for (final run in [pentatonic, cMajor]) {
      final sequence = [...run, ...run.reversed.skip(1)];

      for (final duration in [0.09, 0.10, 0.12, 0.16]) {
        final samples = concat([
          for (final midi in sequence)
            synthPluck(midi: midi, duration: duration),
        ]);

        expect(midis(samples), sequence, reason: 'duration $duration');
      }
    }
  });

  test('L15 overlap from ringing strings keeps the legacy sequences', () {
    final scales = [
      legacyScale('Minor pentatonic', 9),
      legacyScale('Minor pentatonic', 4),
      legacyScale('Minor blues', 9),
      legacyScale('Major', 0),
      legacyScale('Major', 7),
      legacyScale('Natural minor', 9),
    ];

    for (final scale in scales) {
      final sequence = generateSequence(
        scale.positions,
        const PracticeOptions(),
      );

      expect(
        midis(ringing(sequence, 0.5)),
        sequence.map((position) => position.midi),
        reason: scale.name,
      );
    }
  });

  test('L15b muted arpeggios give exactly the sequence in every order', () {
    final arpeggios = [
      arpeggio('Major', 0),
      arpeggio('Min7', 9),
      arpeggio('Dom7', 7),
    ];
    const orders = {
      'straight': NoteOrder.straight,
      'thirds': NoteOrder.thirds,
      'groups of 3': NoteOrder.groupsOf3,
      'groups of 4': NoteOrder.groupsOf4,
    };
    final wrong = <String, List<int>>{};

    void check(String label, List<ScalePosition> sequence) {
      final expected = sequence.map((position) => position.midi).toList();
      final heard = midis(muted(sequence, 0.5));
      if (heard.join(' ') != expected.join(' ')) {
        wrong['$label: expected ${expected.join(' ')}'] = heard;
      }
    }

    for (final scale in arpeggios) {
      orders.forEach((label, order) {
        check(
          '${scale.name} $label',
          generateSequence(scale.positions, PracticeOptions(order: order)),
        );
      });
      for (var seed = 1; seed <= 5; seed++) {
        check(
          '${scale.name} random seed $seed',
          generateSequence(
            scale.positions,
            const PracticeOptions(order: NoteOrder.random),
            random: Random(seed),
          ),
        );
      }
    }

    expect(wrong, isEmpty);
  });

  group('L16 only the expected note passes the phantom filter', () {
    List<int> heard(Float64List samples, int expectedMidi) => runListener(
      samples,
      expectedMidi: expectedMidi,
    ).events.map((event) => event.midi).toList();

    for (final target in [76, 83, 88, 52, 45, 40]) {
      test('switch to $target', () {
        final samples = concat([held(64), held(target)]);

        expect(heard(samples, target), [64, target]);
        expect(heard(samples, 65), [64]);
      });
    }
  });
}
