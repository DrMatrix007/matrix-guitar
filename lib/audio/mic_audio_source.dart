import 'dart:io';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'audio_source.dart';

const _config = RecordConfig(
  encoder: AudioEncoder.pcm16bits,
  sampleRate: 44100,
  numChannels: 1,
  autoGain: false,
  echoCancel: false,
  noiseSuppress: false,
  androidConfig: AndroidRecordConfig(
    audioSource: AndroidAudioSource.voiceRecognition,
    manageBluetooth: false,
  ),
);

Float64List pcm16ToSamples(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final samples = Float64List(bytes.length ~/ 2);
  for (var i = 0; i < samples.length; i++) {
    samples[i] = data.getInt16(2 * i, Endian.little) / 32768;
  }
  return samples;
}

Future<Stream<Uint8List>> startWithFallback(
  Future<Stream<Uint8List>> Function(RecordConfig) start, {
  required bool isAndroid,
}) async {
  if (!isAndroid) return start(_config);
  try {
    return await start(_config.copyWith(streamBufferSize: (value: 1024)));
  } on Exception {
    return start(_config);
  }
}

class MicAudioSource implements AudioSource {
  AudioRecorder? _recorder;

  @override
  Future<MicPermission> requestPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return MicPermission.granted;
    if (status.isPermanentlyDenied || status.isRestricted) {
      return MicPermission.permanentlyDenied;
    }
    return MicPermission.denied;
  }

  @override
  Future<void> openSettings() => openAppSettings();

  @override
  Future<Stream<Float64List>> start() async {
    final recorder = _recorder = AudioRecorder();
    final bytes = await startWithFallback(
      recorder.startStream,
      isAndroid: Platform.isAndroid,
    );
    return bytes.map(pcm16ToSamples);
  }

  @override
  Future<void> stop() async {
    final recorder = _recorder;
    _recorder = null;
    await recorder?.stop();
    await recorder?.dispose();
  }
}
