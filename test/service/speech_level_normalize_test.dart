import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/service/speech_service.dart';

void main() {
  group('SpeechService.normalizeSoundLevel', () {
    test('Android 스케일: 침묵(-2)은 0', () {
      expect(SpeechService.normalizeSoundLevel(-2), 0);
    });

    test('Android 스케일: 큰 소리(10)는 1', () {
      expect(SpeechService.normalizeSoundLevel(10), 1);
    });

    test('Android 스케일: 중간(4)은 0.5', () {
      expect(SpeechService.normalizeSoundLevel(4), 0.5);
    });

    test('iOS dB: 매우 조용함(-60)은 0', () {
      expect(SpeechService.normalizeSoundLevel(-60), 0);
    });

    test('iOS dB: 말하는 수준(-20)은 중간 이상', () {
      final v = SpeechService.normalizeSoundLevel(-20);
      expect(v, greaterThan(0.5));
      expect(v, lessThan(1));
    });

    test('범위를 벗어나면 clamp', () {
      expect(SpeechService.normalizeSoundLevel(99), 1);
      expect(SpeechService.normalizeSoundLevel(-200), 0);
    });
  });
}
