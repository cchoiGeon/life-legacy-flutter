import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 07·08 자기소개 — 음성 모드 / 키보드 모드.
///
/// 두 프레임은 같은 화면의 입력 방식 차이다. 시니어 사용자가 음성을 기본으로
/// 쓰되 언제든 키보드로 바꿀 수 있어야 해서 [mode]로 전환한다.
class IntroController extends GetxController {
  IntroController(this._api, this._speech, this._toast);

  final ApiClient _api;
  final SpeechService _speech;
  final ToastService _toast;

  final answerController = TextEditingController();

  final RxList<IntroQuestion> questions = <IntroQuestion>[].obs;
  final RxBool isLoading = true.obs;

  /// 0부터. `questions[index]`가 지금 화면의 질문이다.
  final RxInt index = 0.obs;

  final Rx<ComposeMode> mode = ComposeMode.voice.obs;

  /// ⚠️ 별도 플래그를 두지 않는다. 인식기가 스스로 멈추거나(무음 타임아웃)
  ///    오류를 내면 서비스 쪽만 false가 되고 화면은 "듣고 있어요…"에
  ///    멈춰 버린다. 서비스의 상태를 그대로 본다.
  RxBool get isRecording => _speech.isListening;

  /// 입력창의 현재 값(반응형). "다음" 버튼 활성 판단에 쓴다.
  final RxString draft = ''.obs;

  /// 질문 id → 답변
  final Map<String, String> answers = {};

  IntroQuestion? get current =>
      index.value < questions.length ? questions[index.value] : null;

  int get step => index.value + 1;
  int get total => questions.length;

  @override
  void onInit() {
    super.onInit();
    answerController.addListener(_onDraftChanged);
    // 인식 오류(무음·권한·네트워크)를 화면에 알리고 키보드로 안내한다.
    ever(_speech.error, _onSpeechError);
    load();
  }

  void _onSpeechError(String? message) {
    if (message == null) return;
    _toast.show(message, description: '키보드로 입력하실 수 있어요');
    _speech.error.value = null;
  }

  @override
  void onClose() {
    _speech.cancel();
    answerController.removeListener(_onDraftChanged);
    answerController.dispose();
    super.onClose();
  }

  void _onDraftChanged() => draft.value = answerController.text;

  Future<void> load() async {
    isLoading.value = true;
    try {
      questions.value = await _api.introQuestions();
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void useKeyboard() => mode.value = ComposeMode.keyboard;

  /// 음성 **대기** 화면으로 돌아간다 — 녹음을 시작하지는 않는다.
  ///
  /// 돌던 받아쓰기 타이머가 있으면 여기서 끊는다. 안 끊으면 화면을 바꾼 뒤에
  /// 뒤늦게 결과가 도착해 입력칸이 제멋대로 채워진다.
  void useVoice() {
    _speech.cancel();
    mode.value = ComposeMode.voice;
    answerController.clear();
  }

  /// 마이크 토글 — 실제 음성 인식.
  ///
  /// 인식 결과는 입력칸에 채워지고 키보드 모드로 바뀐다. 받아쓴 글을
  /// 그대로 넘기지 않고 한 번 고칠 수 있게 하려는 것이다.
  Future<void> toggleRecording() async {
    if (isRecording.value) {
      await _speech.stop();
      isRecording.value = false;
      final heard = _speech.partial.value.trim();
      if (heard.isNotEmpty) _applyTranscript(heard);
      return;
    }

    final started = await _speech.start(
      onFinal: (text) {
        isRecording.value = false;
        _applyTranscript(text);
      },
    );
    if (!started) {
      // 음성으로 진행할 수 없으면 키보드로 안내한다.
      _toast.show(
        _speech.error.value ?? '음성 인식을 쓸 수 없어요',
        description: '키보드로 입력하실 수 있어요',
      );
      mode.value = ComposeMode.keyboard;
      return;
    }
    isRecording.value = true;
  }

  void _applyTranscript(String text) {
    answerController.text = text;
    mode.value = ComposeMode.keyboard;
  }

  /// 말하는 도중 화면에 뜨는 인식 결과.
  String get liveTranscript => _speech.partial.value;

  bool get canGoNext => draft.value.trim().isNotEmpty;

  /// 답을 저장하고 다음 질문으로. 마지막이면 목차 생성으로 넘어간다.
  void next() {
    final q = current;
    if (q == null || !canGoNext) return;
    answers[q.id] = answerController.text.trim();
    answerController.clear();

    if (index.value + 1 >= questions.length) {
      Get.offNamed(AppRoutes.tocLoading, arguments: answers);
      return;
    }
    index.value++;
    mode.value = ComposeMode.voice;
  }

  /// 뒤로 — 첫 질문에서는 화면을 벗어난다.
  void back() {
    if (index.value == 0) {
      Get.back();
      return;
    }
    index.value--;
    final q = current;
    answerController.text = q == null ? '' : (answers[q.id] ?? '');
    mode.value = ComposeMode.voice;
  }
}
