import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 작성 화면의 단계.
///
/// 시안의 "AI 글 다듬기"와 "직접 고치기"는 **없앴다.**
/// 답변은 사용자가 말하거나 적은 그대로 저장된다.
enum WriteStage {
  /// D1 음성 모드 · 기본
  ask,

  /// D2 음성 모드 · 녹음 중
  recording,

  /// D3 글자로 입력
  keyboard,

  /// D4 답변 확인 — 받아쓴 원문이 맞는지. 저장에 실패하면 여기 머물며
  /// D5(저장 실패)로 모양만 바뀐다.
  confirm,
}

/// D1~D5 작성 — 앱의 핵심 흐름.
///
/// 어느 쪽으로 답하든 **확인 화면을 한 번 거친다**:
///   · 음성   : ask → recording → confirm → 저장 → 다음 질문
///   · 키보드 : ask → keyboard  → confirm → 저장 → 다음 질문
class WriteController extends GetxController {
  WriteController(this._api, this._speech, this._toast);

  final ApiClient _api;
  final SpeechService _speech;
  final ToastService _toast;

  /// 키보드 입력칸
  final answerController = TextEditingController();

  final Rx<WriteStage> stage = WriteStage.ask.obs;

  final Rxn<Question> question = Rxn<Question>();
  final Rxn<Chapter> chapter = Rxn<Chapter>();

  /// 확인 화면에 보여줄 답변. 음성이면 받아쓴 글, 키보드면 적은 글이다.
  final RxString transcript = ''.obs;

  /// 확인 화면의 답변이 어느 경로로 들어왔는지.
  /// "다시 ~할게요" 버튼이 되돌아갈 곳과 문구를 정한다.
  final Rx<WriteStage> answerSource = WriteStage.recording.obs;

  /// 입력칸의 현재 값. `answerController.text`는 Rx가 아니라 Obx가 갱신되지
  /// 않으므로 따로 둔다.
  final RxString draft = ''.obs;

  final RxBool isLoading = true.obs;
  final RxBool isBusy = false.obs;

  /// 녹음 경과 초. 시안 D2의 "0:23".
  final RxInt elapsed = 0.obs;

  /// 확인 화면에 보여줄 "말한 시간". 저장이 끝나면 0으로 돌아간다.
  final RxInt spokenSeconds = 0.obs;

  /// 저장에 실패했다 — 확인 화면이 D5(저장 실패) 모양으로 바뀐다.
  final RxBool saveFailed = false.obs;

  /// 모든 장을 끝냈을 때 true — 더 답할 질문이 없다.
  final RxBool isAllDone = false.obs;

  Timer? _tick;

  @override
  void onInit() {
    super.onInit();
    answerController.addListener(_onDraftChanged);
    // 인식기가 오류로 멈추면(무음·권한·네트워크) 녹음 화면에 갇히지 않게
    // 대기 화면으로 되돌린다.
    ever(_speech.error, _onSpeechError);
    load();
  }

  void _onSpeechError(String? message) {
    if (message == null) return;
    _speech.error.value = null;
    if (stage.value != WriteStage.recording) return;
    _tick?.cancel();

    // 오류 전까지 알아들은 게 있으면 버리지 않고 확인 화면으로 넘긴다.
    final heard = _speech.partial.value.trim();
    if (heard.isNotEmpty) {
      _onTranscribed(heard);
      return;
    }
    stage.value = WriteStage.ask;
    _toast.show(message, description: '키보드로 입력하실 수 있어요');
  }

