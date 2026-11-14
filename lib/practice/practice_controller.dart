import 'dart:typed_data';

import '../audio/audio_source.dart';
import '../audio/note_listener.dart';
import '../theory/scale.dart';
import 'mic_controller.dart';
import 'practice_session.dart';

class PracticeController extends MicController {
  final PracticeSession session;
  late final _listener = NoteListener(onNote: _onNote, onReading: _onReading);
  FrameReading? _reading;
  NoteEvent? _lastEvent;
  NoteResult? _lastResult;

  PracticeController({
    required List<ScalePosition> sequence,
    required AudioSource source,
  }) : session = PracticeSession(sequence),
       super(source) {
    _listener.expectedMidi = session.expected?.midi;
  }

  FrameReading? get reading => _reading;

  NoteEvent? get lastEvent => _lastEvent;

  NoteResult? get lastResult => _lastResult;

  @override
  bool get isComplete => session.phase == SessionPhase.complete;

  @override
  void addSamples(Float64List samples) => _listener.addSamples(samples);

  @override
  void resetListener() => _listener.reset();

  void _onNote(NoteEvent event) {
    final result = session.onNote(event);
    _listener.expectedMidi = session.expected?.midi;
    if (result == NoteResult.ignored) return;
    _lastEvent = event;
    _lastResult = result;
    if (session.phase == SessionPhase.complete) finishMic();
    notifyListeners();
  }

  void _onReading(FrameReading reading) {
    _reading = reading;
    notifyListeners();
  }
}
