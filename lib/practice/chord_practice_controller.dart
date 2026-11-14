import 'dart:typed_data';

import '../audio/audio_source.dart';
import '../audio/strum_detector.dart';
import '../theory/chord.dart';
import 'mic_controller.dart';
import 'practice_session.dart';

class ChordPracticeController extends MicController {
  final ChordVoicing chord;
  late final _detector = StrumDetector(
    notes: chord.playedNotes,
    onStrum: _onStrum,
  );
  var _correct = 0;
  var _wrong = 0;
  var _startTime = 0.0;
  var _endTime = 0.0;
  StrumEvent? _lastStrum;

  ChordPracticeController({required this.chord, required AudioSource source})
    : super(source);

  int get correct => _correct;

  StrumEvent? get lastStrum => _lastStrum;

  @override
  bool get isComplete => _correct == chordStrumCount;

  SessionSummary get summary => SessionSummary(
    correct: _correct,
    wrong: _wrong,
    accuracy: _correct / (_correct + _wrong),
    duration: Duration(
      microseconds: ((_endTime - _startTime) * Duration.microsecondsPerSecond)
          .round(),
    ),
    troubleNotes: const [],
  );

  @override
  void addSamples(Float64List samples) => _detector.addSamples(samples);

  @override
  void resetListener() => _detector.reset();

  void _onStrum(StrumEvent event) {
    if (isComplete) return;
    if (_lastStrum == null) _startTime = event.time;
    _endTime = event.time;
    if (event.correct) {
      _correct++;
    } else {
      _wrong++;
    }
    _lastStrum = event;
    if (isComplete) finishMic();
    notifyListeners();
  }
}
