import 'dart:async';
import 'dart:typed_data';

import 'package:matrix_guitar/audio/audio_source.dart';

class FakeAudioSource implements AudioSource {
  final List<FutureOr<MicPermission>> permissionResults;
  Object? startError;
  Future<void>? startGate;
  var requestPermissionCalls = 0;
  var openSettingsCalls = 0;
  var startCalls = 0;
  var stopCalls = 0;
  StreamController<Float64List>? _controller;

  FakeAudioSource({
    List<FutureOr<MicPermission>>? permissionResults,
    this.startError,
    this.startGate,
  }) : permissionResults = permissionResults ?? [MicPermission.granted];

  void feed(Float64List samples) => _controller!.add(samples);

  void failStream(Object error) => _controller!.addError(error);

  @override
  Future<MicPermission> requestPermission() async {
    requestPermissionCalls++;
    return permissionResults.removeAt(0);
  }

  @override
  Future<void> openSettings() async {
    openSettingsCalls++;
  }

  @override
  Future<Stream<Float64List>> start() async {
    startCalls++;
    final gate = startGate;
    if (gate != null) await gate;
    final error = startError;
    if (error != null) throw error;
    final controller = _controller = StreamController(sync: true);
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _controller?.close();
    _controller = null;
  }
}
