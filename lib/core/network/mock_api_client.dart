import 'dart:async';

import 'package:life_legacy/data/data_manager.dart';

import 'api_client.dart';

/// [ApiClient]의 **가짜 구현** — 서버 계약이 정해질 때까지 앱을 돌리는 용도.
///
/// 메모리에 상태를 들고 있어서 답변을 저장하면 진행률·장 상태가 실제로
/// 바뀐다. 화면 흐름(질문 → 답변 → 다듬기 → 저장 → 다음 질문)이 끝까지
/// 도는지 확인할 수 있어야 목업으로서 값이 있기 때문이다.
///
/// ⚠️ 앱을 재시작하면 초기 상태로 돌아간다. 영속화는 일부러 하지 않았다 —
///    실제 서버가 들어오면 어차피 버릴 코드라서.
class MockApiClient implements ApiClient {
  /// 네트워크가 있는 것처럼 보이게 하는 지연.
  /// 로딩 스피너·스켈레톤이 실제로 보이는지 확인하려면 0이면 안 된다.
  static const _latency = Duration(milliseconds: 450);

  /// 목차 생성처럼 오래 걸리는 작업(시안 09번 전용 로딩 화면).
  static const _slowLatency = Duration(milliseconds: 2600);

  /// AI를 부르는 호출. 실제로는 꼬리질문 30초 · 윤문 60초까지 걸린다.
  /// 전용 로딩 화면이 눈에 보일 만큼은 끌어 둔다.
  static const _aiLatency = Duration(milliseconds: 1200);

  Future<T> _delay<T>(T value, [Duration d = _latency]) =>
      Future.delayed(d, () => value);

  // ══════════════════════════════════════════════════════════
  // 메모리 상태
  // ══════════════════════════════════════════════════════════

  User _user = const User(id: 'u1', name: '김영희', phone: '01012345678');

  AppSettings _settings = const AppSettings(dailyQuestionAlarm: true);

  /// 시안 C4(알림 센터)의 일곱 건.
  List<AppNotification> _notifications = const [
    AppNotification(id: 'n1', title: '오늘의 질문이 도착했어요', timeLabel: '3시간 전'),
    AppNotification(id: 'n2', title: '1장 어린 시절이 완성됐어요', timeLabel: '어제'),
    AppNotification(id: 'n3', title: '2장 새 질문 3개가 준비됐어요', timeLabel: '3일 전'),
    AppNotification(
      id: 'n4',
      title: '3장 서울살이와 첫 직장이 열렸어요',
      timeLabel: '1주 전',
      isRead: true,
    ),
    AppNotification(
      id: 'n5',
      title: '책 미리보기가 준비됐어요',
      timeLabel: '2주 전',
      isRead: true,
    ),
    AppNotification(
      id: 'n6',
      title: '2장 학창 시절과 꿈이 열렸어요',
      timeLabel: '3주 전',
      isRead: true,
    ),
    AppNotification(
      id: 'n7',
      title: '가입을 환영해요',
      timeLabel: '1개월 전',
      isRead: true,
    ),
  ];

  Address _address = const Address(
    recipient: '김영희',
    phone: '01012345678',
    postalCode: '03186',
    line1: '서울 종로구 세종대로 175',
    line2: '302동 1201호',
  );

  /// 인증번호 — 어떤 번호로 요청하든 이 값이 정답이다.
  static const demoCode = '482915';

  /// 다음 [submitFollowupAnswer] 한 번을 실패시킨다 — D5(저장 실패)를 눈으로
  /// 확인하기 위한 스위치다. 작성 화면 `⋯` 메뉴에서 켠다.
  ///
  /// ⚠️ 실제 구현에는 없을 코드다. 실패는 네트워크가 만들지 우리가 만들지 않는다.
  bool failNextSave = false;

  /// 다음 [submitAnswer] 한 번을 실패시킨다 — D6(꼬리질문 실패)용.
  ///
  /// 저장 실패와 **결과가 다르다.** 이쪽은 적은 글이 버려지고 질문부터 다시다.
  bool failNextFollowup = false;

  /// 마지막 1차 답변에 실려 온 값들. 테스트가 "무엇을 보냈는지" 확인한다.
  String? lastAnswerQuestionId;
  ComposeMode? lastAnswerInputMode;
  int? lastAnswerSpokenSeconds;

  /// 질문 id → 확정 전 1차 답변. 꼬리답변이 오면 합쳐서 저장하고 지운다.
  final Map<String, String> _drafts = {};

  /// [me]를 TOKEN_EXPIRED로 실패시킨다 — 토큰 갱신 흐름을 확인하기 위한 스위치.
  /// 갱신이 성공하면 저절로 꺼진다(서버가 새 토큰을 준 셈이므로).
  bool expireAccessToken = false;

  /// [refreshTokens]까지 실패시킨다. 이때는 다시 로그인하는 수밖에 없다.
  bool expireRefreshToken = false;

  /// 갱신을 몇 번 시도했는지. 테스트가 "부르지 않았다"를 확인한다.
  int refreshCallCount = 0;

  /// 발급한 토큰에 붙는 일련번호. 갱신할 때마다 값이 달라져야
  /// "갈아 끼웠다"를 눈으로 확인할 수 있다.
  int _tokenSerial = 0;

  AuthTokens _issueTokens() {
    _tokenSerial++;
    return AuthTokens(
      accessToken: 'mock-access-$_tokenSerial',
      refreshToken: 'mock-refresh-$_tokenSerial',
    );
  }

  late List<Chapter> _chapters = _seedChapters();
  late List<Question> _questions = _seedQuestions();

  /// 자기소개 답변 — F3(내 정보)의 "자기소개" 구획이 읽는다.
  /// 목차를 만들 때 [generateToc]가 통째로 받아 둔다.
  List<IntroAnswerSubmission> _introAnswers = const [
    IntroAnswerSubmission(questionId: 'i2', value: '여'),
    IntroAnswerSubmission(questionId: 'i6', value: '1955-03-12'),
    IntroAnswerSubmission(questionId: 'i3', value: '예'),
    IntroAnswerSubmission(questionId: 'i4', value: '예'),
    IntroAnswerSubmission(
      questionId: 'i5',
      value: '대학교 이상',
      detailValue: '학사',
    ),
  ];

