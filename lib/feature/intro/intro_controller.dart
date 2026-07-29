import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 08 자기소개 — 성함은 키보드로, 나머지는 예/아니요 버튼으로 받는다.
///
/// ⚠️ 여기에는 **음성 입력이 없다.** 작성 탭(13)과 달리 답이 이름 한 단어나
///    두 갈래 선택이라 받아쓰기가 오히려 손이 더 간다. 되살릴 일이 생기면
///    작성 탭의 [SpeechService] 사용 방식을 그대로 가져오면 된다.
class IntroController extends GetxController {
  IntroController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final answerController = TextEditingController();

  final RxList<IntroQuestion> questions = <IntroQuestion>[].obs;
  final RxBool isLoading = true.obs;

  /// 0부터. `questions[index]`가 지금 화면의 질문이다.
  final RxInt index = 0.obs;

  /// 입력창의 현재 값(반응형). "다음" 버튼 활성 판단에 쓴다.
  final RxString draft = ''.obs;

  /// 질문 id → 답변
  final Map<String, String> answers = {};

  IntroQuestion? get current =>
      index.value < questions.length ? questions[index.value] : null;

  int get step => index.value + 1;
  int get total => questions.length;

  /// "질문 1 / 5" — 작성 탭(WriteController.progressLabel)과 같은 형식이다.
  /// 두 화면의 진행률 블록이 같은 모양이라 문구도 맞췄다.
  String get progressLabel => total == 0 ? '' : '질문 $step / $total';

  @override
  void onInit() {
    super.onInit();
    answerController.addListener(_onDraftChanged);
    load();
  }

  @override
  void onClose() {
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

  bool get canGoNext => draft.value.trim().isNotEmpty;

  /// 고르기 문항 — 누르는 즉시 저장하고 다음으로 넘어간다.
  /// 텍스트 문항처럼 "다음" 버튼을 한 번 더 누르게 하지 않는다.
  void choose(String value) {
    final q = current;
    if (q == null) return;
    answers[q.id] = value;
    _advance();
  }

  /// 텍스트 문항 — 적은 답을 저장하고 다음으로.
  void next() {
    final q = current;
    if (q == null || !canGoNext) return;
    answers[q.id] = answerController.text.trim();
    _advance();
  }

  /// 다음 문항으로. 마지막이면 목차 생성으로 넘어간다.
  void _advance() {
    answerController.clear();
    if (index.value + 1 >= questions.length) {
      Get.offNamed(AppRoutes.tocLoading, arguments: answers);
      return;
    }
    index.value++;
  }

  /// 뒤로 — 첫 질문에서는 화면을 벗어난다.
  void back() {
    if (index.value == 0) {
      Get.back();
      return;
    }
    index.value--;
    final q = current;
    // 고르기 문항은 입력칸이 없다 — 텍스트 문항일 때만 되살린다.
    answerController.text = (q != null && q.type == IntroAnswerType.text)
        ? (answers[q.id] ?? '')
        : '';
  }
}
