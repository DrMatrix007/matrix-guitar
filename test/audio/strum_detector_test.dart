import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/audio/debug_tone_source.dart';
import 'package:matrix_guitar/audio/pitch_detector.dart';
import 'package:matrix_guitar/audio/strum_detector.dart';
import 'package:matrix_guitar/theory/chord.dart';

import '../helpers/signals.dart';

const stringOffset = 0.015;
const strumDuration = 0.8;
const countedChords = ['C', 'E', 'F#', 'G5', 'B7'];
const quietChords = ['C', 'E', 'F#', 'Am7', 'B7', 'G5'];

ChordVoicing chordNamed(String name) =>
    chordLibrary.firstWhere((chord) => chord.name == name);

Float64List strumOf(ChordVoicing chord) => synthStrum(chord.playedNotes);

Float64List offsetStrum(
  List<int> notes,
  Float64List Function(int index, int midi) pluck,
) => mix([
  for (final (index, midi) in notes.indexed)
    concat([silence(index * stringOffset), pluck(index, midi)]),
]);

Float64List detunedStrum(List<int> notes, double cents) => offsetStrum(
  notes,
  (_, midi) => detunedPluck(
    midi,
    cents,
    amplitude: 1 / notes.length,
    duration: strumDuration,
  ),
);

Float64List profileStrum(List<int> notes, List<double> harmonics) =>
    offsetStrum(
      notes,
      (_, midi) => synthPluck(
        midi: midi,
        harmonics: harmonics,
        amplitude: 1 / notes.length,
        duration: strumDuration,
      ),
    );

Float64List quietStringStrum(List<int> notes, int quietIndex) => offsetStrum(
  notes,
  (index, midi) => synthPluck(
    midi: midi,
    amplitude: (index == quietIndex ? pow(10, -12 / 20) : 1) / notes.length,
    duration: strumDuration,
  ),
);

String describe(List<StrumEvent> events) => events.isEmpty
    ? 'no events'
    : events
          .map(
            (event) =>
                'missing ${event.missing} extra ${event.extra} '
                'at ${event.time}',
          )
          .join('; ');

bool oneCorrect(List<StrumEvent> events) =>
    events.length == 1 && events.single.correct;

bool oneWrong(List<StrumEvent> events) =>
    events.length == 1 && !events.single.correct;

void expectEachOneCorrect(
  Iterable<ChordVoicing> chords,
  Float64List Function(ChordVoicing chord) signal,
) {
  final wrong = <String, String>{};

  for (final chord in chords) {
    final events = runStrums(signal(chord), chord.playedNotes);
    if (!oneCorrect(events)) wrong[chord.name] = describe(events);
  }

  expect(wrong, isEmpty);
}

