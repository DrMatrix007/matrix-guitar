import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/audio/debug_tone_source.dart';
import 'package:matrix_guitar/theory/harmony.dart';
import 'package:matrix_guitar/ui/scale_list_screen.dart';
import 'package:matrix_guitar/ui/theory_play_screen.dart';
import 'package:matrix_guitar/ui/theory_practice_screen.dart';

import '../helpers/fake_audio_source.dart';

void prepareView(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

Future<void> tapLabel(WidgetTester tester, String label) async {
  final labelFinder = find.text(label);
  for (
    var attempt = 0;
    attempt < 8 && labelFinder.evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  final finder = labelFinder.first;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> chooseDropdown(
  WidgetTester tester,
  int index,
  String choice,
) async {
  tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .jumpTo(0);
  await tester.pumpAndSettle();
  final dropdowns = find.byWidgetPredicate(
    (widget) => widget is DropdownButton<int>,
  );
  await tester.tap(dropdowns.at(index));
  await tester.pumpAndSettle();
  await tester.tap(find.text(choice).last);
  await tester.pumpAndSettle();
}

Future<void> startPractice(WidgetTester tester) async =>
    tapLabel(tester, 'Start quiz');

void main() {
  testWidgets('beginner help expands and follows the selected exercise', (
    tester,
  ) async {
    prepareView(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TheoryPracticeScreen(
            audioSourceFactory: (_) => FakeAudioSource(),
          ),
        ),
      ),
    );
    expect(find.textContaining('A key is a family'), findsNothing);
    await tapLabel(tester, 'Music theory basics');
    expect(find.textContaining('A key is a family'), findsOneWidget);
    await tapLabel(tester, 'Music theory basics');
    await tapLabel(tester, 'How this exercise works');
    expect(
      find.text('Selected progression: Dm7 → G7 → Cmaj7.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Its third is F, 3 semitones above D.'),
      findsOneWidget,
    );
    await chooseDropdown(tester, 0, 'F major');
    await chooseDropdown(tester, 1, 'I–V/ii–ii–V–I');
    await tapLabel(tester, 'Progression transposition');
    await tester.scrollUntilVisible(
      find.textContaining('V/ii means “five of two”.'),
      300,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('D7 (D–F#–A–C) leads to Gm'), findsOneWidget);
    expect(find.textContaining('count F–G–A–Bb–C–D–E'), findsOneWidget);
    await chooseDropdown(tester, 1, 'I–IV–iv–I');
    await tester.scrollUntilVisible(find.textContaining('Borrowed iv:'), 300);
    expect(
      find.textContaining('Bb becomes Bbm by lowering D to Db'),
      findsOneWidget,
    );
    await tapLabel(tester, 'Advanced example · ungraded');
    await tester.ensureVisible(find.textContaining('A shell voicing'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('quiz reminder teaches the method without the worked answer', (
    tester,
  ) async {
    prepareView(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TheoryPracticeScreen(
            audioSourceFactory: (_) => FakeAudioSource(),
          ),
        ),
      ),
    );
    await startPractice(tester);
    await tapLabel(tester, 'Remember the method');
    expect(find.textContaining('a minor third 3'), findsOneWidget);
    expect(find.textContaining('Worked example:'), findsNothing);
    expect(find.textContaining('F is the chord-relative third'), findsNothing);
    await tapLabel(tester, 'F');
    expect(
      find.textContaining(
        'F is the chord-relative third of Dm7: 3 semitones above its root D.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('notes: D–F–A–C'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Theory is the fourth tab and quiz retries without requesting audio',
    (tester) async {
      prepareView(tester);
      final fake = FakeAudioSource();
      var sourceFactoryCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ScaleListScreen(
            audioSourceFactory: (_) {
              sourceFactoryCalls++;
              return fake;
            },
            chordAudioSourceFactory: (_) => fake,
          ),
        ),
      );
      expect(find.text('Theory'), findsOneWidget);
      await tapLabel(tester, 'Theory');
      expect(find.text('Theory practice'), findsOneWidget);
      expect(sourceFactoryCalls, 0);

      await startPractice(tester);
      expect(
        find.text('Question 1 of 3 · 0 incorrect attempts'),
        findsOneWidget,
      );
      expect(sourceFactoryCalls, 0);
      await tapLabel(tester, 'A');
      expect(
        find.textContaining('Try again. The answer is F.'),
        findsOneWidget,
      );
      expect(
        find.text('Question 1 of 3 · 1 incorrect attempts'),
        findsOneWidget,
      );
      await tapLabel(tester, 'F');
      expect(find.text('Next'), findsOneWidget);
      await tapLabel(tester, 'Next');
      expect(
        find.text('Question 2 of 3 · 1 incorrect attempts'),
        findsOneWidget,
      );
      await tapLabel(tester, 'B');
      await tapLabel(tester, 'Next');
      await tapLabel(tester, 'E');
      await tapLabel(tester, 'Finish');
      expect(find.text('Practice complete'), findsOneWidget);
      expect(
        find.text('3 questions completed · 1 incorrect attempts'),
        findsOneWidget,
      );
      await tapLabel(tester, 'Retry quiz');
      expect(
        find.text('Question 1 of 3 · 0 incorrect attempts'),
        findsOneWidget,
      );
      expect(sourceFactoryCalls, 0);
      expect(fake.requestPermissionCalls, 0);
      expect(fake.startCalls, 0);
    },
  );

  testWidgets(
    'transposition choices spell secondary and borrowed chords in key',
    (tester) async {
      prepareView(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TheoryPracticeScreen(
              audioSourceFactory: (_) => FakeAudioSource(),
            ),
          ),
        ),
      );
      await chooseDropdown(tester, 0, 'F major');
      await chooseDropdown(tester, 1, 'I–V/ii–ii–V–I');
      await tapLabel(tester, 'Progression transposition');
      await startPractice(tester);
      await tapLabel(tester, 'F');
      await tapLabel(tester, 'Next');
      expect(find.text('In F major, which chord is V/ii?'), findsOneWidget);
      expect(find.text('D7'), findsOneWidget);
      await tapLabel(tester, 'D7');
      expect(find.textContaining('V/ii is D7'), findsOneWidget);

      await tapLabel(tester, 'Back to setup');
      await chooseDropdown(tester, 1, 'I–IV–iv–I');
      await chooseDropdown(tester, 0, 'Db major');
      await startPractice(tester);
      await tapLabel(tester, 'Db');
      await tapLabel(tester, 'Next');
      await tapLabel(tester, 'Gb');
      await tapLabel(tester, 'Next');
      expect(find.text('In Db major, which chord is iv?'), findsOneWidget);
      expect(find.text('Gbm'), findsOneWidget);
    },
  );

  testWidgets('construction asks for the bass in a third inversion', (
    tester,
  ) async {
    prepareView(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TheoryPracticeScreen(
            audioSourceFactory: (_) => FakeAudioSource(),
          ),
        ),
      ),
    );
    await tapLabel(tester, 'Construction & inversions');
    await tapLabel(tester, 'Third inversion');
    await startPractice(tester);
    await tapLabel(tester, '1–b3–5–b7');
    await tapLabel(tester, 'Next');
    expect(
      find.text('Which bass note gives Dm7 third inversion?'),
      findsOneWidget,
    );
    expect(find.text('C'), findsOneWidget);
    expect(find.textContaining('Bass to top: C–D–F–A.'), findsNothing);
    await tapLabel(tester, 'C');
    expect(find.textContaining('Bass to top: C–D–F–A.'), findsOneWidget);
    expect(find.textContaining('Put the seventh, C, lowest.'), findsOneWidget);
    expect(find.textContaining('chord root remains D.'), findsOneWidget);
  });

  testWidgets(
    'microphone play retains chord context and summarizes the full sequence',
    (tester) async {
      prepareView(tester);
      final fake = FakeAudioSource();
      final targets = harmonyTargets(
        harmonyProgressions.first.chords(0, (minFret: 3, maxFret: 7)),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TheoryPlayScreen(
                        targets: targets,
                        audioSourceFactory: (_) => fake,
                      ),
                    ),
                  ),
                  child: const Text('Open play'),
                ),
              ),
            ),
          ),
        ),
      );
      await tapLabel(tester, 'Open play');
      await tester.pump();
      expect(fake.requestPermissionCalls, 1);
      expect(fake.startCalls, 1);
      expect(find.text('Dm7'), findsOneWidget);
      expect(find.textContaining('chord-relative third: F'), findsOneWidget);
      expect(find.textContaining('String 1 is the thinnest'), findsOneWidget);
      expect(find.textContaining('MIDI'), findsNothing);

      fake.feed(
        synthPluck(midi: targets.first.position.midi + 1, duration: .7),
      );
      await tester.pump();
      expect(
        find.textContaining('Try again: Dm7 (ii7), third.'),
        findsOneWidget,
      );
      expect(find.textContaining('Played '), findsOneWidget);
      expect(find.text('Dm7'), findsOneWidget);

      fake.feed(synthPluck(midi: targets.first.position.midi, duration: .7));
      await tester.pump();
      expect(find.text('G7'), findsOneWidget);
      for (final target in targets.skip(1)) {
        fake.feed(synthPluck(midi: target.position.midi, duration: .7));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('Theory practice'), findsOneWidget);
      expect(find.text('3 of 4 (75%)'), findsOneWidget);
      expect(find.text('No wrong notes.'), findsNothing);
      expect(fake.stopCalls, 1);
      await tapLabel(tester, 'Done');
      await tester.pumpAndSettle();
      expect(fake.stopCalls, 1);
      expect(find.text('Open play'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
