import 'dart:async';

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
  IntroController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final answerController = TextEditingController();

  final RxList<IntroQuestion> questions = <IntroQuestion>[].obs;
  final RxBool isLoading = true.obs;

  /// 0부터. `questions[index]`가 지금 화면의 질문이다.
  final RxInt index = 0.obs;

  final Rx<ComposeMode> mode = ComposeMode.voice.obs;
  final RxBool isRecording = false.obs;

  /// 입력창의 현재 값(반응형). "다음" 버튼 활성 판단에 쓴다.
  final RxString draft = ''.obs;

  /// 질문 id → 답변
  final Map<String, String> answers = {};

  Timer? _recordTimer;

  IntroQuestion? get current =>
      index.value < questions.length ? questions[index.value] : null;

  int get step => index.value + 1;
  int get total => questions.length;

  @override
  void onInit() {
    super.onInit();
    answerController.addListener(_onDraftChanged);
    load();
  }

  @override
  void onClose() {
    _recordTimer?.cancel();
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

  void useVoice() {
    mode.value = ComposeMode.voice;
    answerController.clear();
  }

  /// 마이크 토글. 목업이라 실제 녹음은 없고, 2초 뒤 받아쓴 텍스트가 온다.
  ///
  /// ⚠️ 실제 STT를 붙일 때 바뀌는 지점이다. 단말 STT(speech_to_text)를 쓰면
  ///    부분 인식 결과가 계속 들어오므로 [draft]를 스트림으로 갱신하게 된다.
  Future<void> toggleRecording() async {
    if (isRecording.value) {
      _recordTimer?.cancel();
      isRecording.value = false;
      return;
    }
    isRecording.value = true;
    _recordTimer = Timer(const Duration(seconds: 2), () async {
      if (!isRecording.value) return;
      try {
        final text = await _api.transcribe();
        answerController.text = text;
        mode.value = ComposeMode.keyboard; // 받아쓴 결과를 고칠 수 있게 한다
      } on ApiException catch (e) {
        _toast.showError(e);
      } finally {
        isRecording.value = false;
      }
    });
  }

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