void main() {
  test('ST1 every chord strummed on its own detector is one correct event', () {
    expectEachOneCorrect(chordLibrary, strumOf);
  });

  test('ST2 a single played note is one wrong event on its chord', () {
    final wrong = <String, String>{};

    for (final chord in chordLibrary) {
      for (final midi in chord.playedNotes) {
        final events = runStrums(
          synthPluck(midi: midi, duration: strumDuration),
          chord.playedNotes,
        );
        if (!oneWrong(events)) {
          wrong['${chord.name} note $midi'] = describe(events);
        }
      }
    }

    expect(wrong, isEmpty);
  });

  test('ST3 every other chord played on a target is one wrong event', () {
    final signals = {
      for (final chord in chordLibrary) chord.name: strumOf(chord),
    };
    final wrong = <String, String>{};
    var pairs = 0;

    for (final target in chordLibrary) {
      for (final played in chordLibrary) {
        if (played.name == target.name) continue;
        pairs++;
        final events = runStrums(signals[played.name]!, target.playedNotes);
        if (!oneWrong(events)) {
          wrong['target ${target.name}, played ${played.name}'] = describe(
            events,
          );
        }
      }
    }

    expect(pairs, 812);
    expect(wrong, isEmpty);
  });

  group('ST4 exact missing and extra sets', () {
    const rows = [
      ('E', 'Em', {8}, {7}),
      ('E', 'E5', {8}, <int>{}),
      ('E5', 'E', <int>{}, {8}),
    ];

    for (final (target, played, missing, extra) in rows) {
      test('target $target, played $played', () {
        final events = runStrums(
          strumOf(chordNamed(played)),
          chordNamed(target).playedNotes,
        );

        expect(events, hasLength(1));
        expect(events.single.missing, missing);
        expect(events.single.extra, extra);
      });
    }
  });

  group('ST5 counting', () {
    final chords = countedChords.map(chordNamed);

    test('a 3 s ring is one event', () {
      for (final chord in chords) {
        final events = runStrums(
          synthStrum(chord.playedNotes, duration: 3),
          chord.playedNotes,
        );

        expect(events, hasLength(1), reason: chord.name);
      }
    });

    test('10 overlapping strums 0.5 s apart are 10 correct events', () {
      final wrong = <String, String>{};

      for (final chord in chords) {
        final events = runStrums(
          overlapStrums(chord.playedNotes, gap: 0.5, count: 10),
          chord.playedNotes,
        );
        if (events.length != 10 || !events.every((event) => event.correct)) {
          wrong[chord.name] = describe(events);
        }
      }

      expect(wrong, isEmpty);
    });

    test('two strums 0.15 s apart are one event', () {
      for (final chord in chords) {
        final events = runStrums(
          overlapStrums(chord.playedNotes, gap: 0.15, count: 2),
          chord.playedNotes,
        );

        expect(events, hasLength(1), reason: chord.name);
      }
    });

    test('D at a slow 35 ms stagger is one correct event', () {
      expectEachOneCorrect([
        chordNamed('D'),
      ], (chord) => synthStrum(chord.playedNotes, stagger: 0.035));
    });

    test('a 200 ms strum is one correct event', () {
      expectEachOneCorrect(
        chords,
        (chord) => synthStrum(
          chord.playedNotes,
          stagger: 0.2 / (chord.playedNotes.length - 1),
        ),
      );
    });
  });

  group('ST6 no event', () {
    final notes = chordNamed('C').playedNotes;
    final knock = whiteNoise(amplitude: 0.5, duration: 220 / sampleRate);

    test('from silence', () {
      expect(runStrums(silence(2), notes), isEmpty);
    });

    test('from quiet noise', () {
      expect(
        runStrums(whiteNoise(amplitude: 0.0017, duration: 2), notes),
        isEmpty,
      );
    });

    test('from a knock', () {
      expect(knock, hasLength(220));
      expect(runStrums(concat([knock, silence(1)]), notes), isEmpty);
      expect(
        runStrums(concat([silence(0.5), knock, silence(1)]), notes),
        isEmpty,
      );
    });
  });

  test('ST7 chunk size does not change verdicts or times', () {
    final target = chordNamed('E');
    final cases = {
      'correct': strumOf(target),
      'wrong': strumOf(chordNamed('Em')),
    };

    cases.forEach((label, samples) {
      final whole = runStrums(samples, target.playedNotes);

      expect(whole, hasLength(1), reason: label);
      expect(whole.single.correct, label == 'correct', reason: label);

      for (final chunkSize in [1, 333, 512, 4096]) {
        final chunked = runStrums(
          samples,
          target.playedNotes,
          chunkSize: chunkSize,
        );
        final reason = '$label, chunk $chunkSize';

        expect(chunked, hasLength(1), reason: reason);
        expect(chunked.single.missing, whole.single.missing, reason: reason);
        expect(chunked.single.extra, whole.single.extra, reason: reason);
        expect(chunked.single.time, whole.single.time, reason: reason);
      }
    });
  });

  group('ST8 reset', () {
    final notes = chordNamed('C').playedNotes;
    final strum = synthStrum(notes);
    final partial = strum.sublist(0, (0.1 * sampleRate).round());
    late List<StrumEvent> events;
    late StrumDetector detector;

    setUp(() {
      events = [];
      detector = StrumDetector(notes: notes, onStrum: events.add);
    });

    test('discards a strum whose verdict is pending', () {
      final fresh = runStrums(strum, notes).single;

      detector.addSamples(partial);
      detector.reset();
      detector.addSamples(strum);

      expect(events, hasLength(1));
      expect(
        events.single.time * sampleRate,
        closeTo(partial.length + fresh.time * sampleRate, 1e-6),
      );
    });

    test('keeps the clock running from the first sample ever fed', () {
      final afterReset = concat([silence(1), strum]);
      final unbroken = runStrums(afterReset, notes).single;

      detector.addSamples(partial);
      detector.reset();
      detector.addSamples(afterReset);

      expect(events, hasLength(1));
      expect(events.single.correct, isTrue);
      expect(
        events.single.time * sampleRate,
        closeTo(partial.length + unbroken.time * sampleRate, 1e-6),
      );
    });
  });

  group('ST9 tolerance', () {
    test('one string 12 dB down, each string in turn', () {
      final wrong = <String, String>{};

      for (final chord in quietChords.map(chordNamed)) {
        final notes = chord.playedNotes;
        for (var index = 0; index < notes.length; index++) {
          final events = runStrums(quietStringStrum(notes, index), notes);
          if (!oneCorrect(events)) {
            wrong['${chord.name} string $index (${notes[index]})'] = describe(
              events,
            );
          }
        }
      }

      expect(wrong, isEmpty);
    });

    test('white noise at -50 dBFS', () {
      final noise = whiteNoise(amplitude: 0.00548, duration: strumDuration);

      expectEachOneCorrect(
        chordLibrary,
        (chord) => mix([strumOf(chord), noise]),
      );
    });

    test('all strings 20 cents sharp', () {
      expectEachOneCorrect(
        chordLibrary,
        (chord) => detunedStrum(chord.playedNotes, 20),
      );
    });

    test('all strings 30 cents flat', () {
      expectEachOneCorrect(
        chordLibrary,
        (chord) => detunedStrum(chord.playedNotes, -30),
      );
    });

    test('pure profile', () {
      expectEachOneCorrect(
        chordLibrary,
        (chord) => profileStrum(chord.playedNotes, pureProfile),
      );
    });

    test('weak profile', () {
      expectEachOneCorrect(
        chordLibrary,
        (chord) => profileStrum(chord.playedNotes, weakProfile),
      );
    });
  });

  test('ST10 a constant level after silence is judged without throwing', () {
    const notes = [40, 47, 52];

    for (final level in [0.01, 0.1, 0.25, 0.5, 1.0]) {
      final constant = Float64List(sampleRate)..fillRange(0, sampleRate, level);

      final events = runStrums(concat([silence(0.2), constant]), notes);

      expect(events, isNotEmpty, reason: 'level $level');
      expect(
        events.where((event) => event.correct),
        isEmpty,
        reason: 'level $level: ${describe(events)}',
      );
    }
  });
}
