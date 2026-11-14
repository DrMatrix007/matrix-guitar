import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/audio/audio_source.dart';
import 'package:matrix_guitar/audio/debug_tone_source.dart';
import 'package:matrix_guitar/main.dart';
import 'package:matrix_guitar/practice/practice_controller.dart';
import 'package:matrix_guitar/practice/practice_options.dart';
import 'package:matrix_guitar/practice/practice_session.dart';
import 'package:matrix_guitar/theory/chord.dart';
import 'package:matrix_guitar/theory/note.dart';
import 'package:matrix_guitar/theory/scale.dart';
import 'package:matrix_guitar/ui/chord_diagram.dart';
import 'package:matrix_guitar/ui/chord_practice_screen.dart';
import 'package:matrix_guitar/ui/fretboard.dart';

import '../helpers/fake_audio_source.dart';
import '../helpers/signals.dart';

const firstNote = 'A2 - string 6, fret 5';
final pattern = patterns.firstWhere((p) => p.name == 'Minor pentatonic');
final scale = ScaleDefinition(pattern, 9, defaultFretWindow(9));
final scaleMidis = [
  for (final position in generateSequence(
    scale.positions,
    const PracticeOptions(),
  ))
    position.midi,
];

Float64List plucks(Iterable<int> midis) =>
    concat([for (final midi in midis) synthPluck(midi: midi, duration: 0.7)]);

Future<void> finishTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> tapLabel(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await finishTransition(tester);
}

Future<void> scrollListTo(WidgetTester tester, String label) =>
    tester.scrollUntilVisible(
      find.text(label),
      200,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );

void prepareView(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

Future<void> launchApp(WidgetTester tester, FakeAudioSource fake) async {
  prepareView(tester);

  await tester.pumpWidget(
    MatrixGuitarApp(
      audioSourceFactory: (_) => fake,
      chordAudioSourceFactory: (_) => fake,
    ),
  );
}

Future<void> openPattern(WidgetTester tester, String name) async {
  await scrollListTo(tester, name);
  await tapLabel(tester, name);
}

Future<void> openDetail(WidgetTester tester, FakeAudioSource fake) async {
  await launchApp(tester, fake);
  await openPattern(tester, pattern.name);
}

Future<void> openSetup(WidgetTester tester, FakeAudioSource fake) async {
  await openDetail(tester, fake);
  await tapLabel(tester, 'Practice');
}

Future<void> openPractice(
  WidgetTester tester,
  FakeAudioSource fake, {
  List<String> options = const [],
}) async {
  await openSetup(tester, fake);
  for (final option in options) {
    await tapLabel(tester, option);
  }
  await tapLabel(tester, 'Start');
}

ChordVoicing chordNamed(String name) =>
    chordLibrary.firstWhere((chord) => chord.name == name);

void expectRep(WidgetTester tester, int rep) {
  final shown = tester.widgetList<Text>(
    find.textContaining(RegExp(r'^\w+ \d+ of 10$')),
  );
  expect(
    find.textContaining(RegExp('^\\w+ $rep of 10\$')),
    findsOneWidget,
    reason: 'counter shows ${shown.map((text) => text.data).toList()}',
  );
}

Future<void> openChordPractice(
  WidgetTester tester,
  FakeAudioSource fake,
  ChordVoicing chord,
) async {
  prepareView(tester);

  await tester.pumpWidget(
    MaterialApp(
      home: ChordPracticeScreen(
        chord: chord,
        chordAudioSourceFactory: (_) => fake,
      ),
    ),
  );
  await tester.pump();
}

Future<void> openChord(WidgetTester tester, String name) async {
  await tapLabel(tester, 'Chords');
  await openPattern(tester, name);
}

Future<void> openChordRun(
  WidgetTester tester,
  FakeAudioSource fake,
  String name,
) async {
  await launchApp(tester, fake);
  await openChord(tester, name);
  await tapLabel(tester, 'Practice');
}

Float64List strums(ChordVoicing chord, int count) => concat([
  for (var i = 0; i < count; i++) synthStrum(chord.playedNotes),
]);

ChoiceChip chip(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));

