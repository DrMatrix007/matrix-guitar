import 'dart:typed_data';

enum MicPermission { granted, denied, permanentlyDenied }

abstract interface class AudioSource {
  Future<MicPermission> requestPermission();
  Future<void> openSettings();
  Future<Stream<Float64List>> start();
  Future<void> stop();
}
