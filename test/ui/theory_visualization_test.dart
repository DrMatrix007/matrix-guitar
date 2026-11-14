import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/theory/harmony.dart';
import 'package:matrix_guitar/ui/fretboard.dart';
import 'package:matrix_guitar/ui/staff_notation.dart';
import 'package:matrix_guitar/ui/theory_visualization.dart';

void main() {
  test('staff spelling preserves octave boundaries and double accidentals', () {
    expect(const StaffNote(60, 'B#').label, 'B#3');
    expect(const StaffNote(59, 'Cb').label, 'Cb4');
    expect(const StaffNote(61, 'B##').label, 'B##3');
    expect(const StaffNote(58, 'Cbb').label, 'Cbb4');
    expect(const StaffNote(60, 'B#').staffStep, -3);
    expect(const StaffNote(59, 'Cb').staffStep, -2);
    expect(const StaffNote(64, 'E').staffStep, 0);
    expect(const StaffNote(77, 'F').staffStep, 8);
  });

  Future<void> show(WidgetTester tester, TheoryVisualization view) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: view)),
        ),
      );

  testWidgets(
    'all keys and chords show ascending inversion pitches and matching fretboard names',
    (tester) async {
      for (var key = 0; key < 12; key++) {
        for (final progression in harmonyProgressions) {
          for (final chord in progression.chords(key, (
            minFret: 3,
            maxFret: 7,
          ))) {
            for (
              var inversion = 0;
              inversion < chord.tones.length;
              inversion++
            ) {
              await show(
                tester,
                TheoryVisualization(
                  key: UniqueKey(),
                  chords: [chord],
                  inversion: inversion,
                ),
              );
              final staff = tester.widget<StaffNotation>(
                find.byType(StaffNotation),
              );
              final board = tester.widget<Fretboard>(find.byType(Fretboard));
              expect(
                staff.notes.map((n) => n.name),
                chord.inversionNames(inversion),
              );
              for (var i = 1; i < staff.notes.length; i++) {
                expect(
                  staff.notes[i].midi,
                  greaterThan(staff.notes[i - 1].midi),
                );
              }
              expect(
                board.highlight!.midi,
                staff.notes[staff.selectedIndex].midi,
              );
              for (final position in board.scale.positions) {
                expect(
                  board.noteName!(position.midi),
                  chord.noteNames[chord.intervals.indexOf(
                    (position.midi - chord.root) % 12,
                  )],
                );
              }
              expect(tester.takeException(), isNull);
            }
          }
        }
      }
    },
  );

  testWidgets(
    'secondary and borrowed notes remain spelled in chord context when selected',
    (tester) async {
      final chords = harmonyProgressions[2].chords(5, (minFret: 3, maxFret: 7));
      await show(tester, TheoryVisualization(chords: chords));
      await tester.tap(find.text('V/ii · D7'));
      await tester.pump();
      expect(
        tester
            .widget<StaffNotation>(find.byType(StaffNotation))
            .notes
            .map((n) => n.name),
        ['D', 'F#', 'A', 'C'],
      );
      await tester.tap(find.text('seventh · C'));
      await tester.pump();
      expect(
        tester.widget<StaffNotation>(find.byType(StaffNotation)).selectedIndex,
        3,
      );
      await tester.tap(find.text('ii · Gm'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final borrowed = harmonyProgressions[3].chords(1, (
        minFret: 3,
        maxFret: 7,
      ));
      await show(
        tester,
        TheoryVisualization(key: UniqueKey(), chords: [borrowed[2]]),
      );
      expect(
        tester
            .widget<StaffNotation>(find.byType(StaffNotation))
            .notes
            .map((n) => n.name),
        ['Gb', 'Bbb', 'Db'],
      );
    },
  );

  testWidgets(
    'guide path uses the same target pitches and selected guitar location',
    (tester) async {
      final chords = harmonyProgressions.first.chords(0, (
        minFret: 3,
        maxFret: 7,
      ));
      final targets = harmonyTargets(chords, guideTones: true);
      await show(tester, TheoryVisualization(chords: chords, guideTones: true));
      expect(
        tester
            .widget<StaffNotation>(find.byType(StaffNotation))
            .notes
            .map((n) => n.midi),
        targets.map((t) => t.position.midi),
      );
      await tester.tap(find.text('V7 · G7'));
      await tester.pump();
      expect(
        tester.widget<StaffNotation>(find.byType(StaffNotation)).selectedIndex,
        1,
      );
      expect(
        tester.widget<Fretboard>(find.byType(Fretboard)).highlight,
        targets[1].position,
      );
    },
  );

  testWidgets(
    'paired diagrams fit narrow and wide layouts and update a live target',
    (tester) async {
      final chords = harmonyProgressions.first.chords(0, (
        minFret: 3,
        maxFret: 7,
      ));
      final targets = harmonyTargets(chords);
      for (final width in [320.0, 1000.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        for (final target in targets) {
          await show(
            tester,
            TheoryVisualization(chords: [target.chord], target: target),
          );
          final staff = tester.widget<StaffNotation>(
            find.byType(StaffNotation),
          );
          expect(staff.notes.single.midi, target.position.midi);
          expect(staff.notes.single.name, target.chord.toneName(target.tone));
          expect(
            tester.widget<Fretboard>(find.byType(Fretboard)).highlight,
            target.position,
          );
          expect(tester.takeException(), isNull);
        }
      }
      tester.view.reset();
    },
  );
}