  @override
  void onClose() {
    _tick?.cancel();
    _speech.cancel();
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

  /// 확인 화면 캡션 — "약 40초 말씀하셨어요 · 128자" (시안 351:974).
  ///
  /// 키보드로 적었으면 말한 시간이 없으므로 글자 수만 남는다.
  String get answerCaption {
    final chars = '${transcript.value.characters.length}자';
    final seconds = spokenSeconds.value;
    return seconds == 0 ? chars : '약 $seconds초 말씀하셨어요 · $chars';
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

  /// 실제 음성 인식을 시작한다.
  ///
  /// 인식된 글자는 [SpeechService.partial]로 흘러들어와 녹음 화면에 그대로
  /// 보인다. 말이 끝나면(침묵 6초 또는 "멈춤") 확인 화면으로 넘어간다.
  Future<void> startRecording() async {
    stage.value = WriteStage.recording;
    elapsed.value = 0;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => elapsed.value++);

    final started = await _speech.start(onFinal: _onTranscribed);
    if (!started) {
      // 권한 거부·인식기 없음 — 음성으로는 진행할 수 없으니 되돌리고
      // 키보드로 안내한다. 버튼만 눌리고 아무 일도 없는 상태를 만들지 않는다.
      _tick?.cancel();
      stage.value = WriteStage.ask;
      _toast.show(
        _speech.error.value ?? '음성 인식을 쓸 수 없어요',
        description: '키보드로 입력하실 수 있어요',
      );
      _speech.error.value = null;
    }
  }

  /// 인식이 끝났다. 받아쓴 글을 확인 화면으로 넘긴다.
  void _onTranscribed(String text) {
    _tick?.cancel();
    answerSource.value = WriteStage.recording;
    transcript.value = text;
    spokenSeconds.value = elapsed.value;
    saveFailed.value = false;
    stage.value = WriteStage.confirm;
  }

  /// "멈춤" — 지금까지 인식된 내용으로 마무리한다.
  Future<void> stopRecording() async {
    if (stage.value != WriteStage.recording) return;
    _tick?.cancel();
    await _speech.stop();

    // stop() 뒤에도 최종 결과가 곧 도착하는 게 정상이다. 다만 한 마디도
    // 못 알아들은 경우엔 콜백이 오지 않으므로 여기서 되돌린다.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (stage.value != WriteStage.recording) return;

    final heard = _speech.partial.value.trim();
    if (heard.isEmpty) {
      stage.value = WriteStage.ask;
      _toast.show('말씀을 알아듣지 못했어요', description: '다시 한 번 말씀해 주세요');
      return;
    }
    _onTranscribed(heard);
  }

  /// 녹음 화면에 실시간으로 뜨는 인식 결과.
  String get liveTranscript => _speech.partial.value;

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

  /// 적은 글도 확인 화면을 거친다 — 음성과 같은 흐름으로 맞춘 것이다.
  void submitTyped() {
    final text = answerController.text.trim();
    if (text.isEmpty) return;
    answerSource.value = WriteStage.keyboard;
    transcript.value = text;
    // 적은 글에는 "말한 시간"이 없다.
    spokenSeconds.value = 0;
    saveFailed.value = false;
    stage.value = WriteStage.confirm;
  }

  // ── D4 답변 확인 · D5 저장 실패 ────────────────────────────

  /// "저장하고 다음 질문" / (실패 후) "다시 저장하기"
  Future<void> confirmTranscript() => _save(transcript.value);

  /// 주 버튼 문구. 한 번 실패했으면 재시도라는 걸 문구로 알린다.
  String get saveLabel => saveFailed.value ? '다시 저장하기' : '저장하고 다음 질문';

  /// 화면 제목 — 실패했으면 "정리는 마쳤어요 / 저장만 남았어요"로 바뀐다.
  /// 글은 살아 있다는 걸 제목에서부터 알려야 사용자가 다시 말하지 않는다.
  String get confirmTitle => saveFailed.value ? '정리는 마쳤어요' : '이렇게 정리했어요';

  String get confirmSubtitle =>
      saveFailed.value ? '저장만 남았어요' : '고치고 싶은 곳을 눌러 바꿀 수 있어요';

  /// 되돌리기 버튼 문구. 들어온 경로에 따라 다르다.
  String get retryLabel =>
      answerSource.value == WriteStage.keyboard ? '다시 쓰기' : '다시 말하기';

  /// 되돌리기 — 온 길로 돌려보낸다.
  /// 키보드로 적었으면 적은 글을 그대로 두고 입력칸으로 돌아간다.
  void retryAnswer() {
    saveFailed.value = false;
    if (answerSource.value == WriteStage.keyboard) {
      answerController.text = transcript.value;
      transcript.value = '';
      stage.value = WriteStage.keyboard;
      return;
    }
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
      saveFailed.value = false;
      _toast.show(
        '저장되었습니다.',
        description: next == null ? null : '다음 질문으로 이동합니다.',
      );
      await _moveTo(next);
    } on ApiException {
      // ⚠️ 토스트로 알리지 않는다. 몇 초 뒤 사라지는 안내로는 "내 이야기가
      //    날아갔나"라는 걱정을 지울 수 없다. 확인 화면에 그대로 머물면서
      //    D5(저장 실패) 안내 박스를 띄우고, 글은 화면에 남겨 둔다.
      saveFailed.value = true;
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
    spokenSeconds.value = 0;
    saveFailed.value = false;
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