  WritingPlan? _writingPlan;
  final Map<String, AnswerDraft> _answerDrafts = {};

  // ══════════════════════════════════════════════════════════
  // 인증
  // ══════════════════════════════════════════════════════════

  @override
  Future<VerificationChallenge> requestVerificationCode(String phone) => _delay(
    const VerificationChallenge(
      expiresIn: Duration(minutes: 3),
      resendAfter: Duration(seconds: 30),
    ),
  );

  @override
  Future<AuthSession> verifyCode({
    required String phone,
    required String code,
  }) async {
    await Future<void>.delayed(_latency);
    if (code != demoCode) {
      throw const ApiException('인증번호가 일치하지 않아요', code: 'INVALID_CODE');
    }
    _user = User(id: _user.id, name: _user.name, phone: phone);
    return AuthSession(
      tokens: _issueTokens(),
      user: _user,
      // 목차가 아직 확정되지 않았으면 자기소개부터 시작한다.
      needsIntro: !Storage.introDone,
    );
  }

  @override
  Future<AuthSession> loginWithKakao() => _delay(
    AuthSession(
      tokens: _issueTokens(),
      user: _user,
      needsIntro: !Storage.introDone,
    ),
  );

  @override
  Future<User> me() async {
    await Future<void>.delayed(_latency);
    if (expireAccessToken) {
      throw const ApiException('다시 로그인해 주세요', code: 'TOKEN_EXPIRED');
    }
    return _user;
  }

  @override
  Future<AuthTokens> refreshTokens(String refreshToken) async {
    refreshCallCount++;
    await Future<void>.delayed(_latency);
    if (expireRefreshToken) {
      throw const ApiException('다시 로그인해 주세요', code: 'UNAUTHORIZED');
    }
    // 새 액세스 토큰을 받았으니 만료 상태도 풀린다.
    expireAccessToken = false;
    return _issueTokens();
  }

  @override
  Future<void> logout() => _delay(null);

  /// 시안 343:713은 "2분 47초 남음"으로 그려져 있다 — 3분에서 13초 지난 모습이다.

  // ══════════════════════════════════════════════════════════
  // OCTOMO 인증 (신규 목업)
  // ══════════════════════════════════════════════════════════

