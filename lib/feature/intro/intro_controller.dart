import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// B1~B5 자기소개 — 성함은 키보드로, 나머지는 선택지로 받는다.
///
/// ⚠️ 여기에는 **음성 입력이 없다.** 작성 탭(D)과 달리 답이 이름 한 단어나
///    보기 중 하나라 받아쓰기가 오히려 손이 더 간다. 되살릴 일이 생기면
///    작성 탭의 [SpeechService] 사용 방식을 그대로 가져오면 된다.
///
/// ⚠️ 선택지는 **누른다고 넘어가지 않는다.** 예전에는 고르는 즉시 다음
///    문항으로 갔지만, 학력 문항이 4지선다가 되면서 잘못 누른 걸 고칠 여지가
///    필요해졌다. 이제 고른 값이 화면에 남고 하단 "다음"으로 넘어간다.
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

  /// 지금 문항에서 고른 선택지. 고르기 문항에서만 쓴다.
  final RxnString selected = RxnString();

  /// 질문 id → 답변
  final Map<String, String> answers = {};

  IntroQuestion? get current =>
      index.value < questions.length ? questions[index.value] : null;

  int get step => index.value + 1;
  int get total => questions.length;

  /// 우상단 "3 / 5"
  String get stepLabel => total == 0 ? '' : '$step / $total';

  double get progress => total == 0 ? 0 : step / total;

  /// 버튼 문구는 다섯 문항 내내 "다음"이다 — 시안 346:820이 마지막 문항(B5)에도
  /// "다음"을 쓴다. 마지막만 "목차 만들기"로 바꾸면 무슨 일이 일어날지 예고되지만,
  /// 다섯 번 중 한 번만 달라지는 버튼은 오히려 손을 멈추게 한다.
  String get ctaLabel => '다음';

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

  bool get canGoNext => switch (current?.type) {
    IntroAnswerType.choice => selected.value != null,
    IntroAnswerType.text => draft.value.trim().isNotEmpty,
    null => false,
  };

  /// 선택지를 고른다. **넘어가지는 않는다** — 하단 "다음"이 그 몫이다.
  void choose(String value) => selected.value = value;

  /// 이 문항의 답을 확정하고 다음으로. 마지막이면 목차 생성으로 넘어간다.
  void next() {
    final q = current;
    if (q == null || !canGoNext) return;

    answers[q.id] = q.type == IntroAnswerType.choice
        ? selected.value!
        : answerController.text.trim();

    if (index.value + 1 >= questions.length) {
      Get.offNamed(AppRoutes.tocLoading, arguments: answers);
      return;
    }
    index.value++;
    _restore();
  }

  /// 뒤로 — 첫 질문에서는 화면을 벗어난다.
  void back() {
    // 성함 입력칸에 키보드가 올라와 있을 수 있다. 화면을 옮기기 전에 내린다.
    FocusManager.instance.primaryFocus?.unfocus();
    if (index.value == 0) {
      Get.back();
      return;
    }
    index.value--;
    _restore();
  }

  /// 지금 문항에 이미 답한 게 있으면 화면에 되살린다.
  ///
  /// 앞으로 갈 때도 부른다 — 뒤로 갔다가 다시 앞으로 오면 아까 고른 값이
  /// 그대로 있어야 한다.
  void _restore() {
    final q = current;
    final saved = q == null ? null : answers[q.id];

    if (q?.type == IntroAnswerType.choice) {
      selected.value = saved;
      answerController.clear();
      return;
    }
    selected.value = null;
    answerController.text = saved ?? '';
  }
}
