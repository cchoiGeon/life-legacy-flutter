import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/purchase/purchase_flow.dart';
import 'package:life_legacy/service/services.dart';

/// 작성 화면의 단계.
///
/// 시안의 "AI 글 다듬기"와 "직접 고치기"는 **없앴다.** 다듬기는 서버가 하고,
/// 그 결과를 작성 화면에서는 보여주지 않는다 — 사용자 눈에 남는 건 자기가
/// 말하거나 적은 원문뿐이다.
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

  /// D6 꼬리질문을 만드는 중. 서버가 AI를 부르느라 30초까지 걸린다.
  generatingFollowup,

  /// D7 이야기를 정리하는 중(윤문). 최대 60초.
  saving,

  /// D8 꼬리질문을 만들지 못했다 — 이 질문을 처음부터 다시 답해야 한다.
  followupFailed,
}

/// D1~D8 작성 — 앱의 핵심 흐름.
///
/// 질문 하나에 **1차 + 꼬리(최대 2회) 답하고 한 번 저장한다**:
///
///   질문 → 1차 → followup → … → (마지막 꼬리) → 윤문·저장 → 다음 질문
///
/// 앱은 횟수를 세지 않는다. 서버가 `followup`을 주면 한 번 더, `next_question`이면 확정.
/// 같은 화면을 쓴다([isFollowup]로 갈린다) — 시니어 사용자가 배워야
/// 할 화면을 늘리지 않으려는 것이다. 꼬리질문일 때는 질문판에 AI가 만든
/// 긴 글이 들어가고, 글자와 판 높이가 그에 맞게 바뀐다.
///
/// 어느 쪽으로 답하든 **확인 화면을 한 번 거친다**:
///   · 음성   : ask → recording → confirm → …
///   · 키보드 : ask → keyboard  → confirm → …
class WriteController extends GetxController {
  WriteController(this._api, this._speech, this._toast, this._voice);

  final ApiClient _api;
  final SpeechService _speech;
  final ToastService _toast;
  final VoicePlayerService _voice;

  /// 키보드 입력칸
  final answerController = TextEditingController();

  final Rx<WriteStage> stage = WriteStage.ask.obs;

  final Rxn<Question> question = Rxn<Question>();
  final Rxn<Chapter> chapter = Rxn<Chapter>();

  /// 지금 화면이 **꼬리질문**을 묻고 있는지.
  ///
  /// 1차 답변과 꼬리답변이 같은 화면을 쓰기 때문에, 무엇을 묻고 있고 답이
  /// 어디로 갈지는 이 값 하나가 정한다.
  final RxBool isFollowup = false.obs;

  /// AI가 되물어 온 질문. [isFollowup]이 true일 때만 채워져 있다.
  final Rxn<Followup> followup = Rxn<Followup>();

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

  /// 일시정지 중인지. 메인 원형 버튼은 여전히 "끝내기"다.
  final RxBool isPaused = false.obs;

  /// 확인 화면에 보여줄 "말한 시간". 저장이 끝나면 0으로 돌아간다.
  final RxInt spokenSeconds = 0.obs;

  /// 저장에 실패했다 — 확인 화면이 D5(저장 실패) 모양으로 바뀐다.
  final RxBool saveFailed = false.obs;

  /// 서버 STT 대기 중 — saving 스테이지이지만 문구만 다르게.
  final RxBool isTranscribing = false.obs;

  /// 모든 장을 끝냈을 때 true — 더 답할 질문이 없다.
  final RxBool isAllDone = false.obs;

  /// 방금 한 장을 끝냈을 때. [_pendingNext]를 이어서 불러온다.
  final RxBool isChapterComplete = false.obs;
  final Rxn<Chapter> completedChapter = Rxn<Chapter>();
  final Rxn<ChapterCompletion> chapterCompletion = Rxn<ChapterCompletion>();

  /// 작성 진입마다 보이는 보이스·마이크 점검 오버레이 (§5.8).
  final RxBool showVoiceCheck = false.obs;
  final RxBool isPlayingSample = false.obs;
  final RxnString voiceSampleError = RxnString();
  final RxBool voiceHeardOk = false.obs;

  final RxBool isMicTesting = false.obs;
  final RxnBool micPermissionOk = RxnBool();
  final RxnString micTestResult = RxnString();
  final RxnString micTestError = RxnString();

  /// 작성 튜토리얼 오버레이.
  final RxBool showTutorial = false.obs;
  final RxInt tutorialStep = 0.obs;

