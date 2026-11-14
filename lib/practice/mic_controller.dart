import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../audio/audio_source.dart';

enum MicState {
  requesting,
  denied,
  permanentlyDenied,
  listening,
  paused,
  error,
}

abstract class MicController extends ChangeNotifier {
  final AudioSource _source;
  late final AppLifecycleListener _lifecycleListener;
  StreamSubscription<Float64List>? _subscription;
  var _micState = MicState.requesting;
  var _disposed = false;

  MicController(this._source) {
    _lifecycleListener = AppLifecycleListener(onHide: _onHide, onShow: _onShow);
  }

  MicState get micState => _micState;

  bool get isComplete;

  @protected
  void addSamples(Float64List samples);

  @protected
  void resetListener();

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

  @protected
  void finishMic() {
    _stopMic();
    _micState = MicState.paused;
  }

  Future<void> _startMic() async {
    resetListener();
    try {
      final stream = await _source.start();
      if (_disposed) {
        _source.stop();
        return;
      }
      _subscription = stream.listen(addSamples, onError: _onStreamError);
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
    } else if (_micState == MicState.paused && !isComplete) {
      _setMicState(MicState.requesting);
      _startMic();
    }
  }
}