  /// 목업 전화번호 — 10자 이상이면 "기존 사용자", 10자 미만이면 "신규".
  int _mockPhonePrefix(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) return 1; // existing
    return 0; // new
  }

  @override
  Future<PhoneLookupResult> lookupPhone(String phone) =>
      _delay(const PhoneLookupResult(nextStep: 'verify'));

  @override
  Future<OctomoChallenge> requestOctomoChallenge(String phone) => _delay(
    const OctomoChallenge(
      sessionId: 'avs_mock_01',
      receiverNumber: '050312345678',
      verifyText: '3538',
      expiresIn: 300,
      pollInterval: 3,
    ),
  );

  @override
  Future<OctomoVerifyResult> verifyOctomo(String sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    // 첫 3초는 pending, 이후 verified
    _verifyAttempts++;
    if (_verifyAttempts < 3) {
      return OctomoVerifyResult(
        status: 'pending',
        expiresIn: 300 - _verifyAttempts * 3,
      );
    }
    // 기존 사용자 모의
    if (_mockPhonePrefix(_mockPhone) == 1) {
      return OctomoVerifyResult(
        status: 'verified',
        account: 'existing',
        session: AuthSession(
          tokens: _issueTokens(),
          user: _user,
          needsIntro: !Storage.introDone,
        ),
      );
    }
    // 신규 사용자 모의
    return const OctomoVerifyResult(
      status: 'verified',
      account: 'new',
      signupToken: 'st_mock_001',
      requiredConsents: [
        ConsentDocument(
          key: 'terms_of_service',
          version: '1.0',
          title: '서비스 이용약관',
          url: 'https://lifelegacy.app/terms',
          required: true,
        ),
        ConsentDocument(
          key: 'privacy_policy',
          version: '1.0',
          title: '개인정보 처리방침',
          url: 'https://lifelegacy.app/privacy',
          required: true,
        ),
        ConsentDocument(
          key: 'age_14',
          version: '1.0',
          title: '만 14세 이상입니다',
          url: null,
          required: true,
        ),
        ConsentDocument(
          key: 'marketing',
          version: '1.0',
          title: '마케팅 정보 수신',
          url: 'https://lifelegacy.app/privacy',
          required: false,
        ),
      ],
    );
  }

  int _verifyAttempts = 0;
  String _mockPhone = '01012345678';

  @override
  Future<AuthSession> signUp({
    required String signupToken,
    required String name,
    required List<ConsentAgreement> consents,
  }) async {
    await Future<void>.delayed(_latency);
    // 필수 3종 확인
    final requiredKeys = {'terms_of_service', 'privacy_policy', 'age_14'};
    for (final c in consents) {
      if (requiredKeys.contains(c.key) && !c.agreed) {
        throw const ApiException(
          '필수 약관에 동의해 주세요',
          code: 'CONSENT_REQUIRED',
        );
      }
    }
    _user = User(id: _user.id, name: name, phone: _user.phone);
    _mockPhone = _user.phone;
    _verifyAttempts = 0;
    return AuthSession(
      tokens: _issueTokens(),
      user: _user,
      needsIntro: true,
    );
  }

  @override
  Future<List<ConsentDocument>> consentDocuments() => _delay(const [
    ConsentDocument(
      key: 'terms_of_service',
      version: '1.0',
      title: '서비스 이용약관',
      url: 'https://lifelegacy.app/terms',
      required: true,
    ),
    ConsentDocument(
      key: 'privacy_policy',
      version: '1.0',
      title: '개인정보 처리방침',
      url: 'https://lifelegacy.app/privacy',
      required: true,
    ),
    ConsentDocument(
      key: 'age_14',
      version: '1.0',
      title: '만 14세 이상입니다',
      url: null,
      required: true,
    ),
    ConsentDocument(
      key: 'marketing',
      version: '1.0',
      title: '마케팅 정보 수신',
      url: 'https://lifelegacy.app/privacy',
      required: false,
    ),
  ]);

  // ══════════════════════════════════════════════════════════
  // 자기소개 → 목차
  // ══════════════════════════════════════════════════════════

  /// 시드와 동일 — i2·i6·i3·i4·i5 (i1 성함은 가입 이름).
  @override
  Future<List<IntroQuestion>> introQuestions() => _delay(const [
    IntroQuestion(
      id: 'i2',
      order: 1,
      text: '성별을\n알려주세요',
      subtitle: '책에서 부르는 말을 정할 때 써요',
      type: IntroAnswerType.choice,
      choices: [
        IntroChoiceOption(id: 'ch_m', label: '남'),
        IntroChoiceOption(id: 'ch_f', label: '여'),
      ],
    ),
    IntroQuestion(
      id: 'i6',
      order: 2,
      text: '생년월일을\n알려주세요',
      type: IntroAnswerType.date,
    ),
    IntroQuestion(
      id: 'i3',
      order: 3,
      text: '결혼은\n하셨나요?',
      subtitle: '가족 이야기를 여쭤볼 때 참고해요',
      type: IntroAnswerType.choice,
      skippable: true,
      choices: [
        IntroChoiceOption(id: 'ch_mar_y', label: '예'),
        IntroChoiceOption(id: 'ch_mar_n', label: '아니오'),
      ],
    ),
    IntroQuestion(
      id: 'i4',
      order: 4,
      text: '자녀가\n있으신가요?',
      subtitle: '자녀 이야기를 여쭤볼지 정해요',
      type: IntroAnswerType.choice,
      skippable: true,
      choices: [
        IntroChoiceOption(id: 'ch_ch_y', label: '예'),
        IntroChoiceOption(id: 'ch_ch_n', label: '아니오'),
      ],
    ),
    IntroQuestion(
      id: 'i5',
      order: 5,
      text: '학교는 어디까지\n다니셨나요?',
      subtitle: '학창 시절 질문을 고를 때 써요',
      type: IntroAnswerType.choice,
      choices: [
        IntroChoiceOption(
          id: 'ch_e',
          label: '초등학교',
          details: [
            IntroChoiceOption(id: 'ch_e1', label: '초등학교'),
            IntroChoiceOption(id: 'ch_e2', label: '국민학교'),
          ],
        ),
        IntroChoiceOption(id: 'ch_m_edu', label: '중학교'),
        IntroChoiceOption(id: 'ch_h', label: '고등학교'),
        IntroChoiceOption(
          id: 'ch_u',
          label: '대학교 이상',
          details: [
            IntroChoiceOption(id: 'ch_u1', label: '학사'),
            IntroChoiceOption(id: 'ch_u2', label: '석사'),
            IntroChoiceOption(id: 'ch_u3', label: '박사'),
          ],
        ),
      ],
    ),
  ]);

  int _recommendWeeks(WritingPlan? plan) {
    final minutes = plan?.dailyMinutes ?? 30;
    final days = plan?.availableWeekdays.length ?? 3;
    if (minutes >= 90 && days >= 4) return 1;
    if (minutes >= 60) return 2;
    if (minutes >= 30) return 4;
    return 6;
  }

  @override
  Future<WritingPlanResult> writingPlan() => _delay(
    WritingPlanResult(
      recommendedWeeks: _recommendWeeks(_writingPlan),
      plan: _writingPlan,
    ),
  );

  @override
  Future<WritingPlanResult> updateWritingPlan(WritingPlan plan) async {
    _writingPlan = plan;
    await Future<void>.delayed(_latency);
    return WritingPlanResult(
      recommendedWeeks: _recommendWeeks(plan),
      plan: plan,
    );
  }

  @override
  Future<TocGenerateResult> generateToc(
    List<IntroAnswerSubmission> answers,
  ) async {
    _introAnswers = List.of(answers);
    const bookId = 'b_mock_001';
    await Future<void>.delayed(_slowLatency);
    _chapters = _seedChapters();
    return TocGenerateResult(
      bookId: bookId,
      caseKey: 'legacy_college_married_children',
      chapters: _chapters,
    );
  }

  @override
  Future<List<CatalogChapter>> catalogChapters(String bookId) => _delay([
    for (final c in _seedChapters())
      CatalogChapter(
        id: 'ct_${c.id}',
        title: c.title,
        questionCount: c.questionCount,
        alreadyAdded: _chapters.any((x) => x.title == c.title),
      ),
    CatalogChapter(
      id: 'ct_extra_현재',
      title: '현재의 삶',
      questionCount: 5,
      alreadyAdded: _chapters.any((x) => x.title == '현재의 삶'),
    ),
  ]);

  @override
  Future<List<Chapter>> saveTocDraft({
    required String bookId,
    required List<TocDraftChapter> chapters,
  }) async {
    await Future<void>.delayed(_latency);
    final out = <Chapter>[];
    for (final (i, item) in chapters.indexed) {
      if (item.id != null) {
        final existing = _chapters.cast<Chapter?>().firstWhere(
          (c) => c?.id == item.id,
          orElse: () => null,
        );
        out.add(
          Chapter(
            id: item.id!,
            order: i + 1,
            title: item.title ?? existing?.title ?? '장',
            status: i == 0 ? ChapterStatus.writing : ChapterStatus.locked,
            answeredCount: existing?.answeredCount ?? 0,
            questionCount: existing?.questionCount ?? 5,
            sourceType: existing?.sourceType ?? ChapterSource.template,
          ),
        );
      } else if (item.templateId != null) {
        out.add(
          Chapter(
            id: 'c_new_$i',
            order: i + 1,
            title: catalogTitleFor(item.templateId!),
            status: i == 0 ? ChapterStatus.writing : ChapterStatus.locked,
            answeredCount: 0,
            questionCount: 5,
            sourceType: ChapterSource.template,
            templateId: item.templateId,
          ),
        );
      } else {
        out.add(
          Chapter(
            id: 'c_custom_$i',
            order: i + 1,
            title: item.title ?? '새 목차',
            status: i == 0 ? ChapterStatus.writing : ChapterStatus.locked,
            answeredCount: 0,
            questionCount: 0,
            sourceType: ChapterSource.custom,
          ),
        );
      }
    }
    _chapters = out;
    return out;
  }

  String catalogTitleFor(String templateId) {
    if (templateId == 'ct_extra_현재') return '현재의 삶';
    for (final c in _seedChapters()) {
      if ('ct_${c.id}' == templateId) return c.title;
    }
    return '추가한 장';
  }

  @override
  Future<TocConfirmResult> confirmToc({
    required String bookId,
    required List<Chapter> chapters,
  }) async {
    await Future<void>.delayed(_latency);
    _chapters = [
      for (final (i, c) in chapters.indexed)
        Chapter(
          id: c.id,
          order: i + 1,
          title: c.title,
          status: i == 0 ? ChapterStatus.writing : ChapterStatus.locked,
          answeredCount: c.answeredCount,
          questionCount: c.questionCount,
          sourceType: c.sourceType,
          templateId: c.templateId,
        ),
    ];
    _questions = _seedQuestions();
    return TocConfirmResult(
      bookId: bookId,
      firstQuestionId: _questions.isEmpty ? null : _questions.first.id,
      chapters: _chapters,
    );
  }

  @override
  Future<IntroProfile> introProfile() => _delay(
    IntroProfile(
      entries: [
        for (final (id, label) in _profileLabels)
          if (_introAnswers.where((a) => a.questionId == id).firstOrNull
              case final a?)
            IntroProfileEntry(
              label: label,
              value: a.skipped
                  ? null
                  : (a.detailValue != null
                        ? '${a.value} · ${a.detailValue}'
                        : a.value),
              skipped: a.skipped,
            ),
      ],
    ),
  );

  /// 자기소개 문항 id → F3에 뜨는 라벨. 성함(i1)은 "기본 정보"에 따로 나가므로 뺀다.
  static const _profileLabels = [
    ('i2', '성별'),
    ('i6', '생년월일'),
    ('i3', '결혼'),
    ('i4', '자녀'),
    ('i5', '학력'),
  ];

  // ══════════════════════════════════════════════════════════
  // 홈
  // ══════════════════════════════════════════════════════════

  @override
  Future<HomeSummary> home(String bookId) {
    final next = _findCurrentQuestion();
    final total = _questions.length;
    final answered = _questions.where((q) => q.isAnswered).length;
    return _delay(
      HomeSummary(
        bookId: bookId,
        todayQuestion: next?.text,
        todayQuestionId: next?.id,
        progress: total == 0 ? 0 : answered / total,
        chapterDone: _chapters
            .where((c) => c.status == ChapterStatus.done)
            .length,
        chapterTotal: _chapters.length,
        remainingQuestions: total - answered,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 작성
  // ══════════════════════════════════════════════════════════

  @override
  Future<List<Chapter>> chapters(String bookId) => _delay(_syncChapters());

  @override
  Future<Question?> currentQuestion(String bookId) =>
      _delay(_findCurrentQuestion());

  @override
  Future<Question> question(String questionId) =>
      _delay(_questions.firstWhere((q) => q.id == questionId));

  @override
  Future<Followup> submitAnswer({
    required String questionId,
    required String text,
    required ComposeMode inputMode,
    int? spokenSeconds,
  }) async {
    lastAnswerQuestionId = questionId;
    lastAnswerInputMode = inputMode;
    lastAnswerSpokenSeconds = spokenSeconds;

    // 실제 서버는 AI를 부르느라 30초까지 걸린다. 로딩 화면이 눈에 보이도록
    // 보통 지연보다 길게 잡았다.
    await Future<void>.delayed(_aiLatency);
    if (failNextFollowup) {
      failNextFollowup = false;
      throw const ApiException(
        '질문을 만들지 못했어요',
        code: 'FOLLOWUP_FAILED',
      );
    }

    _drafts[questionId] = text;
    final q = _questions.firstWhere((e) => e.id == questionId);
    final followup = Followup(
      id: 'f_$questionId',
      seq: 1,
      text: _followupTextFor(q.text),
    );
    _answerDrafts[questionId] = AnswerDraft(
      questionId: questionId,
      phase: 'followup',
      text: text,
      inputMode: inputMode,
      spokenSeconds: spokenSeconds,
      followupRound: 1,
      pendingFollowup: followup,
    );
    return followup;
  }

  @override
  Future<FollowupAdvanceResult> submitFollowupAnswer({
    required String questionId,
    required String followupId,
    required String text,
    required ComposeMode inputMode,
    int? spokenSeconds,
  }) async {
    await Future<void>.delayed(_aiLatency);
    if (failNextSave) {
      failNextSave = false;
      throw const ApiException('저장하지 못했어요', code: 'POLISH_FAILED');
    }

    final draft = _answerDrafts[questionId];
    final round = draft?.followupRound ?? 1;
    // 최대 2회 꼬리 → round 1이면 한 번 더
    if (round < 2) {
      final next = Followup(
        id: 'f_mock_${questionId}_$round',
        seq: round + 1,
        text: _followupTextFor(text),
      );
      _answerDrafts[questionId] = AnswerDraft(
        questionId: questionId,
        phase: 'followup',
        text: draft?.text ?? '',
        inputMode: inputMode,
        spokenSeconds: spokenSeconds,
        followupRound: round + 1,
        pendingFollowup: next,
      );
      return FollowupAdvanceResult(followup: next);
    }

    final first = _drafts.remove(questionId) ?? '';
    _answerDrafts.remove(questionId);
    final joined = [first, text].where((e) => e.isNotEmpty).join('\n\n');

    final i = _questions.indexWhere((q) => q.id == questionId);
    if (i >= 0) _questions[i] = _questions[i].copyWith(answer: joined);
    _syncChapters();
    return FollowupAdvanceResult(nextQuestion: _findCurrentQuestion());
  }

  /// 1차 답변을 받고 되묻는 말. 실제로는 AI가 답변 내용을 읽고 만든다.
  String _followupTextFor(String question) =>
      '말씀해 주신 장면이 눈에 그려집니다. 그 시간이 지금까지도 마음에 남아 계신 것 같아요.\n\n'
      '그때 곁에 누가 함께 있었는지, 기억나는 대로 조금만 더 들려주시겠어요?';

  @override
  Future<Question> updateQuestionText({
    required String questionId,
    required String text,
  }) async {
    await Future<void>.delayed(_latency);
    final i = _questions.indexWhere((q) => q.id == questionId);
    if (i < 0) {
      throw const ApiException('질문을 찾지 못했어요', code: 'NOT_FOUND');
    }
    if (_questions[i].isAnswered) {
      throw const ApiException(
        '이미 답하신 질문이라 고칠 수 없어요',
        code: 'ALREADY_ANSWERED',
      );
    }
    final q = _questions[i];
    _questions[i] = Question(
      id: q.id,
      chapterId: q.chapterId,
      order: q.order,
      text: text,
      answer: q.answer,
    );
    return _questions[i];
  }

  @override
  Future<Question?> skipQuestion(String questionId) async {
    await Future<void>.delayed(_latency);
    // 건너뛴 질문은 답변으로 치지 않는다. 같은 장의 **다음** 질문을 돌려준다.
    final q = _questions.firstWhere((e) => e.id == questionId);
    final rest = _questions
        .where(
          (e) =>
              e.chapterId == q.chapterId && e.order > q.order && !e.isAnswered,
        )
        .toList();
    return rest.isEmpty ? _findCurrentQuestion() : rest.first;
  }

  @override
  Future<AnswerDraft> saveAnswerDraft({
    required String questionId,
    required String text,
    required ComposeMode inputMode,
    int? spokenSeconds,
  }) async {
    await Future<void>.delayed(_latency);
    final existing = _answerDrafts[questionId];
    if (existing?.isFollowupPhase == true) {
      return existing!;
    }
    final draft = AnswerDraft(
      questionId: questionId,
      phase: 'first',
      text: text,
      inputMode: inputMode,
      spokenSeconds: spokenSeconds,
    );
    _answerDrafts[questionId] = draft;
    return draft;
  }

  @override
  Future<AnswerDraft?> answerDraft(String questionId) =>
      _delay(_answerDrafts[questionId]);

  @override
  Future<void> deleteAnswerDraft(String questionId) async {
    await Future<void>.delayed(_latency);
    _answerDrafts.remove(questionId);
  }

  final Map<String, ChapterReview> _reviews = {};

  @override
  Future<ChapterReview?> chapterReview(String bookId, String chapterId) =>
      _delay(_reviews[chapterId]);

  @override
  Future<ChapterReview> synthesizeReview(
    String bookId,
    String chapterId,
  ) async {
    await Future<void>.delayed(_aiLatency);
    final chapter = _chapters.firstWhere(
      (c) => c.id == chapterId,
      orElse: () => _chapters.first,
    );
    final answers = _questions
        .where((q) => q.chapterId == chapter.id && q.isAnswered)
        .map((q) => q.answer!)
        .toList();
    final review = ChapterReview(
      chapterId: chapter.id,
      chapterOrder: chapter.order,
      chapterTitle: chapter.title,
      status: 'draft',
      version: 1,
      paragraphs: answers.isEmpty
          ? [
              '이 장의 이야기를 정리하고 있어요.',
              '질문에 답하시면 여기에 자서전 문체로 모입니다.',
            ]
          : answers,
    );
    _reviews[chapter.id] = review;
    return review;
  }

  @override
  Future<ChapterReview> saveReview({
    required String bookId,
    required String chapterId,
    required int version,
  }) async {
    await Future<void>.delayed(_latency);
    final current = _reviews[chapterId] ??
        await synthesizeReview(bookId, chapterId);
    final next = current.copyWith(
      status: 'reviewed',
      version: version,
      message: current.chapterOrder == 1 ? '챕터1 저장 완료' : '현재 챕터 저장 완료',
    );
    _reviews[chapterId] = next;
    return next;
  }

  @override
  Future<ChapterCompletion> chapterCompletion(
    String bookId,
    String chapterId,
  ) async {
    await Future<void>.delayed(_latency);
    final chapter = _chapters.firstWhere(
      (c) => c.id == chapterId,
      orElse: () => throw const ApiException('장을 찾지 못했어요', code: 'NOT_FOUND'),
    );
    if (chapter.status == ChapterStatus.locked) {
      throw const ApiException('아직 열리지 않은 장이에요', code: 'CHAPTER_LOCKED');
    }
    final qs = _questions.where((q) => q.chapterId == chapterId).toList();
    final answered = qs.where((q) => q.isAnswered).length;
    // mock은 skipped를 별도 필드로 두지 않아 0
    final next = _chapters
        .where((c) => c.order > chapter.order)
        .fold<Chapter?>(null, (best, c) {
          if (best == null || c.order < best.order) return c;
          return best;
        });
    final review = _reviews[chapterId];
    return ChapterCompletion(
      chapterId: chapter.id,
      chapterOrder: chapter.order,
      chapterTitle: chapter.title,
      questionCount: qs.length,
      answeredCount: answered,
      skippedCount: 0,
      reviewStatus: review?.status == 'reviewed' ? 'reviewed' : null,
      nextChapter: next == null
          ? null
          : ChapterCompletionNext(
              id: next.id,
              order: next.order,
              title: next.title,
            ),
      canReview: chapter.status == ChapterStatus.done,
      canHub: true,
    );
  }

  @override
  Future<VoiceAudio> synthesizeSpeech({
    required String text,
    String? voiceCode,
  }) async {
    await Future<void>.delayed(_latency);
    // 목업: 실제 mp3 대신 빈 바이트 — 재생은 실패해도 흐름만 검증
    return VoiceAudio(
      bytes: const [0xff, 0xfb, 0x90, 0x00],
      durationMs: 800,
    );
  }

  @override
  Future<SttResult> transcribeAudio({
    required List<int> bytes,
    required String filename,
    String contentType = 'audio/mp4',
    int? durationMs,
  }) async {
    await Future<void>.delayed(_aiLatency);
    if (bytes.isEmpty) {
      throw const ApiException('말씀을 알아듣지 못했어요', code: 'STT_FAILED');
    }
    return SttResult(
      text: '목업 전사입니다. 그때의 이야기가 참 따뜻하게 들립니다.',
      durationMs: durationMs,
    );
  }

  @override
  Future<VoiceAudio> voiceSample({String? voiceCode}) =>
      synthesizeSpeech(text: '샘플');

  @override
  Future<VoiceAudio> reviewTts({
    required String bookId,
    required String chapterId,
    int fromParagraph = 0,
    int chunkSize = 2,
    String? voiceCode,
  }) async {
    await Future<void>.delayed(_latency);
    return VoiceAudio(
      bytes: const [0xff, 0xfb, 0x90, 0x00],
      durationMs: 1000,
      nextParagraph: null,
    );
  }

  // ══════════════════════════════════════════════════════════
  // 나의 자서전
  // ══════════════════════════════════════════════════════════

  @override
  Future<List<BookListItem>> books() => _delay([
    BookListItem(
      id: 'b_mock_001',
      title: '나의 이야기',
      authorName: _user.name,
      status: 'writing',
      chapterCount: _chapters.length,
      chapterDone: _chapters
          .where((c) => c.status == ChapterStatus.done)
          .length,
      progress: _questions.isEmpty
          ? 0
          : _questions.where((q) => q.isAnswered).length / _questions.length,
      updatedAt: DateTime.now(),
    ),
  ]);

  @override
  Future<Book> book(String bookId) {
    final chapters = _syncChapters();
    final writing = chapters.where((c) => c.status == ChapterStatus.writing);
    final currentChapter = writing.isEmpty ? null : writing.first;
    Question? currentQ;
    if (currentChapter != null) {
      currentQ = _questions
          .where((q) => q.chapterId == currentChapter.id && !q.isAnswered)
          .fold<Question?>(null, (best, q) {
            if (best == null || q.order < best.order) return q;
            return best;
          });
    }
    final reviewed = chapters
        .where((c) => _reviews[c.id]?.status == 'reviewed')
        .length;
    final status = chapters.isEmpty
        ? 'draft'
        : reviewed == chapters.length
            ? 'completed'
            : 'writing';
    return _delay(
      Book(
        id: bookId,
        title: '나의 이야기',
        authorName: _user.name,
        status: status,
        progress: _questions.isEmpty
            ? 0
            : _questions.where((q) => q.isAnswered).length / _questions.length,
        chapterDone:
            chapters.where((c) => c.status == ChapterStatus.done).length,
        chapterTotal: chapters.length,
        currentQuestion: currentQ == null || currentChapter == null
            ? null
            : BookCurrentQuestion(
                id: currentQ.id,
                chapterId: currentChapter.id,
                chapterTitle: currentChapter.title,
                order: currentQ.order,
                text: currentQ.text,
              ),
        chapters: [
          for (final c in chapters)
            c.copyWith(
              reviewStatus: _reviews[c.id]?.status,
              ebookEligible: _reviews[c.id]?.status == 'reviewed',
            ),
        ],
        entitlements: BookEntitlements.defaults,
        questionCount: _questions.length,
        pageCount: _questions.where((q) => q.isAnswered).length * 6,
        photoCount: 0,
      ),
    );
  }

  @override
  Future<List<BookPage>> bookPages(String bookId) {
    // 쪽 번호는 책 전체를 통틀어 매긴다 — 미리보기 하단이 "12 / 34쪽"으로
    // 전체 대비 위치를 보여주기 때문이다. 앞의 10쪽은 표지·목차 몫이다.
    const frontMatter = 10;
    final chunks = <(Chapter, List<String>)>[];
    for (final c in _syncChapters()) {
      if (_reviews[c.id]?.status != 'reviewed') continue;
      final answers = _questions
          .where((q) => q.chapterId == c.id && q.isAnswered)
          .map((q) => q.answer!)
          .toList();
      // 답변 두 개를 한 쪽에 담는다.
      for (var i = 0; i < answers.length; i += 2) {
        chunks.add((c, answers.skip(i).take(2).toList()));
      }
    }

    final total = frontMatter + chunks.length;
    return _delay([
      for (final (i, (c, paragraphs)) in chunks.indexed)
        BookPage(
          chapterOrder: c.order,
          chapterTitle: c.title,
          pageNumber: frontMatter + i + 1,
          totalPages: total,
          paragraphs: paragraphs,
        ),
    ]);
  }

  @override
  Future<EbookEligibility> ebookEligibility(String bookId) async {
    final detail = await book(bookId);
    final included = detail.chapters
        .where((c) => c.ebookEligible)
        .map(
          (c) => EbookIncludedChapter(
            id: c.id,
            order: c.order,
            title: c.title,
            version: 1,
          ),
        )
        .toList();
    final allowed = included.isNotEmpty;
    return _delay(
      EbookEligibility(
        allowed: allowed,
        reason: allowed ? null : 'CHAPTER_NOT_REVIEWED',
        includedChapters: included,
        pendingChapters: detail.chapterTotal - included.length,
        coverKind: 'default',
        downloadable: allowed,
        titleSuggestAvailable: detail.progress >= 0.8,
        progress: detail.progress,
      ),
    );
  }

  @override
  Future<PlanEntitlements> entitlements(String bookId) async {
    // 소유 확인
    await book(bookId);
    return _delay(
      const PlanEntitlements(
        planCode: 'free',
        features: {
          'ebook': PlanFeatureEntitlement(allowed: true),
          'audiobook': PlanFeatureEntitlement(
            allowed: false,
            reason: 'PLAN_REQUIRED',
            remainingGenerations: 0,
          ),
          'manual_photo': PlanFeatureEntitlement(
            allowed: false,
            reason: 'PLAN_REQUIRED',
            remainingGenerations: 0,
          ),
          'ai_photo': PlanFeatureEntitlement(
            allowed: true,
            remainingGenerations: 1,
          ),
          'ai_rewrite': PlanFeatureEntitlement(
            allowed: false,
            reason: 'PLAN_REQUIRED',
            remainingGenerations: 0,
          ),
        },
      ),
    );
  }

  @override
  Future<EbookExportResult> generateEbook(String bookId) async {
    final elig = await ebookEligibility(bookId);
    if (!elig.allowed) {
      throw const ApiException(
        '챕터 리뷰를 저장하면 전자책을 확인할 수 있어요',
        code: 'CHAPTER_NOT_REVIEWED',
      );
    }
    return _delay(
      EbookExportResult(
        exportId: 'ex_mock_$bookId',
        status: 'completed',
        chapterSnapshot: [
          for (final c in elig.includedChapters)
            EbookSnapshotChapter(chapterId: c.id, version: c.version),
        ],
      ),
    );
  }

  @override
  Future<List<int>> downloadEbookFile(String bookId) async {
    await generateEbook(bookId);
    // 목업: 최소 PDF 헤더만 (열기 실패할 수 있음 — Real이 진실)
    const header = '%PDF-1.4 mock ebook\n';
    return _delay(header.codeUnits);
  }

  @override
  Future<List<String>> suggestEbookTitles(String bookId) async {
    final book = await this.book(bookId);
    if (book.progress < 0.8) {
      throw const ApiException(
        '전체 작성 진행률 80% 이상에서 제목 추천을 쓸 수 있어요',
        code: 'TITLE_PROGRESS_REQUIRED',
      );
    }
    return _delay([
      '${book.authorName}의 ${book.title}',
      '볕이 좋던 날의 기록',
      '남겨 두고 싶은 이름',
      '우리가 걸어온 시간',
    ]);
  }

  @override
  Future<void> updateEbookMetadata(
    String bookId, {
    required String title,
  }) async {
    await Future<void>.delayed(_latency);
  }

  @override
  Future<AudiobookOverview> audiobook(String bookId) async {
    final detail = await book(bookId);
    return _delay(
      AudiobookOverview(
        bookTitle: detail.title,
        allowed: false,
        reason: 'PLAN_REQUIRED',
        chapters: const [],
      ),
    );
  }

  @override
  Future<List<AudiobookVoice>> audiobookVoices(String bookId) async {
    await book(bookId);
    return _delay(const [
      AudiobookVoice(
        voiceCode: 'vara',
        name: '아라(Pro)',
        gender: 'female',
        isDefault: true,
        pro: true,
      ),
      AudiobookVoice(
        voiceCode: 'vdaeseong',
        name: '대성(Pro)',
        gender: 'male',
        pro: true,
      ),
    ]);
  }

  @override
  Future<List<int>> audiobookVoicePreview(
    String bookId,
    String voiceCode,
  ) async {
    await book(bookId);
    return _delay(const <int>[1, 2, 3]);
  }

  @override
  Future<List<AudiobookBgmTrack>> audiobookBgms(String bookId) async {
    await book(bookId);
    return _delay(const [
      AudiobookBgmTrack(id: 'bgm_soft', title: 'a soothing song', mood: 'gentle'),
    ]);
  }

  @override
  Future<AudiobookJobCreated> createAudiobookJob({
    required String bookId,
    required String chapterId,
    required String voiceCode,
    required String idempotencyKey,
    String? bgmTrackId,
  }) async {
    await book(bookId);
    return _delay(
      AudiobookJobCreated(
        jobId: 'aj_mock_$chapterId',
        status: 'pending',
        remainingGenerations: 1,
      ),
    );
  }

  @override
  Future<AudiobookJobStatus> audiobookJob(String bookId, String jobId) =>
      _delay(
        AudiobookJobStatus(
          jobId: jobId,
          status: 'completed',
          progress: 100,
        ),
      );

  @override
  Future<AudiobookJobStatus> cancelAudiobookJob(
    String bookId,
    String jobId,
  ) =>
      _delay(
        AudiobookJobStatus(jobId: jobId, status: 'cancelled', progress: 0),
      );

  @override
  Future<List<int>> audiobookChapterAudio(
    String bookId,
    String chapterId, {
    bool download = false,
  }) =>
      _delay(const <int>[]);

  // ══════════════════════════════════════════════════════════
  // 알림
  // ══════════════════════════════════════════════════════════

  @override
  Future<List<AppNotification>> notifications() =>
      _delay(List.unmodifiable(_notifications));

  @override
  Future<List<AppNotification>> markAllNotificationsRead() {
    _notifications = [for (final n in _notifications) n.copyWith(isRead: true)];
    return _delay(List.unmodifiable(_notifications));
  }

  // ══════════════════════════════════════════════════════════
  // 설정
  // ══════════════════════════════════════════════════════════

  @override
  Future<AppSettings> settings() => _delay(_settings);

  @override
  Future<AppSettings> updateSettings(AppSettings next) {
    _settings = next;
    return _delay(_settings);
  }

  // ══════════════════════════════════════════════════════════
  // 인쇄본 배송지
  // ══════════════════════════════════════════════════════════

  @override
  Future<Address> shippingAddress() => _delay(_address);

  @override
  Future<Address> updateShippingAddress(Address next) {
    _address = next;
    return _delay(_address);
  }

  // ══════════════════════════════════════════════════════════
  // 내부
  // ══════════════════════════════════════════════════════════

  /// 답변 수를 보고 각 장의 상태를 다시 계산한다.
  /// 앞 장이 끝나야 다음 장이 열리는 규칙도 여기서 적용한다.
  List<Chapter> _syncChapters() {
    // 앞 장의 결과가 다음 장의 잠금 여부를 정하므로 순서대로 훑어야 한다.
    var previousDone = true;
    final out = <Chapter>[];
    for (final c in _chapters) {
      final next = _recalc(c, unlocked: previousDone);
      out.add(next);
      previousDone = next.status == ChapterStatus.done;
    }
    _chapters = out;
    return _chapters;
  }

  Chapter _recalc(Chapter c, {required bool unlocked}) {
    final answered = _questions
        .where((q) => q.chapterId == c.id && q.isAnswered)
        .length;
    final status = switch (answered) {
      _ when answered >= c.questionCount => ChapterStatus.done,
      0 when !unlocked => ChapterStatus.locked,
      _ => ChapterStatus.writing,
    };
    // 자서전 목록(E1)이 "다음 질문 · ○○○"으로 쓸 문구.
    final pending = _questions
        .where((q) => q.chapterId == c.id && !q.isAnswered)
        .toList();
    final next = status == ChapterStatus.writing && pending.isNotEmpty
        ? pending.first.text
        : null;

    // ⚠️ copyWith를 쓰지 않는다 — null을 넘겨도 예전 값이 남는 구조라
    //    장을 다 끝냈는데 "다음 질문"이 계속 붙어 있게 된다.
    return Chapter(
      id: c.id,
      order: c.order,
      title: c.title,
      status: status,
      answeredCount: answered,
      questionCount: c.questionCount,
      nextQuestionText: next,
    );
  }

  /// 지금 답해야 할 질문 = 잠기지 않은 장의 첫 미답변 질문.
  Question? _findCurrentQuestion() {
    for (final c in _syncChapters()) {
      if (c.status == ChapterStatus.locked) continue;
      final pending = _questions
          .where((q) => q.chapterId == c.id && !q.isAnswered)
          .toList();
      if (pending.isNotEmpty) return pending.first;
    }
    return null;
  }

  // ── 초기 데이터 ────────────────────────────────────────────

  /// 시안 B7·C1·E1의 목차.
  ///
  /// ⚠️ 시안 C1의 "42%"는 정적인 목업 수치다. 여기서는 진행률을 답변 수로
  ///    계산하므로 화면에 뜨는 값이 시안과 정확히 같지는 않다.
  static List<Chapter> _seedChapters() => const [
    Chapter(
      id: 'c1',
      order: 1,
      title: '어린 시절',
      status: ChapterStatus.done,
      answeredCount: 0,
      questionCount: 8,
    ),
    Chapter(
      id: 'c2',
      order: 2,
      title: '학창 시절과 꿈',
      status: ChapterStatus.writing,
      answeredCount: 0,
      questionCount: 8,
    ),
    Chapter(
      id: 'c3',
      order: 3,
      title: '서울살이와 첫 직장',
      status: ChapterStatus.locked,
      answeredCount: 0,
      questionCount: 6,
    ),
    Chapter(
      id: 'c4',
      order: 4,
      title: '가족을 이루다',
      status: ChapterStatus.locked,
      answeredCount: 0,
      questionCount: 6,
    ),
    Chapter(
      id: 'c5',
      order: 5,
      title: '지금의 나',
      status: ChapterStatus.locked,
      answeredCount: 0,
      questionCount: 6,
    ),
  ];

  /// 장별 질문. 앞부분은 답변이 채워진 상태로 시작해서 "이어서 쓰는" 흐름을
  /// 바로 볼 수 있게 했다(빈 상태만 보이면 홈 카드가 늘 비어 있다).
  static List<Question> _seedQuestions() {
    const texts = {
      'c1': [
        '어린 시절 살던 동네는 어떤 모습이었나요?',
        '가장 아끼던 물건이 있었나요?',
        '부모님은 어떤 분이셨나요?',
        '형제자매와는 어떻게 지내셨어요?',
        '기억에 남는 명절이 있으신가요?',
        '어릴 적 가장 무서웠던 일은 무엇인가요?',
        '동네 친구들과 무엇을 하며 놀았나요?',
        '그 시절로 돌아간다면 무엇을 하고 싶으세요?',
      ],
      'c2': [
        '학교 가는 길은 어땠나요?',
        '가장 기억에 남는 선생님이 계신가요?',
        '학창 시절 꿈은 무엇이었나요?',
        '친구들과의 추억 하나를 들려주세요.',
        '공부는 어떠셨어요?',
        '처음으로 크게 실망했던 일이 있나요?',
        '그때 좋아하던 노래나 영화가 있나요?',
        '졸업하던 날은 어떤 기분이었나요?',
      ],
      'c3': [
        '서울에 처음 올라오던 날을 기억하시나요?',
        '첫 직장은 어떤 곳이었나요?',
        '첫 월급을 받던 날, 기분이 어떠셨나요?',
        '일하면서 가장 힘들었던 때는 언제인가요?',
        '고마웠던 사람이 있나요?',
        '그 시절 나에게 해주고 싶은 말이 있다면요?',
      ],
      'c4': [
        '배우자를 처음 만난 날을 들려주세요.',
        '결혼식 날은 어떠셨나요?',
        '아이가 태어나던 날을 기억하시나요?',
        '가족과 함께한 가장 좋았던 여행은요?',
        '부모로서 가장 뿌듯했던 순간은 언제인가요?',
        '가족에게 못다 한 말이 있나요?',
      ],
      'c5': [
        '요즘 하루는 어떻게 보내시나요?',
        '지금 가장 감사한 것은 무엇인가요?',
        '살면서 가장 잘한 선택은 무엇이었나요?',
        '후회되는 일이 있으신가요?',
        '자녀에게 남기고 싶은 말은 무엇인가요?',
        '어떤 사람으로 기억되고 싶으세요?',
      ],
    };

    /// 시작 시점에 이미 답변된 질문 수 — 시안 19번(1장 완성 · 2장 3/8)과 맞춘다.
    const answeredCounts = {'c1': 8, 'c2': 3, 'c3': 0, 'c4': 0, 'c5': 0};

    const seedAnswer =
        '그 시절 우리 집 마당에는 오래된 감나무 한 그루가 서 있었다. 가을이 오면 온 가족이 '
        '그 아래 모여 앉아 이야기를 나누곤 했다.';

    final out = <Question>[];
    for (final entry in texts.entries) {
      final answered = answeredCounts[entry.key] ?? 0;
      for (var i = 0; i < entry.value.length; i++) {
        out.add(
          Question(
            id: '${entry.key}q${i + 1}',
            chapterId: entry.key,
            order: i + 1,
            text: entry.value[i],
            answer: i < answered ? seedAnswer : null,
          ),
        );
      }
    }
    return out;
  }
}