Fretboard fretboard(WidgetTester tester) =>
    tester.widget<Fretboard>(find.byType(Fretboard));

String nextNoteText(ScalePosition position) =>
    '${scale.spelledNote(position.midi)} - '
    'string ${position.string}, fret ${position.fret}';

void hideApp(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
}

void showApp(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

void main() {
  testWidgets('W1 a full run with one wrong note reaches the summary', (
    tester,
  ) async {
    final fake = FakeAudioSource();
    await openPractice(tester, fake);

    expect(find.text('Note 1 of 23'), findsOneWidget);
    expect(find.text(firstNote), findsOneWidget);

    fake.feed(plucks([45]));
    await tester.pump();

    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('C3 - string 6, fret 8'), findsOneWidget);

    fake.feed(plucks([48, 51]));
    await tester.pump();

    expect(find.text('Wrong: played D#3'), findsOneWidget);
    expect(find.text('D#3'), findsOneWidget);
    expect(find.text('in tune'), findsWidgets);
    expect(find.text('Note 3 of 23'), findsOneWidget);
    expect(find.text('D3 - string 5, fret 5'), findsOneWidget);

    fake.feed(plucks(scaleMidis.skip(2)));

    expect(fake.stopCalls, 1);

    await finishTransition(tester);

    expect(find.text(scale.name), findsOneWidget);
    expect(find.text('23 of 24 (96%)'), findsOneWidget);
    expect(find.text('0:16'), findsOneWidget);
    expect(find.text('D3 - 1 wrong'), findsOneWidget);
    expect(fake.stopCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('W2 denied shows the message and never starts the mic', (
    tester,
  ) async {
    final fake = FakeAudioSource(permissionResults: [MicPermission.denied]);
    await openPractice(tester, fake);

    expect(
      find.text('Microphone access is needed to hear your playing.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(fake.startCalls, 0);
  });

  testWidgets('W3 permanently denied recovers after a settings round trip', (
    tester,
  ) async {
    final fake = FakeAudioSource(
      permissionResults: [MicPermission.permanentlyDenied],
    );
    await openPractice(tester, fake);

    expect(find.text('Open settings'), findsOneWidget);
    expect(fake.startCalls, 0);

    await tester.tap(find.text('Open settings'));
    await tester.pump();

    expect(fake.openSettingsCalls, 1);

    fake.permissionResults.add(MicPermission.granted);
    hideApp(tester);
    showApp(tester);
    await tester.pump();

    expect(fake.requestPermissionCalls, 2);
    expect(fake.startCalls, 1);
    expect(find.text('Open settings'), findsNothing);
    expect(find.text(firstNote), findsOneWidget);
  });

  testWidgets('W4 hide and show keeps progress and duration skips the pause', (
    tester,
  ) async {
    final fake = FakeAudioSource();
    await openPractice(tester, fake);

    fake.feed(concat([plucks(scaleMidis.take(3)), silence(0.3)]));
    await tester.pump();

    expect(find.text('Note 4 of 23'), findsOneWidget);

    hideApp(tester);
    tester.binding.scheduleForcedFrame();
    await tester.pump(const Duration(seconds: 30));

    expect(find.text('Paused'), findsOneWidget);
    expect(fake.stopCalls, 1);

    showApp(tester);
    await tester.pump();

    expect(fake.startCalls, 2);
    expect(find.text('Note 4 of 23'), findsOneWidget);
    expect(find.text('E3 - string 5, fret 7'), findsOneWidget);

    fake.feed(plucks(scaleMidis.skip(3)));
    await finishTransition(tester);

    expect(find.text('23 of 23 (100%)'), findsOneWidget);
    expect(find.text('0:15'), findsOneWidget);
    expect(find.text('No wrong notes.'), findsOneWidget);
    expect(fake.stopCalls, 2);
  });

  testWidgets('W5 hide and show during a pending request starts once', (
    tester,
  ) async {
    final permission = Completer<MicPermission>();
    final fake = FakeAudioSource(permissionResults: [permission.future]);
    await openPractice(tester, fake);

    hideApp(tester);
    showApp(tester);
    await tester.pump();

    expect(fake.requestPermissionCalls, 1);
    expect(fake.startCalls, 0);

    permission.complete(MicPermission.granted);
    await tester.pump();

    expect(fake.startCalls, 1);
    expect(find.text(firstNote), findsOneWidget);
  });

  testWidgets('W6 a start failure shows the error and leaving calls stop', (
    tester,
  ) async {
    final fake = FakeAudioSource(
      permissionResults: [MicPermission.granted, MicPermission.granted],
      startError: Exception('mic busy'),
    );
    await openPractice(tester, fake);

    expect(find.text('The microphone could not be started.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(fake.stopCalls, 0);

    fake.startError = null;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    fake.feed(plucks([45]));
    await tester.pump();

    expect(find.text('Note 2 of 23'), findsOneWidget);

    await tester.pageBack();
    await finishTransition(tester);

    expect(find.text('Start'), findsOneWidget);
    expect(fake.stopCalls, 1);
  });

  testWidgets('W7 detuned audio shows sharp and flat labels', (tester) async {
    final fake = FakeAudioSource();
    await openPractice(tester, fake);

    fake.feed(sine(midiToFrequency(45.2), duration: 0.5));
    await tester.pump();

    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('+20 cents sharp'), findsNWidgets(2));

    fake.feed(
      concat([silence(0.1), sine(midiToFrequency(47.8), duration: 0.5)]),
    );
    await tester.pump();

    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Note 3 of 23'), findsOneWidget);
    expect(find.text('-20 cents flat'), findsNWidgets(2));
  });

  testWidgets('W8 the fretboard highlights the expected position', (
    tester,
  ) async {
    final fake = FakeAudioSource();
    await openPractice(tester, fake);

    ScalePosition highlight() =>
        tester.widget<Fretboard>(find.byType(Fretboard)).highlight!;

    expect(fretboard(tester).showNames, isTrue);
    expect(highlight().midi, 45);
    expect(highlight().string, 6);
    expect(highlight().fret, 5);

    fake.feed(plucks([45]));
    await tester.pump();

    expect(highlight().midi, 48);
    expect(highlight().string, 6);
    expect(highlight().fret, 8);
  });

  testWidgets('W9 resuming resets the listener so a replay is heard', (
    tester,
  ) async {
    final fake = FakeAudioSource();
    await openPractice(tester, fake);
    final ringing = synthPluck(midi: 45, duration: 0.5, decay: 0);

    fake.feed(ringing);
    await tester.pump();

    expect(find.text('Correct'), findsOneWidget);

    hideApp(tester);
    showApp(tester);
    await tester.pump();
    fake.feed(ringing);
    await tester.pump();

    expect(fake.startCalls, 2);
    expect(find.text('Wrong: played A2'), findsOneWidget);
  });

  testWidgets('W10 a start finishing after leaving turns the mic off', (
    tester,
  ) async {
    final gate = Completer<void>();
    final fake = FakeAudioSource(startGate: gate.future);
    await openPractice(tester, fake);

    expect(fake.startCalls, 1);

    await tester.pageBack();
    await finishTransition(tester);

    expect(find.text('Start'), findsOneWidget);
    expect(fake.stopCalls, 0);

    gate.complete();
    await tester.pump();

    expect(fake.stopCalls, 1);
  });

  testWidgets('W11 a stream error stops the mic and shows the error', (
    tester,
  ) async {
    final fake = FakeAudioSource();
    await openPractice(tester, fake);

    fake.failStream(Exception('mic lost'));
    await tester.pump();

    expect(fake.stopCalls, 1);
    expect(find.text('The microphone could not be started.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('W12 hide and show after completion leaves the mic off', (
    tester,
  ) async {
    final fake = FakeAudioSource();
    await openPractice(tester, fake);

    fake.feed(plucks(scaleMidis));

    expect(fake.stopCalls, 1);

    hideApp(tester);
    showApp(tester);
    await finishTransition(tester);

    expect(fake.startCalls, 1);
    expect(fake.stopCalls, 1);
    expect(find.text('23 of 23 (100%)'), findsOneWidget);
  });

  testWidgets('W13 tabs group patterns and arpeggios have their own titles', (
    tester,
  ) async {
    await launchApp(tester, FakeAudioSource());

    expect(find.text('Modes'), findsOneWidget);
    expect(find.text('Dorian'), findsOneWidget);

    await openPattern(tester, 'Major');

    expect(find.text('A major'), findsOneWidget);

    await tester.pageBack();
    await finishTransition(tester);
    await scrollListTo(tester, 'Pentatonic');

    expect(find.text('Pentatonic'), findsOneWidget);

    await tapLabel(tester, 'Arpeggios');

    expect(find.text('Triads'), findsOneWidget);
    expect(find.text('Maj7'), findsOneWidget);
    expect(find.text('Dorian'), findsNothing);

    await openPattern(tester, 'Major');

    expect(find.text('A major arpeggio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('W14 root and window chips drive the fretboard', (tester) async {
    await openDetail(tester, FakeAudioSource());

    expect(tester.takeException(), isNull);
    expect(find.text('A minor pentatonic'), findsOneWidget);
    expect(chip(tester, 'A').selected, isTrue);
    expect(find.text('Frets 0-4'), findsOneWidget);
    expect(find.text('Frets 11-15'), findsOneWidget);
    expect(chip(tester, 'Frets 4-8').selected, isTrue);
    expect(fretboard(tester).scale.minFret, 4);

    await tapLabel(tester, 'Frets 11-15');

    expect(chip(tester, 'Frets 11-15').selected, isTrue);
    expect(chip(tester, 'Frets 4-8').selected, isFalse);
    expect(fretboard(tester).scale.minFret, 11);
    expect(fretboard(tester).scale.maxFret, 15);

    await tapLabel(tester, 'Eb');

    expect(find.text('Eb minor pentatonic'), findsOneWidget);
    expect(find.text('Frets 4-8'), findsNothing);
    expect(find.text('Frets 11-15'), findsNothing);
    expect(find.text('Frets 10-14'), findsOneWidget);
    expect(chip(tester, 'Frets 5-9').selected, isTrue);
    expect(fretboard(tester).scale.root, 3);
    expect(fretboard(tester).scale.minFret, 5);
    expect(fretboard(tester).scale.maxFret, 9);
    expect(tester.takeException(), isNull);
  });

  testWidgets('W15 chosen options reach the practice session', (tester) async {
    final sequence = generateSequence(
      scale.positions,
      const PracticeOptions(
        direction: PracticeDirection.descending,
        order: NoteOrder.thirds,
        repeats: 2,
      ),
    );
    final fake = FakeAudioSource();
    await openPractice(tester, fake, options: ['Descending', 'Thirds', '2']);

    expect(find.text('Note 1 of ${sequence.length}'), findsOneWidget);
    expect(find.text(nextNoteText(sequence.first)), findsOneWidget);

    fake.feed(plucks(sequence.take(3).map((position) => position.midi)));
    await tester.pump();

    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Note 4 of ${sequence.length}'), findsOneWidget);
    expect(find.text(nextNoteText(sequence[3])), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('W16 random disables direction and plays each position once', (
    tester,
  ) async {
    await openSetup(tester, FakeAudioSource());
    const directions = ['Ascending', 'Descending', 'Both'];

    expect(tester.takeException(), isNull);

    await tapLabel(tester, 'Random');

    for (final label in directions) {
      expect(chip(tester, label).onSelected, isNull);
    }

    await tapLabel(tester, 'Straight');

    for (final label in directions) {
      expect(chip(tester, label).onSelected, isNotNull);
    }

    await tapLabel(tester, 'Random');
    await tapLabel(tester, 'Start');

    expect(find.text('Note 1 of ${scale.positions.length}'), findsOneWidget);
  });

  testWidgets('W17 no names hides note names until a wrong note', (
    tester,
  ) async {
    final fake = FakeAudioSource();
    await openPractice(tester, fake, options: ['No names']);

    expect(fretboard(tester).showNames, isFalse);
    expect(find.text('string 6, fret 5'), findsOneWidget);
    expect(find.text(firstNote), findsNothing);

    fake.feed(plucks([51]));
    await tester.pump();

    expect(find.text('Wrong: played D#3'), findsOneWidget);
  });

  testWidgets('W18 from memory hides the fretboard and next note', (
    tester,
  ) async {
    final fake = FakeAudioSource();
    await openPractice(tester, fake, options: ['From memory']);

    expect(find.byType(Fretboard), findsNothing);
    expect(find.textContaining('string '), findsNothing);
    expect(find.text('Note 1 of 23'), findsOneWidget);
    expect(find.text('Listening...'), findsOneWidget);

    fake.feed(plucks([45]));
    await tester.pump();

    expect(find.text('A2'), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);

    fake.feed(plucks([51]));
    await tester.pump();

    expect(find.text('D#3'), findsOneWidget);
    expect(find.text('Wrong: played D#3'), findsOneWidget);
    expect(find.byType(Fretboard), findsNothing);
    expect(find.textContaining('string '), findsNothing);
  });

  testWidgets('W19 random rules out from memory and falls back to no names', (
    tester,
  ) async {
    await openSetup(tester, FakeAudioSource());

    await tapLabel(tester, 'Random');

    expect(chip(tester, 'From memory').onSelected, isNull);
    expect(chip(tester, 'Full').onSelected, isNotNull);
    expect(chip(tester, 'No names').onSelected, isNotNull);

    await tapLabel(tester, 'Straight');
    await tapLabel(tester, 'From memory');
    await tapLabel(tester, 'Random');

    expect(chip(tester, 'No names').selected, isTrue);
    expect(chip(tester, 'From memory').selected, isFalse);

    await tapLabel(tester, 'Straight');

    expect(chip(tester, 'From memory').onSelected, isNotNull);

    await tapLabel(tester, 'Start');

    expect(find.byType(Fretboard), findsOneWidget);
  });

  testWidgets('W20 the detail screen spells the scale, the root chip stays', (
    tester,
  ) async {
    await launchApp(tester, FakeAudioSource());
    await openPattern(tester, 'Natural minor');

    await tapLabel(tester, 'Db');

    expect(find.text('C# natural minor'), findsOneWidget);
    expect(find.text('C# D# E F# G# A B'), findsOneWidget);
    expect(chip(tester, 'Db').selected, isTrue);
  });

  testWidgets('W21 a run with an octave-sized step completes', (tester) async {
    final arpeggio = patterns.firstWhere(
      (p) => p.name == 'Major' && p.kind == PatternKind.arpeggio,
    );
    final sequence = generateSequence(
      ScaleDefinition(arpeggio, 0, (minFret: 7, maxFret: 11)).positions,
      const PracticeOptions(direction: PracticeDirection.ascending, repeats: 2),
    );
    final notes = sequence.map((position) => position.midi).toList();
    final steps = [
      for (var i = 1; i < notes.length; i++) (notes[i] - notes[i - 1]).abs(),
    ];
    final fake = FakeAudioSource();
    final controller = PracticeController(sequence: sequence, source: fake);
    addTearDown(controller.dispose);

    expect(steps, anyOf(contains(12), contains(19), contains(24)));

    controller.start();
    await tester.pump();
    fake.feed(
      concat([
        for (final midi in notes) synthPluck(midi: midi, duration: 0.35),
      ]),
    );

    expect(controller.session.index, sequence.length);
    expect(controller.session.phase, SessionPhase.complete);
    expect(controller.session.summary.wrong, 0);
  });

  testWidgets('W21b an octave step in the middle of a run completes', (
    tester,
  ) async {
    const notes = [60, 64, 76];
    final fake = FakeAudioSource();
    final controller = PracticeController(
      sequence: [
        for (final midi in notes) ScalePosition(string: 1, fret: 0, midi: midi),
      ],
      source: fake,
    );
    addTearDown(controller.dispose);

    controller.start();
    await tester.pump();
    fake.feed(
      concat([
        for (final midi in notes) synthPluck(midi: midi, duration: 0.35),
      ]),
    );

    expect(controller.session.phase, SessionPhase.complete);
  });

  testWidgets('W22 the next-note line and summary use the scale spelling', (
    tester,
  ) async {
    final fake = FakeAudioSource();
    await launchApp(tester, fake);
    await openPattern(tester, 'Minor blues');
    await tapLabel(tester, 'Practice');
    await tapLabel(tester, 'Start');

    fake.feed(plucks([45, 48, 50]));
    await tester.pump();

    expect(find.text('Eb3 - string 5, fret 6'), findsOneWidget);

    fake.feed(plucks([52]));
    await tester.pump();

    expect(find.text('Wrong: played E3'), findsOneWidget);
    expect(find.text('Eb3 - string 5, fret 6'), findsOneWidget);

    fake.feed(plucks([51, 52, 55, 57, 60, 62, 63, 64, 67, 69, 72]));
    fake.feed(plucks([69, 67, 64, 63, 62, 60, 57, 55, 52, 51, 50, 48, 45]));
    await finishTransition(tester);

    expect(find.text('Eb3 - 1 wrong'), findsOneWidget);
  });

  testWidgets('W23 the fretboard paints note names only when asked', (
    tester,
  ) async {
    const expectedParagraphs = {true: 18, false: 6};

    for (final MapEntry(key: showNames, value: paragraphs)
        in expectedParagraphs.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Fretboard(scale: scale, showNames: showNames),
        ),
      );

      expect(
        tester.renderObject(
          find.descendant(
            of: find.byType(Fretboard),
            matching: find.byType(CustomPaint),
          ),
        ),
        paintsExactlyCountTimes(#drawParagraph, paragraphs),
        reason: 'showNames $showNames',
      );
    }
  });

  testWidgets('W24a one strum is one rep', (tester) async {
    final chord = chordNamed('D');
    final fake = FakeAudioSource();
    await openChordPractice(tester, fake, chord);

    expectRep(tester, 1);

    fake.feed(
      concat([
        synthStrum(chord.playedNotes.reversed.toList(), stagger: 0.05),
        silence(0.5),
      ]),
    );
    await tester.pump();

    expectRep(tester, 2);
  });

  testWidgets('W24b a single string does not count', (tester) async {
    final fake = FakeAudioSource();
    await openChordPractice(tester, fake, chordNamed('E'));

    expectRep(tester, 1);

    fake.feed(concat([synthPluck(midi: 40, duration: 0.8), silence(0.5)]));
    await tester.pump();

    expectRep(tester, 1);
  });

  testWidgets('W24c a wrong chord sharing a tone does not count', (
    tester,
  ) async {
    final fake = FakeAudioSource();
    await openChordPractice(tester, fake, chordNamed('E'));

    expectRep(tester, 1);

    fake.feed(
      concat([
        synthStrum(chordNamed('Em').playedNotes, stagger: 0.05),
        silence(0.5),
      ]),
    );
    await tester.pump();

    expectRep(tester, 1);
  });

  testWidgets('W25 a full chord run through the UI reaches the summary', (
    tester,
  ) async {
    final chord = chordNamed('E');
    final fake = FakeAudioSource();
    await launchApp(tester, fake);
    await openChord(tester, 'E');

    expect(find.text('E major'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);

    await tapLabel(tester, 'Practice');

    expect(find.text('Strum 1 of 10'), findsOneWidget);

    fake.feed(synthStrum(chordNamed('Em').playedNotes));
    await tester.pump();

    expect(find.text('Wrong: missing G#, extra G'), findsOneWidget);
    expect(find.text('Strum 1 of 10'), findsOneWidget);

    for (var i = 0; i < 9; i++) {
      fake.feed(synthStrum(chord.playedNotes));
    }
    await tester.pump();

    expect(find.text('Strum 10 of 10'), findsOneWidget);
    expect(fake.stopCalls, 0);

    fake.feed(synthStrum(chord.playedNotes));
    await tester.pump();

    expect(find.text('Paused'), findsNothing);

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Paused'), findsNothing);
    }

    await finishTransition(tester);

    expect(find.text('E major'), findsOneWidget);
    expect(find.text('10 of 11 (91%)'), findsOneWidget);
    expect(find.text('Most troublesome notes'), findsNothing);
    expect(find.text('Paused'), findsNothing);
    expect(fake.stopCalls, 1);

    await tapLabel(tester, 'Done');

    expect(find.text('Done'), findsNothing);
    expect(find.text('E major'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('W26 hide and show keeps the strum count and keeps counting', (
    tester,
  ) async {
    final chord = chordNamed('E');
    final fake = FakeAudioSource();
    await openChordRun(tester, fake, 'E');

    fake.feed(strums(chord, 3));
    await tester.pump();

    expect(find.text('Strum 4 of 10'), findsOneWidget);

    hideApp(tester);
    tester.binding.scheduleForcedFrame();
    await tester.pump();

    expect(find.text('Paused'), findsOneWidget);
    expect(fake.stopCalls, 1);

    showApp(tester);
    await tester.pump();

    expect(fake.startCalls, 2);
    expect(find.text('Paused'), findsNothing);
    expect(find.text('Strum 4 of 10'), findsOneWidget);

    fake.feed(strums(chord, 1));
    await tester.pump();

    expect(find.text('Strum 5 of 10'), findsOneWidget);
  });

  testWidgets('W27a denied shows the message and try again starts the mic', (
    tester,
  ) async {
    final fake = FakeAudioSource(
      permissionResults: [MicPermission.denied, MicPermission.granted],
    );
    await openChordRun(tester, fake, 'E');

    expect(
      find.text('Microphone access is needed to hear your playing.'),
      findsOneWidget,
    );
    expect(fake.startCalls, 0);

    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(fake.requestPermissionCalls, 2);
    expect(fake.startCalls, 1);
    expect(find.text('Try again'), findsNothing);
    expect(find.text('Strum 1 of 10'), findsOneWidget);
  });

  testWidgets('W27b permanently denied recovers after a settings round trip', (
    tester,
  ) async {
    final fake = FakeAudioSource(
      permissionResults: [MicPermission.permanentlyDenied],
    );
    await openChordRun(tester, fake, 'E');

    expect(find.text('Open settings'), findsOneWidget);
    expect(fake.startCalls, 0);

    await tester.tap(find.text('Open settings'));
    await tester.pump();

    expect(fake.openSettingsCalls, 1);

    fake.permissionResults.add(MicPermission.granted);
    hideApp(tester);
    showApp(tester);
    await tester.pump();

    expect(fake.requestPermissionCalls, 2);
    expect(fake.startCalls, 1);
    expect(find.text('Open settings'), findsNothing);
    expect(find.text('Strum 1 of 10'), findsOneWidget);
  });

  testWidgets('W27c a start failure shows the error', (tester) async {
    final fake = FakeAudioSource(startError: Exception('mic busy'));
    await openChordRun(tester, fake, 'E');

    expect(find.text('The microphone could not be started.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(fake.stopCalls, 0);
  });

  testWidgets('W28a leaving during a pending request never starts the mic', (
    tester,
  ) async {
    final permission = Completer<MicPermission>();
    final fake = FakeAudioSource(permissionResults: [permission.future]);
    await openChordRun(tester, fake, 'E');

    expect(fake.requestPermissionCalls, 1);

    await tester.pageBack();
    await finishTransition(tester);

    expect(find.text('Practice'), findsOneWidget);

    permission.complete(MicPermission.granted);
    await tester.pump();

    expect(fake.startCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('W28b a start finishing after leaving turns the mic off', (
    tester,
  ) async {
    final gate = Completer<void>();
    final fake = FakeAudioSource(startGate: gate.future);
    await openChordRun(tester, fake, 'E');

    expect(fake.startCalls, 1);

    await tester.pageBack();
    await finishTransition(tester);

    expect(find.text('Practice'), findsOneWidget);
    expect(fake.stopCalls, 0);

    gate.complete();
    await tester.pump();

    expect(fake.stopCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('W29 hide and show after completion leaves the mic off', (
    tester,
  ) async {
    final fake = FakeAudioSource();
    await openChordRun(tester, fake, 'E');

    fake.feed(strums(chordNamed('E'), 10));

    expect(fake.stopCalls, 1);

    hideApp(tester);
    showApp(tester);
    await finishTransition(tester);

    expect(fake.startCalls, 1);
    expect(fake.stopCalls, 1);
    expect(find.text('10 of 10 (100%)'), findsOneWidget);
  });

  testWidgets('W30 the debug strum source plays a run to the summary', (
    tester,
  ) async {
    prepareView(tester);
    await tester.pumpWidget(
      const MatrixGuitarApp(
        audioSourceFactory: DebugToneSource.new,
        chordAudioSourceFactory: DebugToneSource.strums,
      ),
    );
    await openChord(tester, 'E');
    await tapLabel(tester, 'Practice');

    for (var i = 0; i < 200 && find.text('Done').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await finishTransition(tester);

    expect(find.text('10 of 11 (91%)'), findsOneWidget);
  });

  const diagramPaints = [
    ('W31a', 'E', 1, 6, 3),
    ('W31b', 'D', 1, 4, 5),
    ('W31c', 'G5', 1, 3, 6),
  ];

  for (final (id, name, rects, circles, paragraphs) in diagramPaints) {
    testWidgets('$id the $name diagram paints its grid, dots and marks', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: ChordDiagram(chord: chordNamed(name))),
      );
      final diagram = tester.renderObject(
        find.descendant(
          of: find.byType(ChordDiagram),
          matching: find.byType(CustomPaint),
        ),
      );

      expect(diagram, paintsExactlyCountTimes(#drawRect, rects));
      expect(diagram, paintsExactlyCountTimes(#drawCircle, circles));
      expect(diagram, paintsExactlyCountTimes(#drawParagraph, paragraphs));
    });
  }

  testWidgets('W32 the Bb detail screen spells every note with flats', (
    tester,
  ) async {
    await launchApp(tester, FakeAudioSource());
    await openChord(tester, 'Bb');

    expect(find.text('Notes: Bb  F  Bb  D  F'), findsOneWidget);
    expect(
      find.text(
        'String 6: muted\n'
        'String 5: fret 1 (Bb)\n'
        'String 4: fret 3 (F)\n'
        'String 3: fret 3 (Bb)\n'
        'String 2: fret 3 (D)\n'
        'String 1: fret 1 (F)',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('A#'), findsNothing);
  });

  testWidgets('W33 events after completion are ignored', (tester) async {
    final fake = FakeAudioSource();
    await openChordRun(tester, fake, 'E');

    fake.feed(strums(chordNamed('E'), 12));
    await tester.pump();

    expect(find.text('Paused'), findsNothing);

    await finishTransition(tester);

    expect(find.text('10 of 10 (100%)'), findsOneWidget);
    expect(fake.stopCalls, 1);
  });
}
