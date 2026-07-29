import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 작성 화면의 단계 — 시안 13~18번이 각각 하나씩 대응한다.
enum WriteStage {
  /// 13 음성 모드 · 기본
  ask,

  /// 14 음성 모드 · 녹음 중
  recording,

  /// 15 채팅 모드 (글자 입력)
  chat,

  /// 16 답변 확인 — 받아쓴 원문이 맞는지
  confirm,

  /// 17 AI 글 다듬기 결과
  polish,

  /// 18 직접 고치기
  edit,
}

/// 13~18 작성 — 앱의 핵심 흐름.
///
/// 한 컨트롤러가 여섯 단계를 모두 들고 있다. 단계마다 라우트를 따로 두면
/// 질문·원문·다듬은 글을 계속 넘겨야 하고, 뒤로가기 동작도 단계마다
/// 달라져야 해서 한 화면 안에서 [stage]로 전환한다.
class WriteController extends GetxController {
  WriteController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final chatController = TextEditingController();
  final editController = TextEditingController();

  final Rx<WriteStage> stage = WriteStage.ask.obs;

  final Rxn<Question> question = Rxn<Question>();
  final Rxn<Chapter> chapter = Rxn<Chapter>();
  final Rxn<AnswerDraft> draft = Rxn<AnswerDraft>();
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

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
    load();
  }

  @override
  void onClose() {
    _tick?.cancel();
    _sttTimer?.cancel();
    chatController.dispose();
    editController.dispose();
    super.onClose();
  }

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
      final text = await _api.transcribe();
      draft.value = AnswerDraft(
        questionId: question.value!.id,
        transcript: text,
        polished: '',
      );
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

  /// 15 채팅 모드로 전환 — "글자로 입력할게요"
  Future<void> useChat() async {
    final q = question.value;
    if (q == null) return;
    stage.value = WriteStage.chat;
    try {
      messages.value = await _api.chatHistory(q.id);
    } on ApiException catch (e) {
      _toast.showError(e);
    }
  }

  void backToAsk() => stage.value = WriteStage.ask;

  // ── 15 채팅 ───────────────────────────────────────────────

  Future<void> sendChat() async {
    final text = chatController.text.trim();
    final q = question.value;
    if (text.isEmpty || q == null || isBusy.value) return;

    chatController.clear();
    messages.add(
      ChatMessage(
        id: 'local-${messages.length}',
        role: ChatRole.user,
        text: text,
      ),
    );
    isBusy.value = true;
    try {
      draft.value = await _api.submitAnswer(questionId: q.id, transcript: text);
      stage.value = WriteStage.polish;
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isBusy.value = false;
    }
  }

  /// 채팅 입력줄의 마이크 — 음성 모드로 되돌린다.
  void micFromChat() {
    stage.value = WriteStage.ask;
    startRecording();
  }

  // ── 16 답변 확인 ──────────────────────────────────────────

  /// "네, 맞아요" → AI 다듬기로 넘어간다.
  Future<void> confirmTranscript() async {
    final d = draft.value;
    if (d == null || isBusy.value) return;
    isBusy.value = true;
    try {
      draft.value = await _api.submitAnswer(
        questionId: d.questionId,
        transcript: d.transcript,
      );
      stage.value = WriteStage.polish;
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isBusy.value = false;
    }
  }

  /// "다시 말할게요" → 13번으로 되돌린다.
  void retryAnswer() {
    draft.value = null;
    stage.value = WriteStage.ask;
  }

  // ── 17 AI 글 다듬기 ───────────────────────────────────────

  Future<void> repolish() async {
    final d = draft.value;
    if (d == null || isBusy.value) return;
    isBusy.value = true;
    try {
      draft.value = await _api.repolish(d);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isBusy.value = false;
    }
  }

  void startEditing() {
    editController.text = draft.value?.polished ?? '';
    stage.value = WriteStage.edit;
  }

  /// "좋아요, 다음 질문" — 확정 저장.
  Future<void> save([String? overrideText]) async {
    final d = draft.value;
    if (d == null || isBusy.value) return;
    isBusy.value = true;
    try {
      final next = await _api.saveAnswer(
        questionId: d.questionId,
        text: overrideText ?? d.polished,
      );
      _toast.show(
        '저장되었습니다.',
        description: next == null ? null : '다음 질문으로 이동합니다.',
      );
      _moveTo(next);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isBusy.value = false;
    }
  }

  // ── 18 직접 고치기 ────────────────────────────────────────

  void cancelEditing() => stage.value = WriteStage.polish;

  Future<void> saveEdited() => save(editController.text.trim());

  // ── 공통 ──────────────────────────────────────────────────

  Future<void> skip() async {
    final q = question.value;
    if (q == null || isBusy.value) return;
    isBusy.value = true;
    try {
      _moveTo(await _api.skipQuestion(q.id));
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isBusy.value = false;
    }
  }

  /// 다음 질문으로 상태를 갈아 끼운다. null이면 전부 끝났다는 뜻이다.
  Future<void> _moveTo(Question? next) async {
    draft.value = null;
    messages.clear();
    chatController.clear();
    editController.clear();
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
