import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 작성 화면의 단계.
///
/// 시안의 "AI 글 다듬기"(17)와 "직접 고치기"(18)는 **없앴다.**
/// 답변은 사용자가 말하거나 적은 그대로 저장된다.
enum WriteStage {
  /// 13 음성 모드 · 기본
  ask,

  /// 14 음성 모드 · 녹음 중
  recording,

  /// 글자로 입력 — 자기소개(08)와 같은 컴포넌트를 쓴다
  keyboard,

  /// 16 답변 확인 — 받아쓴 원문이 맞는지 (음성 경로에서만 거친다)
  confirm,
}

/// 13~16 작성 — 앱의 핵심 흐름.
///
/// 흐름은 두 갈래다:
///   · 음성   : ask → recording → confirm → 저장 → 다음 질문
///   · 키보드 : ask → keyboard → 저장 → 다음 질문
///
/// 키보드 경로에 확인 단계가 없는 이유: 방금 본인이 타이핑한 글이라
/// "이렇게 들었어요"를 한 번 더 보여줄 이유가 없다.
class WriteController extends GetxController {
  WriteController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  /// 키보드 입력칸
  final answerController = TextEditingController();

  final Rx<WriteStage> stage = WriteStage.ask.obs;

  final Rxn<Question> question = Rxn<Question>();
  final Rxn<Chapter> chapter = Rxn<Chapter>();

  /// 받아쓴 답변 원문(음성 경로). 확인 화면이 이 값을 보여준다.
  final RxString transcript = ''.obs;

  /// 입력칸의 현재 값. `answerController.text`는 Rx가 아니라 Obx가 갱신되지
  /// 않으므로 따로 둔다.
  final RxString draft = ''.obs;

  final RxBool isLoading = true.obs;
  final RxBool isBusy = false.obs;

  /// 녹음 경과 초. 시안 14번의 "0:12".
  final RxInt elapsed = 0.obs;

  /// 모든 장을 끝냈을 때 true — 더 답할 질문이 없다.
  final RxBool isAllDone = false.obs;

  Timer? _tick;
  Timer? _sttTimer;

  @override
  void onInit() {
    super.onInit();
    answerController.addListener(_onDraftChanged);
    load();
  }

  @override
  void onClose() {
    _tick?.cancel();
    _sttTimer?.cancel();
    answerController.removeListener(_onDraftChanged);
    answerController.dispose();
    super.onClose();
  }

  void _onDraftChanged() => draft.value = answerController.text;

  // ── 로딩 ──────────────────────────────────────────────────

  Future<void> load() async {
    isLoading.value = true;
    try {
      final q = await _api.currentQuestion();
      question.value = q;
      isAllDone.value = q == null;
      if (q != null) {
        final chapters = await _api.chapters();
        chapter.value = chapters.firstWhereOrNull((c) => c.id == q.chapterId);
      }
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// "제1장 · 어린 시절"
  String get headerTitle {
    final c = chapter.value;
    return c == null ? '작성' : '제${c.order}장 · ${c.title}';
  }

  /// "질문 3 / 8"
  String get progressLabel {
    final q = question.value;
    final c = chapter.value;
    if (q == null || c == null) return '';
    return '질문 ${q.order} / ${c.questionCount}';
  }

  double get chapterProgress {
    final q = question.value;
    final c = chapter.value;
    if (q == null || c == null || c.questionCount == 0) return 0;
    return (q.order - 1) / c.questionCount;
  }

  // ── 13 · 14 음성 ──────────────────────────────────────────

  void startRecording() {
    stage.value = WriteStage.recording;
    elapsed.value = 0;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => elapsed.value++);

    // 목업: 4초 뒤 받아쓴 결과가 온다.
    // ⚠️ 실제 STT를 붙일 때 바뀌는 유일한 지점이다.
    _sttTimer = Timer(const Duration(seconds: 4), stopRecording);
  }

  Future<void> stopRecording() async {
    if (stage.value != WriteStage.recording) return;
    _tick?.cancel();
    _sttTimer?.cancel();
    isBusy.value = true;
    try {
      transcript.value = await _api.transcribe();
      stage.value = WriteStage.confirm;
    } on ApiException catch (e) {
      _toast.showError(e);
      stage.value = WriteStage.ask;
    } finally {
      isBusy.value = false;
    }
  }

  /// "🔊 다시 들려줘" — 질문을 소리로 읽어준다.
  ///
  /// TTS 패키지를 아직 넣지 않았다. 붙는 자리를 남겨두고 지금은 안내만 띄운다.
  void replayQuestion() =>
      _toast.show('음성 안내는 준비 중이에요', description: '질문은 화면에서 읽으실 수 있어요');

  // ── 키보드 입력 ───────────────────────────────────────────

  /// "키보드로 입력할게요" — 자기소개(08)와 같은 화면으로 넘어간다.
  void useKeyboard() {
    answerController.clear();
    stage.value = WriteStage.keyboard;
  }

  /// 키보드 입력칸의 마이크 — 음성 **대기** 화면으로 되돌린다.
  ///
  /// ⚠️ 여기서 바로 [startRecording]을 부르지 않는다. 마이크를 누른 순간
  ///    녹음이 시작되면 사용자가 말할 준비를 하기 전에 듣기가 시작돼서,
  ///    "누르고 말씀하세요" 화면을 한 번 거치게 한다.
  void micFromKeyboard() {
    answerController.clear();
    stage.value = WriteStage.ask;
  }

  bool get canSubmitTyped => draft.value.trim().isNotEmpty;

  /// 적은 그대로 저장한다. 확인 단계를 거치지 않는다.
  Future<void> submitTyped() => _save(answerController.text.trim());

  // ── 16 답변 확인 ──────────────────────────────────────────

  /// "네, 맞아요" — 받아쓴 원문을 그대로 저장한다.
  Future<void> confirmTranscript() => _save(transcript.value);

  /// "다시 말할게요" → 13번으로 되돌린다.
  void retryAnswer() {
    transcript.value = '';
    stage.value = WriteStage.ask;
  }

  // ── 공통 ──────────────────────────────────────────────────

  Future<void> _save(String text) async {
    final q = question.value;
    if (q == null || text.isEmpty || isBusy.value) return;
    isBusy.value = true;
    try {
      final next = await _api.saveAnswer(questionId: q.id, text: text);
      _toast.show(
        '저장되었습니다.',
        description: next == null ? null : '다음 질문으로 이동합니다.',
      );
      await _moveTo(next);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> skip() async {
    final q = question.value;
    if (q == null || isBusy.value) return;
    isBusy.value = true;
    try {
      await _moveTo(await _api.skipQuestion(q.id));
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isBusy.value = false;
    }
  }

  /// 다음 질문으로 상태를 갈아 끼운다. null이면 전부 끝났다는 뜻이다.
  Future<void> _moveTo(Question? next) async {
    transcript.value = '';
    answerController.clear();
    stage.value = WriteStage.ask;

    question.value = next;
    isAllDone.value = next == null;
    if (next == null) {
      Get.offNamed(AppRoutes.book);
      return;
    }
    // 장이 바뀌었을 수 있으니 다시 읽는다.
    final chapters = await _api.chapters();
    chapter.value = chapters.firstWhereOrNull((c) => c.id == next.chapterId);
  }
}