  /// 각 단계가 가리킬 위젯(질문·마이크·타이핑·더보기/건너뛰기).
  final tutorialQuestionKey = GlobalKey();
  final tutorialMicKey = GlobalKey();
  final tutorialTypingKey = GlobalKey();
  final tutorialSkipKey = GlobalKey();

  /// 현재 단계 타깃의 화면 좌표. 오버레이가 하이라이트·다이얼로그 위치를 잡는다.
  final Rxn<Rect> tutorialTargetRect = Rxn<Rect>();

  /// 질문판에 지금 보이는 글 — 첫 표시 때 한글자씩 채워진다.
  final RxString revealedQuestion = ''.obs;

  /// TTS+타이핑 진행 중인지. 녹음/키보드로 넘어가면 전문을 바로 연다.
  final RxBool isRevealingQuestion = false.obs;

  static const tutorialSteps = [
    ('질문을 읽어요', '화면의 질문을 소리로도 들을 수 있어요'),
    ('말씀으로 답해요', '가운데 마이크를 누르고 편하게 이야기하세요'),
    ('글로도 적을 수 있어요', '아래 “글로 답하기”를 눌러 보세요'),
    ('건너뛸 수도 있어요', '오른쪽 위 ⋯ 메뉴에서 이 질문을 건너뛸 수 있어요'),
  ];

  List<GlobalKey> get tutorialKeys => [
        tutorialQuestionKey,
        tutorialMicKey,
        tutorialTypingKey,
        tutorialSkipKey,
      ];

  GlobalKey get currentTutorialKey =>
      tutorialKeys[tutorialStep.value.clamp(0, tutorialKeys.length - 1)];

  String? _bookId;

  /// 1차 답 원문 — 꼬리질문 화면의 "다시 답하기/추가하기"에 쓴다.
  String? _firstAnswerText;

  Question? _pendingNext;
  Timer? _tick;
  Timer? _revealTick;
  Completer<void>? _revealDone;

  /// 같은 질문에 대해 TTS+타이핑을 이미 돌렸는지.
  String? _presentedKey;

  /// 타이핑 세대 — 새 present가 오면 이전 타이머/비동기를 무시한다.
  int _revealGen = 0;

  bool get hasPendingNext => _pendingNext != null;

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

    // 진입 점검 중이면 작성 흐름을 건드리지 않는다.
    if (showVoiceCheck.value) {
      isMicTesting.value = false;
      micTestError.value = message;
      if (message.contains('권한')) micPermissionOk.value = false;
      return;
    }

