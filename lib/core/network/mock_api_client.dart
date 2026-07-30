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

  /// 다음 [saveAnswer] 한 번을 실패시킨다 — 시안 D5(저장 실패)를 눈으로
  /// 확인하기 위한 스위치다. 작성 화면 `⋯` 메뉴에서 켠다.
  ///
  /// ⚠️ 실제 구현에는 없을 코드다. 실패는 네트워크가 만들지 우리가 만들지 않는다.
  bool failNextSave = false;

  late List<Chapter> _chapters = _seedChapters();
  late List<Question> _questions = _seedQuestions();

  /// 자기소개 답변 — F3(내 정보)의 "자기소개" 구획이 읽는다.
  /// 목차를 만들 때 [generateToc]가 통째로 받아 둔다.
  Map<String, String> _introAnswers = const {
    'i2': '여성',
    'i3': '했어요',
    'i4': '있어요',
    'i5': '고등학교',
  };

  // ══════════════════════════════════════════════════════════
  // 인증
  // ══════════════════════════════════════════════════════════

  @override
  Future<void> requestVerificationCode(String phone) => _delay(null);

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
      accessToken: 'mock-token',
      user: _user,
      // 목차가 아직 확정되지 않았으면 자기소개부터 시작한다.
      needsIntro: !Storage.introDone,
    );
  }

  @override
  Future<AuthSession> loginWithKakao() => _delay(
    AuthSession(
      accessToken: 'mock-token-kakao',
      user: _user,
      needsIntro: !Storage.introDone,
    ),
  );

  @override
  Future<User> me() => _delay(_user);

  @override
  Future<void> logout() => _delay(null);

  /// 시안 343:713은 "2분 47초 남음"으로 그려져 있다 — 3분에서 13초 지난 모습이다.
  @override
  Duration get verificationCodeTtl => const Duration(minutes: 3);

  // ══════════════════════════════════════════════════════════
  // 자기소개 → 목차
  // ══════════════════════════════════════════════════════════

  /// 시안 B1~B5. 문항 순서를 바꾸거나 지우면 [generateToc]의 이름 저장과
  /// [introProfile]의 라벨 대응도 같이 손봐야 한다.
  @override
  Future<List<IntroQuestion>> introQuestions() => _delay(const [
    IntroQuestion(
      id: 'i1',
      order: 1,
      text: '성함을\n알려주세요',
      subtitle: '책 표지에 들어갈 이름이에요',
      hint: '성함을 적어 주세요',
    ),
    IntroQuestion(
      id: 'i2',
      order: 2,
      text: '성별을\n알려주세요',
      subtitle: '책에서 부르는 말을 정할 때 써요',
      type: IntroAnswerType.choice,
      choices: ['여성', '남성'],
    ),
    IntroQuestion(
      id: 'i3',
      order: 3,
      text: '결혼은\n하셨나요?',
      subtitle: '가족 이야기를 여쭤볼 때 참고해요',
      type: IntroAnswerType.choice,
      choices: ['했어요', '안 했어요'],
    ),
    IntroQuestion(
      id: 'i4',
      order: 4,
      text: '자녀가\n있으신가요?',
      subtitle: '자녀 이야기를 여쭤볼지 정해요',
      type: IntroAnswerType.choice,
      choices: ['있어요', '없어요'],
    ),
    IntroQuestion(
      id: 'i5',
      order: 5,
      text: '학교는 어디까지\n다니셨나요?',
      subtitle: '학창 시절 질문을 고를 때 써요',
      type: IntroAnswerType.choice,
      choices: ['초등학교', '중학교', '고등학교', '대학교 이상'],
    ),
  ]);

  @override
  Future<List<Chapter>> generateToc(Map<String, String> answers) {
    // 실제로는 답변을 보고 목차를 만들겠지만, 여기서는 고정 목차를 돌려준다.
    // 대신 사용자가 이름을 말했으면 그걸 반영해서 "만들어진 느낌"을 준다.
    final name = answers['i1']?.trim();
    if (name != null && name.isNotEmpty) {
      _user = User(id: _user.id, name: name, phone: _user.phone);
    }
    _introAnswers = Map.of(answers);
    return _delay(_seedChapters(), _slowLatency);
  }

  @override
  Future<void> confirmToc(List<Chapter> chapters) async {
    await Future<void>.delayed(_latency);
    // 순서를 바꿨을 수 있으니 order를 다시 매긴다 — 화면은 이 번호로
    // "제2장 이어서 쓰기"를 그린다.
    _chapters = [
      for (final (i, c) in chapters.indexed)
        Chapter(
          id: c.id,
          order: i + 1,
          title: c.title,
          status: c.status,
          answeredCount: c.answeredCount,
          questionCount: c.questionCount,
        ),
    ];
    _questions = _seedQuestions();
    await Storage.markIntroDone();
  }

  @override
  Future<IntroProfile> introProfile() => _delay(
    IntroProfile(
      entries: [
        for (final (id, label) in _profileLabels)
          if (_introAnswers[id] case final v? when v.trim().isNotEmpty)
            IntroProfileEntry(label: label, value: v),
      ],
    ),
  );

  /// 자기소개 문항 id → F3에 뜨는 라벨. 성함(i1)은 "기본 정보"에 따로 나가므로 뺀다.
  static const _profileLabels = [
    ('i2', '성별'),
    ('i3', '결혼'),
    ('i4', '자녀'),
    ('i5', '학력'),
  ];

  // ══════════════════════════════════════════════════════════
  // 홈
  // ══════════════════════════════════════════════════════════

  @override
  Future<HomeSummary> home() {
    final next = _findCurrentQuestion();
    final total = _questions.length;
    final answered = _questions.where((q) => q.isAnswered).length;
    return _delay(
      HomeSummary(
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
  Future<List<Chapter>> chapters() => _delay(_syncChapters());

  @override
  Future<Question?> currentQuestion() => _delay(_findCurrentQuestion());

  @override
  Future<Question> question(String questionId) =>
      _delay(_questions.firstWhere((q) => q.id == questionId));

  @override
  Future<Question?> saveAnswer({
    required String questionId,
    required String text,
  }) async {
    await Future<void>.delayed(_latency);
    if (failNextSave) {
      failNextSave = false;
      throw const ApiException('저장하지 못했어요', code: 'SAVE_FAILED');
    }
    final i = _questions.indexWhere((q) => q.id == questionId);
    if (i >= 0) _questions[i] = _questions[i].copyWith(answer: text);
    _syncChapters();
    return _findCurrentQuestion();
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

  // ══════════════════════════════════════════════════════════
  // 나의 자서전
  // ══════════════════════════════════════════════════════════

  @override
  Future<Book> book() {
    _syncChapters();
    final done = _chapters.every((c) => c.status == ChapterStatus.done);
    return _delay(
      Book(
        // 시안 352:954의 표지 — 제목은 "나의 이야기", 아래에 이름이 들어간다.
        title: '나의 이야기',
        authorName: _user.name,
        chapterCount: _chapters.length,
        questionCount: _questions.length,
        // 답변 하나당 대략 6쪽으로 잡은 눈속임 값이다.
        pageCount: _questions.where((q) => q.isAnswered).length * 6,
        // 사진 첨부(시안 G)를 아직 만들지 않아 고정값이다.
        photoCount: 0,
        isComplete: done,
      ),
    );
  }

  @override
  Future<List<BookPage>> bookPages() {
    // 쪽 번호는 책 전체를 통틀어 매긴다 — 미리보기 하단이 "12 / 34쪽"으로
    // 전체 대비 위치를 보여주기 때문이다. 앞의 10쪽은 표지·목차 몫이다.
    const frontMatter = 10;
    final chunks = <(Chapter, List<String>)>[];
    for (final c in _syncChapters()) {
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
