import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';

/// 음성 인식(STT) — **단말 기능**이라 `ApiClient`가 아니라 서비스로 둔다.
///
/// 안드로이드는 시스템 `SpeechRecognizer`(대개 Google 앱), iOS는 Speech
/// 프레임워크를 쓴다. 서버로 오디오를 올리지 않는다.
///
/// ⚠️ 인식기가 없거나 권한이 거부되면 [available]이 false가 된다. 이때
///    화면은 음성 대신 **키보드 입력으로 안내**해야 한다 — 버튼만 눌리고
///    아무 일도 안 일어나는 상태를 만들면 안 된다.
class SpeechService extends GetxService {
  final _speech = stt.SpeechToText();

  /// 인식기를 쓸 수 있는지. [init] 전에는 null.
  final RxnBool available = RxnBool();

  final RxBool isListening = false.obs;

  /// 말하는 도중 계속 갱신되는 부분 인식 결과.
  final RxString partial = ''.obs;

  /// 마지막 오류 메시지(사용자에게 보여줄 한국어 문장). 없으면 null.
  final RxnString error = RxnString();

  /// 한국어 고정. 기기에 ko_KR이 없으면 [init]에서 기본 로케일로 물러난다.
  String _localeId = 'ko_KR';

  /// 앱 시작 시 한 번 부른다. 권한 요청도 여기서 일어난다.
  ///
  /// 실패해도 예외를 던지지 않는다 — 음성이 안 되는 기기에서도 앱은
  /// 키보드 입력으로 계속 쓸 수 있어야 한다.
  Future<SpeechService> init() async {
    try {
      final ok = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
      available.value = ok;
      if (ok) await _pickKoreanLocale();
    } on Exception {
      available.value = false;
    }
    return this;
  }

  /// 기기에 설치된 로케일 중 한국어를 고른다.
  /// 없으면 시스템 기본값을 쓴다(빈 문자열이면 플러그인이 기본을 쓴다).
  Future<void> _pickKoreanLocale() async {
    final locales = await _speech.locales();
    final ko = locales.firstWhereOrNull(
      (l) => l.localeId.replaceAll('-', '_').startsWith('ko'),
    );
    _localeId = ko?.localeId ?? (await _speech.systemLocale())?.localeId ?? '';
  }

  /// 듣기 시작. [onFinal]은 사용자가 말을 마쳤을 때 한 번 호출된다.
  ///
  /// 반환값이 false면 시작하지 못한 것이다(권한 거부·인식기 없음).
  Future<bool> start({required void Function(String text) onFinal}) async {
    if (available.value != true) {
      error.value = '이 기기에서는 음성 인식을 쓸 수 없어요';
      return false;
    }
    if (isListening.value) return true;

    partial.value = '';
    error.value = null;

    try {
      await _speech.listen(
        onResult: (result) {
          partial.value = result.recognizedWords;
          if (result.finalResult) {
            isListening.value = false;
            if (result.recognizedWords.trim().isNotEmpty) {
              onFinal(result.recognizedWords.trim());
            }
          }
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: _localeId,
          // 어르신이 천천히 말씀하시는 걸 감안해 넉넉히 잡는다.
          // (기본값은 침묵 3초면 끊는다)
          listenFor: const Duration(minutes: 2),
          pauseFor: const Duration(seconds: 6),
          // 말하는 동안 화면에 글자가 차오르게 한다 — 시니어 사용자가
          // "듣고 있다"를 눈으로 확인할 수 있어야 한다.
          partialResults: true,
          // 받아쓰기 모드. 짧은 명령이 아니라 긴 이야기를 받는다.
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
        ),
      );
      isListening.value = true;
      return true;
    } on Exception {
      error.value = '음성 인식을 시작하지 못했어요';
      isListening.value = false;
      return false;
    }
  }

  /// 사용자가 "멈춤"을 눌렀을 때. 지금까지 인식된 내용이 최종 결과로 온다.
  Future<void> stop() async {
    if (!isListening.value) return;
    await _speech.stop();
    isListening.value = false;
  }

  /// 화면을 벗어날 때. 결과를 버린다.
  Future<void> cancel() async {
    if (!_speech.isListening) return;
    await _speech.cancel();
    isListening.value = false;
    partial.value = '';
  }

  void _onStatus(String status) {
    // 'done' · 'notListening' 은 인식기가 스스로 멈춘 경우다.
    if (status == 'done' || status == 'notListening') {
      isListening.value = false;
    }
  }

  void _onError(SpeechRecognitionError e) {
    isListening.value = false;
    error.value = _message(e.errorMsg);
  }

  /// 플러그인이 주는 오류 코드를 사용자가 읽을 문장으로 바꾼다.
  /// 원문은 'error_speech_timeout' 같은 영어 상수라 그대로 보여줄 수 없다.
  static String _message(String code) => switch (code) {
    'error_speech_timeout' ||
    'error_no_match' => '말씀을 알아듣지 못했어요. 다시 한 번 말씀해 주세요',
    'error_permission' => '마이크 권한이 필요해요. 설정에서 허용해 주세요',
    'error_network' ||
    'error_network_timeout' => '네트워크가 불안정해요. 잠시 후 다시 시도해 주세요',
    'error_busy' => '다른 앱이 마이크를 쓰고 있어요',
    _ => '음성 인식에 문제가 생겼어요. 키보드로 입력하실 수 있어요',
  };
}
