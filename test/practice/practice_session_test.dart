import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/audio/note_listener.dart';
import 'package:matrix_guitar/practice/practice_session.dart';
import 'package:matrix_guitar/theory/scale.dart';

const offScaleMidi = 70;

PracticeSession sessionOf(List<int> midis) => PracticeSession([
  for (final midi in midis) ScalePosition(string: 1, fret: 0, midi: midi),
]);

NoteResult play(PracticeSession session, int midi, {double time = 0}) =>
    session.onNote(NoteEvent(midi, 0, time));

List<(int, int)> troubleOf(PracticeSession session) => [
  for (final note in session.summary.troubleNotes) (note.midi, note.wrongCount),
];

void main() {
  test('S1 correct notes advance the session to completion', () {
    final session = sessionOf([45, 48, 50]);

    expect(session.phase, SessionPhase.notStarted);
    expect(session.expected?.midi, 45);

    expect(play(session, 45), NoteResult.correct);
    expect(session.phase, SessionPhase.inProgress);
    expect(session.index, 1);
    expect(session.expected?.midi, 48);

    expect(play(session, 48), NoteResult.correct);
    expect(session.phase, SessionPhase.inProgress);
    expect(session.expected?.midi, 50);

    expect(play(session, 50), NoteResult.correct);
    expect(session.phase, SessionPhase.complete);
    expect(session.index, 3);
    expect(session.expected, isNull);
  });

  test('S2 a wrong note and a wrong octave count and do not advance', () {
    final session = sessionOf([45, 48]);

    expect(play(session, 46), NoteResult.wrong);
    expect(play(session, 57), NoteResult.wrong);

    expect(session.index, 0);
    expect(session.expected?.midi, 45);
    expect(session.summary.wrong, 2);
    expect(session.summary.correct, 0);
  });

  test('S3 repeated notes are separate steps', () {
    final passes = sessionOf([45, 48, 50, 48, 45]);

    play(passes, 45);
    play(passes, offScaleMidi);
    play(passes, 48);
    play(passes, 50);
    play(passes, offScaleMidi);
    play(passes, 48);
    expect(passes.phase, SessionPhase.inProgress);
    play(passes, 45);

    expect(passes.phase, SessionPhase.complete);
    expect(passes.summary.correct, 5);
    expect(troubleOf(passes), [(48, 2)]);

    final repeated = sessionOf([60, 60, 62]);

    expect(play(repeated, 60), NoteResult.correct);
    expect(repeated.index, 1);
    expect(repeated.expected?.midi, 60);
  });

  test('S4 events after completion are ignored and change nothing', () {
    final session = sessionOf([45, 48]);
    play(session, 45, time: 1);
    play(session, offScaleMidi, time: 2);
    play(session, 48, time: 3);

    expect(play(session, 48, time: 4), NoteResult.ignored);
    expect(play(session, offScaleMidi, time: 5), NoteResult.ignored);

    expect(session.phase, SessionPhase.complete);
    expect(session.index, 2);
    expect(session.summary.correct, 2);
    expect(session.summary.wrong, 1);
    expect(session.summary.duration, const Duration(seconds: 2));
    expect(troubleOf(session), [(48, 1)]);
  });

  test('S5 the summary reports accuracy, duration and trouble notes', () {
    final session = sessionOf([50, 52, 55, 57, 60]);
    final wrongPerNote = {50: 3, 52: 2, 55: 4, 57: 1, 60: 0};
    var time = 1.0;

    for (final MapEntry(key: midi, value: wrongCount) in wrongPerNote.entries) {
      for (var i = 0; i < wrongCount; i++) {
        play(session, offScaleMidi, time: time);
        time += 0.2;
      }
      play(session, midi, time: midi == 60 ? 4.0 : time);
    }

    final summary = session.summary;
    expect(summary.correct, 5);
    expect(summary.wrong, 10);
    expect(summary.accuracy, closeTo(1 / 3, 1e-12));
    expect(summary.duration, const Duration(seconds: 3));
    expect(troubleOf(session), [(55, 4), (50, 3), (52, 2)]);
  });
}
