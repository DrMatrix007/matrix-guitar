import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../audio/audio_source.dart';
import '../audio/note_listener.dart';
import '../theory/scale.dart';
import 'practice_session.dart';

enum MicState {
  requesting,
  denied,
  permanentlyDenied,
  listening,
  paused,
  error,
}

class PracticeController extends ChangeNotifier {
  final PracticeSession session;
  final AudioSource _source;
  late final _listener = NoteListener(onNote: _onNote, onReading: _onReading);
  late final AppLifecycleListener _lifecycleListener;
  StreamSubscription<Float64List>? _subscription;
  var _micState = MicState.requesting;
  var _disposed = false;
  FrameReading? _reading;
  NoteEvent? _lastEvent;
  NoteResult? _lastResult;

  PracticeController({
    required List<ScalePosition> sequence,
    required this._source,
  }) : session = PracticeSession(sequence) {
    _lifecycleListener = AppLifecycleListener(onHide: _onHide, onShow: _onShow);
    _listener.expectedMidi = session.expected?.midi;
  }

  MicState get micState => _micState;

  FrameReading? get reading => _reading;

  NoteEvent? get lastEvent => _lastEvent;

  NoteResult? get lastResult => _lastResult;

  Future<void> start() async {
    _setMicState(MicState.requesting);
    final permission = await _source.requestPermission();
    if (_disposed) return;
    switch (permission) {
      case MicPermission.granted:
        await _startMic();
      case MicPermission.denied:
        _setMicState(MicState.denied);
      case MicPermission.permanentlyDenied:
        _setMicState(MicState.permanentlyDenied);
    }
  }

  Future<void> openSettings() => _source.openSettings();

  @override
  void dispose() {
    _disposed = true;
    _lifecycleListener.dispose();
    if (_subscription != null) _stopMic();
    super.dispose();
  }

  Future<void> _startMic() async {
    _listener.reset();
    try {
      final stream = await _source.start();
      if (_disposed) {
        _source.stop();
        return;
      }
      _subscription = stream.listen(
        _listener.addSamples,
        onError: _onStreamError,
      );
      _setMicState(MicState.listening);
    } catch (_) {
      if (!_disposed) _setMicState(MicState.error);
    }
  }

  void _stopMic() {
    _subscription?.cancel();
    _subscription = null;
    _source.stop();
  }

  void _setMicState(MicState state) {
    _micState = state;
    notifyListeners();
  }

  void _onNote(NoteEvent event) {
    final result = session.onNote(event);
    _listener.expectedMidi = session.expected?.midi;
    if (result == NoteResult.ignored) return;
    _lastEvent = event;
    _lastResult = result;
    if (session.phase == SessionPhase.complete) {
      _stopMic();
      _micState = MicState.paused;
    }
    notifyListeners();
  }

  void _onReading(FrameReading reading) {
    _reading = reading;
    notifyListeners();
  }

  void _onStreamError(Object _) {
    _stopMic();
    _setMicState(MicState.error);
  }

  void _onHide() {
    if (_micState != MicState.listening) return;
    _stopMic();
    _setMicState(MicState.paused);
  }

  void _onShow() {
    if (_micState == MicState.permanentlyDenied) {
      start();
    } else if (_micState == MicState.paused &&
        session.phase != SessionPhase.complete) {
      _setMicState(MicState.requesting);
      _startMic();
    }
  }
}
