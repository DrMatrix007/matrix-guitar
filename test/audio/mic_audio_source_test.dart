import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_guitar/audio/mic_audio_source.dart';
import 'package:record/record.dart';

class FakeStart {
  final List<Object?> outcomes;
  final configs = <RecordConfig>[];

  FakeStart(this.outcomes);

  Future<Stream<Uint8List>> call(RecordConfig config) async {
    final outcome = outcomes[configs.length];
    configs.add(config);
    if (outcome is Exception) throw outcome;
    return outcome! as Stream<Uint8List>;
  }
}

void main() {
  group('M1 pcm16ToSamples', () {
    test('decodes little-endian 16-bit samples', () {
      const pcm = [0x00, 0x00, 0x01, 0x00, 0xFF, 0xFF, 0xFF, 0x7F, 0x00, 0x80];

      expect(pcm16ToSamples(Uint8List.fromList(pcm)), [
        0.0,
        1 / 32768,
        -1 / 32768,
        32767 / 32768,
        -1.0,
      ]);
    });

    test('decodes a view at a non-zero offset', () {
      final backing = Uint8List.fromList([0xAA, 0x01, 0x00, 0x00, 0x80, 0xBB]);

      final samples = pcm16ToSamples(Uint8List.sublistView(backing, 1, 5));

      expect(samples, [1 / 32768, -1.0]);
    });
  });

  group('M2 startWithFallback', () {
    final firstStream = Stream<Uint8List>.empty();
    final secondStream = Stream<Uint8List>.empty();

    test(
      'Android asks for a small buffer first and stops on success',
      () async {
        final start = FakeStart([firstStream]);

        final stream = await startWithFallback(start.call, isAndroid: true);

        expect(stream, same(firstStream));
        expect(start.configs, hasLength(1));
        expect(start.configs.single.streamBufferSize, 1024);
        expect(
          start.configs.single.androidConfig.audioSource,
          AndroidAudioSource.voiceRecognition,
        );
      },
    );

    test('Android retries once with the default buffer on failure', () async {
      final start = FakeStart([Exception('rejected'), secondStream]);

      final stream = await startWithFallback(start.call, isAndroid: true);

      expect(stream, same(secondStream));
      expect(start.configs.map((config) => config.streamBufferSize), [
        1024,
        null,
      ]);
    });

    test('Android propagates a second failure', () async {
      final second = Exception('still rejected');
      final start = FakeStart([Exception('rejected'), second]);

      await expectLater(
        startWithFallback(start.call, isAndroid: true),
        throwsA(same(second)),
      );
      expect(start.configs, hasLength(2));
    });

    test('other platforms call once with the default buffer', () async {
      final start = FakeStart([firstStream]);

      final stream = await startWithFallback(start.call, isAndroid: false);

      expect(stream, same(firstStream));
      expect(start.configs, hasLength(1));
      expect(start.configs.single.streamBufferSize, isNull);
    });

    test('other platforms do not retry a failure', () async {
      final failure = Exception('rejected');
      final start = FakeStart([failure, secondStream]);

      await expectLater(
        startWithFallback(start.call, isAndroid: false),
        throwsA(same(failure)),
      );
      expect(start.configs, hasLength(1));
    });
  });
}