    if (stage.value != WriteStage.recording) return;
    _tick?.cancel();
    isPaused.value = false;

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
    _cancelReveal();
    _speech.cancel();
    _voice.stop();
    answerController.removeListener(_onDraftChanged);
    answerController.dispose();
    super.onClose();
  }

  void _onDraftChanged() => draft.value = answerController.text;

  // ── 로딩 ──────────────────────────────────────────────────

  Future<void> load() async {
    isLoading.value = true;
    try {
      final bookId = await _resolveBookId();
      final args = Get.arguments;
      Question? q;
      if (args is Map && args['questionId'] is String) {
        q = await _api.question(args['questionId'] as String);
      } else {
        q = await _api.currentQuestion(bookId);
      }
      question.value = q;
      isAllDone.value = q == null;
      if (q != null) {
        final chapters = await _api.chapters(bookId);
        chapter.value = chapters.firstWhereOrNull((c) => c.id == q!.chapterId);
        await _restoreDraft(q.id);
        // 작성에 들어올 때마다 소리·마이크를 먼저 확인한다.
        // 튜토리얼은 점검을 닫은 뒤에 이어서 연다.
        _resetVoiceCheck();
        showVoiceCheck.value = true;
      }
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _resetVoiceCheck() {
    isPlayingSample.value = false;
    voiceSampleError.value = null;
    voiceHeardOk.value = false;
    isMicTesting.value = false;
    micPermissionOk.value = null;
    micTestResult.value = null;
    micTestError.value = null;
  }

  /// 스피커 볼륨(0~1). 점검·질문 TTS에 공통 적용.
  RxDouble get voiceVolume => _voice.volume;

  Future<void> setVoiceVolume(double value) => _voice.setVolume(value);

  /// 보이스 샘플 재생 — 소리가 나는지·볼륨이 맞는지 확인한다.
  Future<void> playVoiceSample() async {
    if (isPlayingSample.value) return;
    isPlayingSample.value = true;
    voiceSampleError.value = null;
    try {
      await _voice.setVolume(voiceVolume.value);
      final audio = await _api.voiceSample();
      if (audio.bytes.isEmpty) {
        voiceSampleError.value = '샘플 음성을 받지 못했어요. 음량을 확인해 주세요';
        return;
      }
      await _voice.playMpeg(audio.bytes);
      voiceHeardOk.value = true;
    } on ApiException catch (e) {
      voiceSampleError.value = e.message;
    } on Exception {
      voiceSampleError.value = '재생에 실패했어요. 음량·출력 장치를 확인해 주세요';
    } finally {
      isPlayingSample.value = false;
    }
  }

  Future<void> stopVoiceSample() => _voice.stop();

  /// 마이크 권한 + 짧은 로컬 STT 테스트.
  Future<void> startMicTest() async {
    if (isMicTesting.value) return;
    micTestError.value = null;
    micTestResult.value = null;

    if (_speech.available.value != true) {
      await _speech.init();
    }
    if (_speech.available.value != true) {
      micPermissionOk.value = false;
      micTestError.value =
          _speech.error.value ?? '이 기기에서는 음성 인식을 쓸 수 없어요';
      _speech.error.value = null;
      return;
    }

    micPermissionOk.value = true;
    isMicTesting.value = true;
    final started = await _speech.start(
      onFinal: (text) {
        isMicTesting.value = false;
        micTestResult.value = text;
      },
    );
    if (!started) {
      isMicTesting.value = false;
      micPermissionOk.value = false;
      micTestError.value =
          _speech.error.value ?? '마이크를 켤 수 없어요';
      _speech.error.value = null;
    }
  }

  Future<void> stopMicTest() async {
    if (!isMicTesting.value && !showVoiceCheck.value) return;
    await _speech.stop();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    isMicTesting.value = false;
    final heard = _speech.partial.value.trim();
    if (heard.isNotEmpty) micTestResult.value = heard;
  }

  /// 점검 중 화면에 보여줄 실시간 인식 글.
  String get micTestLive =>
      micTestResult.value ?? _speech.partial.value;

  /// 점검 종료 후 작성(또는 타이핑)으로 넘어간다.
  Future<void> dismissVoiceCheck({bool preferTyping = false}) async {
    await stopMicTest();
    await stopVoiceSample();
    showVoiceCheck.value = false;

    if (preferTyping) {
      showFullQuestion();
      useKeyboard();
      return;
    }

    if (!Storage.writeTutorialDone &&
        question.value != null &&
        !isFollowup.value &&
        stage.value == WriteStage.ask) {
      // 튜토리얼 동안은 전문을 보여 주고, 끝나면 TTS+타이핑을 돌린다.
      showFullQuestion();
      showTutorial.value = true;
      tutorialStep.value = 0;
      scheduleTutorialTargetRefresh();
      return;
    }

    await presentQuestion();
  }

  Future<void> _restoreDraft(String questionId) async {
    try {
      final draft = await _api.answerDraft(questionId);
      if (draft == null) return;
      _firstAnswerText = draft.text;
      if (draft.isFollowupPhase && draft.pendingFollowup != null) {
        followup.value = draft.pendingFollowup;
        isFollowup.value = true;
        stage.value = WriteStage.ask;
        return;
      }
      // 1차 초안 — 확인 화면 생략, 바로 이어서 저장/다음
      transcript.value = draft.text;
      spokenSeconds.value = draft.spokenSeconds ?? 0;
      answerSource.value = draft.inputMode == ComposeMode.keyboard
          ? WriteStage.keyboard
          : WriteStage.recording;
      // stage.value = WriteStage.confirm; // TODO: 확인 화면 복구 시 주석 해제
      await _save(draft.text);
    } on ApiException {
      // 복원 실패해도 작성은 이어간다
    }
  }

  Future<void> _autosaveDraft(String text) async {
    final q = question.value;
    if (q == null || text.trim().isEmpty || isFollowup.value) return;
    try {
      await _api.saveAnswerDraft(
        questionId: q.id,
        text: text,
        inputMode: _inputMode,
        spokenSeconds: _spokenSecondsOrNull,
      );
    } on ApiException {
      // autosave 실패는 조용히 — 확정 저장이 본 경로다
    }
  }

  /// 꼬리질문 단계에서 1차를 처음부터 다시.
  Future<void> redoFirstAnswer() async {
    final q = question.value;
    if (q == null || !isFollowup.value) return;
    try {
      await _api.deleteAnswerDraft(q.id);
    } on ApiException {
      // 없어도 진행
    }
    _firstAnswerText = null;
    followup.value = null;
    isFollowup.value = false;
    _clearInput();
    stage.value = WriteStage.ask;
    await presentQuestion();
  }

  /// 꼬리질문 단계에서 1차 원문을 이어 쓰기.
  Future<void> appendToFirstAnswer() async {
    if (!isFollowup.value) return;
    final prior = _firstAnswerText ?? '';
    try {
      final q = question.value;
      if (q != null) await _api.deleteAnswerDraft(q.id);
    } on ApiException {
      // ignore
    }
    followup.value = null;
    isFollowup.value = false;
    showFullQuestion();
    answerController.text = prior.isEmpty ? '' : '$prior\n';
    draft.value = answerController.text;
    answerSource.value = WriteStage.keyboard;
    stage.value = WriteStage.keyboard;
  }

  Future<String> _resolveBookId() async {
    final fromArgs = Get.arguments;
    if (fromArgs is Map && fromArgs['bookId'] is String) {
      final id = fromArgs['bookId'] as String;
      await Storage.saveCurrentBookId(id);
      _bookId = id;
      return id;
    }
    final stored = Storage.currentBookId;
    if (stored != null) {
      _bookId = stored;
      return stored;
    }
    throw const ApiException('책을 선택해 주세요');
  }

  String _requireBookId() {
    final id = _bookId ?? Storage.currentBookId;
    if (id != null) return id;
    throw const ApiException('책을 선택해 주세요');
  }

  /// 미확정 입력이 있으면 true — 이탈 경고 대상.
  bool get hasUnsavedInput {
    if (isBusy.value) return true;
    return switch (stage.value) {
      WriteStage.recording => true,
      WriteStage.keyboard => draft.value.trim().isNotEmpty,
      WriteStage.confirm => transcript.value.trim().isNotEmpty,
      WriteStage.generatingFollowup || WriteStage.saving => true,
      _ => false,
    };
  }

  Future<void> requestLeave() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final ctx = Get.context;
    if (ctx == null) {
      _leaveToHome();
      return;
    }
    // 왼쪽 `홈으로 가기`, 오른쪽 강조 `계속하기`.
    // AppDialog는 왼쪽=cancel·오른쪽=confirm.
    final stay = await AppDialog.confirm(
      ctx,
      title: '작성을 나갈까요?',
      message: hasUnsavedInput
          ? '입력된 내용이 지워질 수 있습니다'
          : '작성 화면을 떠나면 홈으로 이동합니다',
      cancelLabel: '홈으로 가기',
      confirmLabel: '계속하기',
    );
    if (!stay) _leaveToHome();
  }

  void _leaveToHome() {
    Get.offNamed(
      AppRoutes.home,
      arguments: {'bookId': _requireBookId()},
    );
  }

  void nextTutorial() {
    if (tutorialStep.value + 1 >= tutorialSteps.length) {
      finishTutorial();
      return;
    }
    tutorialStep.value++;
    scheduleTutorialTargetRefresh();
  }

  void prevTutorial() {
    if (tutorialStep.value > 0) {
      tutorialStep.value--;
      scheduleTutorialTargetRefresh();
    }
  }

  Future<void> finishTutorial() async {
    showTutorial.value = false;
    tutorialTargetRect.value = null;
    await Storage.markWriteTutorialDone();
    await presentQuestion();
  }

  /// 레이아웃이 끝난 뒤 타깃 위젯의 화면 Rect를 갱신한다.
  void scheduleTutorialTargetRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!showTutorial.value) return;
      final ctx = currentTutorialKey.currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize || !box.attached) {
        tutorialTargetRect.value = null;
        return;
      }
      final offset = box.localToGlobal(Offset.zero);
      tutorialTargetRect.value = offset & box.size;
    });
  }

  /// 질문판에 들어갈 글. 1차면 원래 질문, 꼬리질문이면 AI가 만든 글이다.
  String get displayQuestion => isFollowup.value
      ? followup.value?.text ?? ''
      : question.value?.text ?? '';

  String get _presentationKey {
    if (isFollowup.value) {
      final id = followup.value?.id;
      return id != null ? 'f:$id' : 'f:${followup.value?.text.hashCode}';
    }
    return 'q:${question.value?.id ?? ''}';
  }

  /// 새 소질문·꼬리질문의 **첫 표시** — TTS와 한글 타이핑을 맞춘다.
  ///
  /// `다시 들려주기`는 [replayQuestion]만 쓰고 여기를 부르지 않는다.
  Future<void> presentQuestion({bool animate = true}) async {
    final full = displayQuestion;
    if (full.trim().isEmpty) {
      _cancelReveal();
      revealedQuestion.value = '';
      return;
    }

    final key = _presentationKey;
    if (!animate) {
      _presentedKey = key;
      showFullQuestion();
      return;
    }

    // 같은 키로 이미 한 번 돌렸고 전문이 보이면 다시 돌리지 않는다.
    if (_presentedKey == key &&
        revealedQuestion.value == full &&
        !isRevealingQuestion.value) {
      return;
    }
    _presentedKey = key;
    await _revealWithTts(full);
  }

  /// 타이핑을 끊고 전문을 바로 연다 (녹음·키보드·다시듣기).
  void showFullQuestion() {
    _cancelReveal();
    revealedQuestion.value = displayQuestion;
  }

  void _cancelReveal() {
    _revealTick?.cancel();
    _revealTick = null;
    isRevealingQuestion.value = false;
    _revealGen++;
    final done = _revealDone;
    _revealDone = null;
    if (done != null && !done.isCompleted) done.complete();
  }

  Future<void> _revealWithTts(String full) async {
    // 이전 타이핑 대기를 풀어 주고 새 세대로 시작한다.
    final prevDone = _revealDone;
    _revealDone = null;
    if (prevDone != null && !prevDone.isCompleted) prevDone.complete();
    _revealTick?.cancel();
    _revealTick = null;

    final gen = ++_revealGen;
    revealedQuestion.value = '';
    isRevealingQuestion.value = true;

    final graphemes = full.characters.toList();
    if (graphemes.isEmpty) {
      isRevealingQuestion.value = false;
      return;
    }

    List<int>? bytes;
    int? headerMs;
    try {
      final audio = await _api.synthesizeSpeech(text: full);
      if (gen != _revealGen) return;
      bytes = audio.bytes;
      headerMs = audio.durationMs;
    } on Object {
      // TTS가 없어도 타이핑은 진행한다.
    }

    if (gen != _revealGen) return;

    // 헤더가 없으면 한글 낭독 속도(~7자/초)로 근사한다.
    final totalMs = (headerMs != null && headerMs > 0)
        ? headerMs
        : (graphemes.length * 140).clamp(900, 16000);

    final ttsFuture = (bytes != null && bytes.isNotEmpty)
        ? _voice.playMpeg(bytes).then((_) {}, onError: (_, __) {})
        : Future<void>.value();

    final started = DateTime.now();
    final done = Completer<void>();
    _revealDone = done;
    _revealTick = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (gen != _revealGen) {
        timer.cancel();
        if (!done.isCompleted) done.complete();
        return;
      }
      final elapsed = DateTime.now().difference(started).inMilliseconds;
      final count = ((elapsed / totalMs) * graphemes.length)
          .ceil()
          .clamp(0, graphemes.length);
      revealedQuestion.value = graphemes.take(count).join();
      if (count >= graphemes.length) {
        timer.cancel();
        _revealTick = null;
        isRevealingQuestion.value = false;
        if (!done.isCompleted) done.complete();
      }
    });

    await Future.wait<void>([done.future, ttsFuture]);
    if (_revealDone == done) _revealDone = null;
    if (gen != _revealGen) return;
    revealedQuestion.value = full;
    isRevealingQuestion.value = false;
  }

  /// 로딩 화면(D6·D7) 제목.
  ///
  /// 두 대기가 성격이 다르다 — 앞은 되물을 말을 고르는 중이고, 뒤는 이미
  /// 받은 이야기를 글로 옮기는 중이다. 같은 문구를 쓰면 사용자는 방금과
  /// 똑같은 화면이 다시 떴다고 읽는다.
  String get loadingTitle {
    if (isTranscribing.value) return '말씀을 글로 옮기고 있어요';
    return stage.value == WriteStage.saving
        ? '이야기를 정리하고 있어요'
        : '말씀을 듣고 있어요';
  }

  /// 줄바꿈은 시안(398:16 · 398:40)이 끊어 놓은 자리다.
  String get loadingSubtitle {
    if (isTranscribing.value) return '잠시만\n기다려 주세요';
    return stage.value == WriteStage.saving
        ? '잠시만\n기다려 주세요'
        : '조금만 더\n여쭤볼게요';
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

  /// 단말 로컬 STT(speech_to_text)를 시작한다.
  Future<void> startRecording() async {
    showFullQuestion();
    await _voice.stop();
    stage.value = WriteStage.recording;
    isPaused.value = false;
    elapsed.value = 0;
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isPaused.value) elapsed.value++;
    });

    final started = await _speech.start(onFinal: _onTranscribed);
    if (!started) {
      _tick?.cancel();
      stage.value = WriteStage.ask;
      _toast.show(
        _speech.error.value ?? '음성 인식을 쓸 수 없어요',
        description: '키보드로 입력하실 수 있어요',
      );
      _speech.error.value = null;
    }
  }

  /// 인식이 끝났다. 확인 화면(이렇게 정리했어요)은 일시 생략하고 바로 저장/다음.
  void _onTranscribed(String text) {
    _tick?.cancel();
    isPaused.value = false;
    answerSource.value = WriteStage.recording;
    transcript.value = text;
    spokenSeconds.value = elapsed.value;
    saveFailed.value = false;
    // stage.value = WriteStage.confirm; // TODO: 확인 화면 복구 시 주석 해제
    _autosaveDraft(text);
    _save(text);
  }

  /// 일시정지 — 메인 "끝내기"와 별도. 글은 유지하고 듣기만 멈춘다.
  Future<void> pauseRecording() async {
    if (stage.value != WriteStage.recording || isPaused.value) return;
    await _speech.pause();
    isPaused.value = true;
  }

  /// 일시정지 후 이어서 말하기.
  Future<void> resumeRecording() async {
    if (stage.value != WriteStage.recording || !isPaused.value) return;
    isPaused.value = false;
    final started = await _speech.resume(onFinal: _onTranscribed);
    if (!started) {
      isPaused.value = true;
      _toast.show(
        _speech.error.value ?? '이어서 듣지 못했어요',
        description: '다시 시도하거나 끝내기를 눌러 주세요',
      );
      _speech.error.value = null;
    }
  }

  /// "끝내기" — 지금까지 단말에서 인식된 내용으로 마무리한다.
  Future<void> stopRecording() async {
    if (stage.value != WriteStage.recording) return;
    _tick?.cancel();
    final wasPaused = isPaused.value;
    isPaused.value = false;

    if (!wasPaused) {
      await _speech.stop();
      // stop() 뒤에도 최종 결과가 곧 도착하는 게 정상이다. 다만 한 마디도
      // 못 알아들은 경우엔 콜백이 오지 않으므로 여기서 되돌린다.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (stage.value != WriteStage.recording) return;
    }

    final heard = _speech.partial.value.trim();
    if (heard.isEmpty) {
      stage.value = WriteStage.ask;
      _toast.show('말씀을 알아듣지 못했어요', description: '다시 한 번 말씀해 주세요');
      return;
    }
    _onTranscribed(heard);

    // --- 서버 Clova STT (로컬 개발 중 비활성) ---
    // final captured = await _speech.stopToAudio();
    // if (captured == null) {
    //   stage.value = WriteStage.ask;
    //   _toast.show('말씀을 알아듣지 못했어요', description: '다시 한 번 말씀해 주세요');
    //   return;
    // }
    // stage.value = WriteStage.saving;
    // isTranscribing.value = true;
    // try {
    //   final result = await _api.transcribeAudio(
    //     bytes: captured.bytes,
    //     filename: captured.filename,
    //     durationMs: captured.durationMs,
    //   );
    //   ...
    // } on ApiException catch (e) {
    //   stage.value = WriteStage.ask;
    //   _toast.showError(e);
    // } finally {
    //   isTranscribing.value = false;
    // }
  }

  /// 녹음 화면에 뜨는 안내/부분 결과.
  String get liveTranscript => _speech.partial.value;

  /// "🔊 다시 들려줘" — TTS만 다시 재생한다. 타이핑 애니는 돌리지 않는다.
  Future<void> replayQuestion() async {
    final text = displayQuestion.trim();
    if (text.isEmpty) return;
    showFullQuestion();
    try {
      final audio = await _api.synthesizeSpeech(text: text);
      await _voice.playMpeg(audio.bytes);
    } on ApiException catch (e) {
      _toast.showError(e);
    } on Exception {
      _toast.show('음성을 재생하지 못했어요', description: '질문은 화면에서 읽으실 수 있어요');
    }
  }

  // ── 키보드 입력 ───────────────────────────────────────────

  /// "키보드로 입력할게요" — 자기소개(08)와 같은 화면으로 넘어간다.
  void useKeyboard() {
    showFullQuestion();
    _tick?.cancel();
    isPaused.value = false;
    _speech.cancel();
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
    // 이미 본 질문이므로 애니는 생략하고 전문만 연다.
    presentQuestion(animate: false);
  }

  bool get canSubmitTyped => draft.value.trim().isNotEmpty;

  /// 적은 글도 확인 화면을 거치지 않고 바로 저장/다음. (확인 UI 일시 생략)
  void submitTyped() {
    final text = answerController.text.trim();
    if (text.isEmpty) return;
    answerSource.value = WriteStage.keyboard;
    transcript.value = text;
    // 적은 글에는 "말한 시간"이 없다.
    spokenSeconds.value = 0;
    saveFailed.value = false;
    // stage.value = WriteStage.confirm; // TODO: 확인 화면 복구 시 주석 해제
    _autosaveDraft(text);
    _save(text);
  }

  // ── D4 답변 확인 · D5 저장 실패 ────────────────────────────

  /// "저장하고 다음 질문" / (실패 후) "다시 저장하기"
  Future<void> confirmTranscript() => _save(transcript.value);

  /// 주 버튼 문구.
  ///
  /// ⚠️ 1차 답변에서는 **"저장"이라고 말하지 않는다.** 그 버튼을 눌러도
  ///    저장되지 않고 다음 질문으로도 가지 않는다 — 꼬리질문이 하나 더 뜬다.
  ///    실제로 저장이 일어나는 건 꼬리답변을 보낼 때뿐이다.
  String get saveLabel {
    if (saveFailed.value) return '다시 저장하기';
    // 중간 라운드인지 마지막인지 앱은 모른다 — "다음 질문"을 약속하지 않는다.
    return isFollowup.value ? '답 보내기' : '이어서 답하기';
  }

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

  /// 답변이 들어온 경로. 서버에 함께 보낸다.
  ComposeMode get _inputMode => answerSource.value == WriteStage.keyboard
      ? ComposeMode.keyboard
      : ComposeMode.voice;

  /// 적은 글에는 "말한 시간"이 없다. 0을 보내면 "0초 말했다"로 읽히므로
  /// 아예 빼서 보낸다.
  int? get _spokenSecondsOrNull =>
      _inputMode == ComposeMode.keyboard ? null : spokenSeconds.value;

  Future<void> _save(String text) async {
    final q = question.value;
    if (q == null || text.isEmpty || isBusy.value) return;

    // 어느 단계의 답인지 **보내기 전에** 붙잡아 둔다. 응답을 기다리는 동안
    // 상태가 바뀌면 실패 처리가 엉뚱한 갈래로 간다.
    final wasFollowup = isFollowup.value;
    final pending = followup.value;
    if (wasFollowup && pending == null) return;

    isBusy.value = true;
    stage.value = wasFollowup
        ? WriteStage.saving
        : WriteStage.generatingFollowup;
    await _voice.stop();
    _cancelReveal();
    try {
      if (!wasFollowup) {
        followup.value = await _api.submitAnswer(
          questionId: q.id,
          text: text,
          inputMode: _inputMode,
          spokenSeconds: _spokenSecondsOrNull,
        );
        _firstAnswerText = text;
        isFollowup.value = true;
        _clearInput();
        stage.value = WriteStage.ask;
        isBusy.value = false;
        await presentQuestion();
        return;
      }

      final advance = await _api.submitFollowupAnswer(
        questionId: q.id,
        followupId: pending!.id,
        text: text,
        inputMode: _inputMode,
        spokenSeconds: _spokenSecondsOrNull,
      );
      saveFailed.value = false;

      // 서버가 followup을 주면 한 번 더 — 횟수는 세지 않는다.
      if (advance.needsAnotherFollowup) {
        followup.value = advance.followup;
        isFollowup.value = true;
        _clearInput();
        stage.value = WriteStage.ask;
        isBusy.value = false;
        await presentQuestion();
        return;
      }

      _toast.show(
        '저장되었습니다.',
        description:
            advance.nextQuestion == null ? null : '다음 질문으로 이동합니다.',
      );
      await _moveTo(advance.nextQuestion);
    } on ApiException {
      if (wasFollowup) {
        // ⚠️ FOLLOWUP_FAILED(중간 라운드)도 여기에 온다 — 초안은 서버에 남고
        //    같은 버튼을 다시 누르면 된다. 윤문 실패와 동일 UX.
        saveFailed.value = true;
        stage.value = WriteStage.confirm;
        return;
      }
      // 꼬리질문을 못 만들었다 — 서버가 1차 답변을 버렸으므로 화면에 남겨
      // 두면 거짓말이 된다. 지우고 처음부터 다시 받는다(D8).
      _firstAnswerText = null;
      followup.value = null;
      isFollowup.value = false;
      _clearInput();
      stage.value = WriteStage.followupFailed;
    } finally {
      isBusy.value = false;
    }
  }

  /// 질문 문구를 고칠 수 있는 상태인지.
  ///
  /// 꼬리질문 단계에서는 잠근다 — 그 질문에는 이미 답을 했고, 지금 문구를
  /// 바꾸면 곧 저장될 답과 어긋난다. 고칠 수 있는 것도 원래 질문이지
  /// AI가 만든 꼬리질문이 아니다.
  bool get canEditQuestion =>
      !isFollowup.value && question.value != null && !isBusy.value;

  /// 질문 문구만 고친다. 답변과 진행 상태는 건드리지 않는다.
  Future<void> editQuestionText(String text) async {
    final q = question.value;
    final next = text.trim();
    if (q == null || next.isEmpty || !canEditQuestion) return;
    if (next == q.text) return;

    isBusy.value = true;
    try {
      question.value = await _api.updateQuestionText(
        questionId: q.id,
        text: next,
      );
      _presentedKey = null;
      await presentQuestion();
      _toast.show('질문을 고쳤어요');
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isBusy.value = false;
    }
  }

  /// D8에서 "다시 답해볼게요" — 같은 질문을 처음부터 받는다.
  void restartQuestion() {
    _clearInput();
    followup.value = null;
    isFollowup.value = false;
    stage.value = WriteStage.ask;
    _presentedKey = null;
    presentQuestion();
  }

  /// 입력 흔적을 지운다. 질문은 건드리지 않는다.
  void _clearInput() {
    transcript.value = '';
    spokenSeconds.value = 0;
    saveFailed.value = false;
    answerController.clear();
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
    _clearInput();
    followup.value = null;
    isFollowup.value = false;
    stage.value = WriteStage.ask;

    final previous = chapter.value;
    final bookId = _requireBookId();

    // 장을 막 끝냈으면 완료 화면을 한 번 보여 준다.
    if (previous != null &&
        (next == null || next.chapterId != previous.id)) {
      completedChapter.value = previous;
      _pendingNext = next;
      isChapterComplete.value = true;
      try {
        chapterCompletion.value = await _api.chapterCompletion(
          bookId,
          previous.id,
        );
      } on ApiException {
        // 조회 실패해도 로컬 장 정보로 화면은 연다.
        chapterCompletion.value = null;
      }
      return;
    }

    await _applyNextQuestion(next, bookId);
  }

  Future<void> proceedAfterChapterComplete() async {
    final next = _pendingNext;
    final nextOrder = chapterCompletion.value?.nextChapter?.order ??
        (completedChapter.value != null
            ? completedChapter.value!.order + 1
            : null);
    if (next != null && nextOrder != null) {
      final allowed = await PurchaseFlow.allowChapter(
        api: _api,
        bookId: _requireBookId(),
        chapterOrder: nextOrder,
      );
      if (!allowed) return;
    }

    isChapterComplete.value = false;
    _pendingNext = null;
    completedChapter.value = null;
    chapterCompletion.value = null;
    await _applyNextQuestion(next, _requireBookId());
  }

  Future<void> _applyNextQuestion(Question? next, String bookId) async {
    question.value = next;
    isAllDone.value = next == null;
    _firstAnswerText = null;
    _presentedKey = null;
    if (next == null) {
      revealedQuestion.value = '';
      return;
    }
    final chapters = await _api.chapters(bookId);
    chapter.value = chapters.firstWhereOrNull((c) => c.id == next.chapterId);
    await presentQuestion();
  }

  void goBookHub() {
    Get.offNamed(
      AppRoutes.bookDetail,
      arguments: {'bookId': _requireBookId()},
    );
  }

  /// 리뷰 화면으로 이동.
  void goReview() {
    final c = completedChapter.value ?? chapter.value;
    if (c == null) {
      _toast.show('장 정보가 없어요');
      return;
    }
    Get.toNamed(
      AppRoutes.bookReview,
      arguments: {
        'bookId': _requireBookId(),
        'chapterId': c.id,
      },
    );
  }
}