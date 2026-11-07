import '../audio/note_listener.dart';
import '../theory/scale.dart';

const _troubleNoteLimit = 3;

enum SessionPhase { notStarted, inProgress, complete }

enum NoteResult { correct, wrong, ignored }

class TroubleNote {
  final int midi;
  final int wrongCount;

  const TroubleNote(this.midi, this.wrongCount);
}

class SessionSummary {
  final int correct;
  final int wrong;
  final double accuracy;
  final Duration duration;
  final List<TroubleNote> troubleNotes;

  const SessionSummary({
    required this.correct,
    required this.wrong,
    required this.accuracy,
    required this.duration,
    required this.troubleNotes,
  });
}

class PracticeSession {
  final List<ScalePosition> _sequence;
  final _wrongCounts = <int, int>{};
  var _phase = SessionPhase.notStarted;
  var _index = 0;
  var _wrong = 0;
  var _startTime = 0.0;
  var _endTime = 0.0;

  PracticeSession(this._sequence);

  SessionPhase get phase => _phase;

  int get index => _index;

  ScalePosition? get expected =>
      _phase == SessionPhase.complete ? null : _sequence[_index];

  NoteResult onNote(NoteEvent event) {
    if (_phase == SessionPhase.complete) return NoteResult.ignored;
    if (_phase == SessionPhase.notStarted) {
      _phase = SessionPhase.inProgress;
      _startTime = event.time;
    }
    _endTime = event.time;

    final expectedMidi = _sequence[_index].midi;
    if (event.midi != expectedMidi) {
      _wrong++;
      _wrongCounts.update(
        expectedMidi,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      return NoteResult.wrong;
    }

    _index++;
    if (_index == _sequence.length) _phase = SessionPhase.complete;
    return NoteResult.correct;
  }

  SessionSummary get summary => SessionSummary(
    correct: _index,
    wrong: _wrong,
    accuracy: _index / (_index + _wrong),
    duration: Duration(
      microseconds: ((_endTime - _startTime) * Duration.microsecondsPerSecond)
          .round(),
    ),
    troubleNotes: _troubleNotes,
  );

  List<TroubleNote> get _troubleNotes {
    final notes = [
      for (final MapEntry(key: midi, value: count) in _wrongCounts.entries)
        TroubleNote(midi, count),
    ];
    notes.sort((a, b) {
      final byCount = b.wrongCount.compareTo(a.wrongCount);
      return byCount != 0 ? byCount : a.midi.compareTo(b.midi);
    });
    return notes.take(_troubleNoteLimit).toList();
  }
}
