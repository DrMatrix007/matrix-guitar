import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/theory/chord.dart';
import 'package:matrix_guitar/ui/chord_explanation.dart';
import 'package:matrix_guitar/ui/progression_explorer.dart';
import 'package:matrix_guitar/ui/staff_notation.dart';

void main() {
  testWidgets('all chord qualities show only their own tones at narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final chord in chordLibrary) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: ChordExplanation(chord: chord)),
          ),
        ),
      );
      final staff = tester.widget<StaffNotation>(find.byType(StaffNotation));
      expect(staff.stacked, isTrue);
      expect(
        staff.notes.map((n) => n.midi % 12).toSet(),
        chord.playedNotes.map((n) => n % 12).toSet(),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('explorer changes progression and key and traces guide tones', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ProgressionExplorer()),
        ),
      ),
    );
    expect(find.text('ii7 · Dm7'), findsWidgets);
    expect(find.textContaining('Dm7 → G7: shared tones D, F'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('I–IV–iv–I').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('borrowed from the minor key'), findsOneWidget);
    final keyNote = find.bySemanticsLabel('Choose D major, string 2 fret 3');
    await tester.ensureVisible(keyNote);
    await tester.tap(keyNote);
    await tester.pumpAndSettle();
    expect(find.text('iv · Gm'), findsWidgets);
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('Guide-tone path'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
