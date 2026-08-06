import 'package:life_legacy/data/data_manager.dart';

/// 서버 API 인터페이스 — Nest `/v1` 계약의 앱 측 경계.
///
/// 구현체는 [RealApiClient](real_api_client.dart) 하나다. 컨트롤러는 이 추상
/// 타입만 알고, 빈 목록·404 등은 서버 응답을 그대로 화면에 넘긴다
/// (목업 시드로 채우지 않는다).
///
/// ⚠️ 메서드 이름과 파라미터는 화면이 필요로 하는 단위다. 엔드포인트가 더
///    잘게 쪼개져 있으면 구현체가 여러 호출을 합친다.
abstract interface class ApiClient {
  // ══════════════════════════════════════════════════════════
  // 인증
  // ══════════════════════════════════════════════════════════

  /// 전화번호로 인증번호 발송.
  ///
  /// 유효 시간과 재발송 대기 시간을 **서버가 알려준다** — 기기 시계가 틀어져
  /// 있어도 화면의 남은 시간이 서버 기준으로 맞는다.
  Future<VerificationChallenge> requestVerificationCode(String phone);

  /// 인증번호 확인 → 세션 발급.
  /// 코드가 틀리면 [ApiException]을 던진다(화면이 에러 상태를 그린다).
  Future<AuthSession> verifyCode({required String phone, required String code});

  /// 카카오로 시작하기. [kakaoAccessToken]은 카카오 SDK 로그인으로 얻은 토큰.
  Future<AuthSession> loginWithKakao(String kakaoAccessToken);

  /// 아이디·비밀번호 로그인 (웹 가입 또는 설정에서 만든 계정).
  Future<AuthSession> loginWithCredentials({
    required String loginId,
    required String password,
  });

  /// 카카오/전화 사용자가 설정에서 아이디·비밀번호를 처음 만든다.
  Future<User> setCredentials({
    required String loginId,
    required String password,
  });

  Future<User> me();

  /// 프로필 사진 업로드. 성공 시 갱신된 사용자 정보.
  Future<User> uploadAvatar({
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  });

  /// 프로필 사진 바이너리. 없으면 null.
  Future<List<int>?> fetchAvatarBytes();

  /// 만료된 액세스 토큰을 새것으로 바꾼다.
  ///
  /// 리프레시 토큰도 함께 새것이 온다(rotation) — 받은 쪽은 **둘 다** 갈아
  /// 끼워야 한다. 옛 리프레시 토큰은 서버에서 즉시 폐기된다.
  ///
  /// 리프레시 토큰까지 만료됐으면 `UNAUTHORIZED`로 던진다. 그때는 다시
  /// 로그인하는 수밖에 없다.
  Future<AuthTokens> refreshTokens(String refreshToken);

  Future<void> logout();

  // ── OCTOMO 인증 (신규) ──────────────────────────────────────

  /// 전화번호로 기존 사용자 후보를 조회한다.
  /// 가입 여부와 무관하게 항상 `"verify"`를 반환한다 — 응답만으로 가입 여부를
  /// 알 수 없게 한다.
  Future<PhoneLookupResult> lookupPhone(String phone);

  /// OCTOMO 인증 문자 정보를 발급받는다 — 수신번호, 보낼 문자, 만료 시간.
  Future<OctomoChallenge> requestOctomoChallenge(String phone);

  /// OCTOMO 문자 수신 여부를 폴링한다.
  /// `account`가 `new`면 signup_token과 required_consents가 함께 온다.
  Future<OctomoVerifyResult> verifyOctomo(String sessionId);

  /// 신규 사용자 가입 — 이름 + 약관 동의를 서버에 보내고 세션을 받는다.
  Future<AuthSession> signUp({
    required String signupToken,
    required String name,
    required List<ConsentAgreement> consents,
  });

  /// 현재 시행 중인 약관 문서 목록.
  /// [consentOnly]면 가입 동의 체크 대상만.
  Future<List<ConsentDocument>> consentDocuments({bool consentOnly = false});

  /// 약관 문서 단건 (`terms_of_service` · `privacy_policy` · `refund_policy` 등).
  Future<ConsentDocument> consentDocument(String key);

  // ══════════════════════════════════════════════════════════
  // 자기소개 → 목차 생성
  // ══════════════════════════════════════════════════════════

  /// 목차를 만들기 위한 사전 질문들(시안 07·08번).
  Future<List<IntroQuestion>> introQuestions();

  /// 작성 계획(추천 기간 포함).
  Future<WritingPlanResult> writingPlan();

  /// 작성 계획 저장.
  Future<WritingPlanResult> updateWritingPlan(WritingPlan plan);

  /// 자기소개 답변을 모두 제출하고 목차를 생성한다(시안 09번 로딩).
  /// 서버에서 오래 걸리는 작업이라 화면은 전용 로딩 화면을 띄운다.
  /// 이 시점에 `book_id`가 만들어진다.
  Future<TocGenerateResult> generateToc(List<IntroAnswerSubmission> answers);

  /// 카탈로그 대목차(추가 후보).
  Future<List<CatalogChapter>> catalogChapters(String bookId);

  /// 목차 초안 저장(제목·추가·삭제·재배열).
  Future<List<Chapter>> saveTocDraft({
    required String bookId,
    required List<TocDraftChapter> chapters,
  });

  /// 제안된 목차를 확정한다.
  Future<TocConfirmResult> confirmToc({
    required String bookId,
    required List<Chapter> chapters,
  });

  /// 자기소개 답변을 사람이 읽는 형태로 (시안 F3의 "자기소개" 구획).
  Future<IntroProfile> introProfile();

  // ══════════════════════════════════════════════════════════
  // 홈
  // ══════════════════════════════════════════════════════════

  Future<HomeSummary> home(String bookId);

  // ══════════════════════════════════════════════════════════
  // 작성
  // ══════════════════════════════════════════════════════════

  Future<List<Chapter>> chapters(String bookId);

  /// 지금 답해야 할 질문. 없으면 null(모든 장 완료).
  Future<Question?> currentQuestion(String bookId);

  Future<Question> question(String questionId);

  /// 1차 답변을 보내고 **AI 꼬리질문**을 받는다.
  ///
  /// 아직 확정 저장이 아니다 — 서버는 초안으로만 들고 있다가 꼬리답변까지
  /// 받아야 저장한다([submitFollowupAnswer]).
  ///
  /// AI 호출이 들어 있어 느리다. 화면은 전용 로딩을 띄우고 기다린다.
  ///
  /// 꼬리질문을 만들지 못하면 `FOLLOWUP_FAILED`로 던진다. 이때 서버는
  /// 초안을 버리므로 **사용자는 질문부터 다시 답해야 한다** — 아직 한 번밖에
  /// 답하지 않은 시점이라 감수하기로 한 동작이다.
  Future<Followup> submitAnswer({
    required String questionId,
    required String text,
    required ComposeMode inputMode,
    int? spokenSeconds,
  });

  /// 꼬리답변을 보내 **확정 저장**하고 다음 질문으로 넘어간다.
  /// 다음 질문이 없으면 null(모든 장 완료).
  ///
  /// 서버가 이 호출 안에서 원문 둘을 작가체로 다듬어 저장한다. 다듬은 글은
  /// 돌려주지 않는다 — 작성 화면에서는 보여주지 않기로 했고, 처음 눈에 띄는
  /// 곳은 자서전 미리보기([bookPages])다.
  ///
  /// 저장에 실패하면 `POLISH_FAILED`로 던진다. 이때 서버는 초안을 **남기므로**
  /// 같은 파라미터로 다시 부르면 된다 — 두 번 답한 이야기를 날리지 않는다.
  /// 꼬리답변. 응답에 followup이 있으면 한 번 더, next_question이면 확정.
  Future<FollowupAdvanceResult> submitFollowupAnswer({
    required String questionId,
    required String followupId,
    required String text,
    required ComposeMode inputMode,
    int? spokenSeconds,
  });

  /// 질문 **문구만** 고친다.
  ///
  /// 목차와 질문은 목차 확정 시점에 사용자별로 복제해 두므로, 한 사람이
  /// 고쳐도 다른 사람의 질문은 그대로다.
  ///
  /// 질문을 더하거나 빼거나 순서를 바꾸는 건 1차 범위 밖이다 — 목차 구조가
  /// 흔들리면 장 잠금과 진행률 계산이 같이 흔들린다.
  ///
  /// 이미 답한 질문은 `ALREADY_ANSWERED`로 거절한다. 문구를 바꾸면 저장된
  /// 원고와 어긋나기 때문이다.
  Future<Question> updateQuestionText({
    required String questionId,
    required String text,
  });

  /// 이 질문 건너뛰기.
  Future<Question?> skipQuestion(String questionId);

  /// §5.6 초안 autosave.
  Future<AnswerDraft> saveAnswerDraft({
    required String questionId,
    required String text,
    required ComposeMode inputMode,
    int? spokenSeconds,
  });

  /// 초안 조회. 없으면 null(204).
  Future<AnswerDraft?> answerDraft(String questionId);

  /// 초안 삭제.
  Future<void> deleteAnswerDraft(String questionId);

  // ══════════════════════════════════════════════════════════
  // 챕터 리뷰
  // ══════════════════════════════════════════════════════════

  /// 종합 원고 조회. 없으면 null(204).
  Future<ChapterReview?> chapterReview(String bookId, String chapterId);

  /// 종합 원고 생성(또는 재생성).
  Future<ChapterReview> synthesizeReview(String bookId, String chapterId);

  /// 리뷰 저장 (본문 편집 시 body 포함).
  Future<ChapterReview> saveReview({
    required String bookId,
    required String chapterId,
    required int version,
    String? body,
    String status = 'reviewed',
  });

  /// 문단 뒤 수동 사진 업로드.
  Future<ReviewMedia> uploadReviewMedia({
    required String bookId,
    required String chapterId,
    required int paragraphIndex,
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  });

  /// 사진 배치 삭제.
  Future<void> deleteReviewMedia({
    required String bookId,
    required String chapterId,
    required String placementId,
  });

  /// 사진 바이트 (인증 필요).
  Future<List<int>> fetchReviewMediaBytes({
    required String bookId,
    required String chapterId,
    required String placementId,
  });

  /// AI 챕터 사진 생성/재생성 (1:1).
  Future<AiPhotoResult> generateReviewAiPhoto({
    required String bookId,
    required String chapterId,
    bool regenerate = false,
  });

  /// 챕터 완료 화면. 이탈 후 재진입 시에도 같은 화면을 그린다.
  Future<ChapterCompletion> chapterCompletion(String bookId, String chapterId);

  // ══════════════════════════════════════════════════════════
  // 음성 (Clova — 서버 프록시)
  // ══════════════════════════════════════════════════════════

  /// POST /voice/tts → audio/mpeg 바이트.
  Future<VoiceAudio> synthesizeSpeech({
    required String text,
    String? voiceCode,
  });

  /// POST /voice/stt (multipart audio).
  Future<SttResult> transcribeAudio({
    required List<int> bytes,
    required String filename,
    String contentType = 'audio/mp4',
    int? durationMs,
  });

  /// GET /voice/sample — 보이스 체크용.
  Future<VoiceAudio> voiceSample({String? voiceCode});

  /// POST …/review/tts — 원고 청크.
  Future<VoiceAudio> reviewTts({
    required String bookId,
    required String chapterId,
    int fromParagraph = 0,
    int chunkSize = 2,
    String? voiceCode,
  });

  // ══════════════════════════════════════════════════════════
  // 나의 자서전
  // ══════════════════════════════════════════════════════════

  Future<Book> book(String bookId);

  /// 책 미리보기 쪽들. 완성된 장만 포함한다.
  Future<List<BookPage>> bookPages(String bookId);

  /// 소유 책 목록.
  Future<List<BookListItem>> books();

  /// 기능별 권한 안내 (잠금 UI용 — 접근 통제 아님).
  Future<PlanEntitlements> entitlements(String bookId);

  /// 쿠폰 코드 교환 → T1~T4 플랜 부여.
  Future<CouponRedeemResult> redeemCoupon(String code);

  /// 전자책 자격 (reviewed 장 기준).
  Future<EbookEligibility> ebookEligibility(String bookId);

  /// 전자책 PDF 생성 (스냅샷 재사용 가능).
  Future<EbookExportResult> generateEbook(String bookId);

  /// 전자책 PDF 바이트 (인증 스트림).
  Future<List<int>> downloadEbookFile(String bookId);

  /// AI 제목 추천 (진행률 80%+).
  Future<List<String>> suggestEbookTitles(String bookId);

  /// 전자책 제목 저장.
  Future<void> updateEbookMetadata(String bookId, {required String title});

  /// 오디오북 현황.
  Future<AudiobookOverview> audiobook(String bookId);

  /// CLOVA 음성 목록.
  Future<List<AudiobookVoice>> audiobookVoices(String bookId);

  /// 음성 샘플 (CLOVA TTS).
  Future<List<int>> audiobookVoicePreview(String bookId, String voiceCode);

  /// BGM 카탈로그.
  Future<List<AudiobookBgmTrack>> audiobookBgms(String bookId);

  /// 챕터 오디오북 생성 (백엔드 CLOVA TTS).
  Future<AudiobookJobCreated> createAudiobookJob({
    required String bookId,
    required String chapterId,
    required String voiceCode,
    required String idempotencyKey,
    String? bgmTrackId,
  });

  /// 생성 job 상태.
  Future<AudiobookJobStatus> audiobookJob(String bookId, String jobId);

  /// 생성 job 취소.
  Future<AudiobookJobStatus> cancelAudiobookJob(String bookId, String jobId);

  /// 챕터 오디오 바이트 (재생/다운로드).
  Future<List<int>> audiobookChapterAudio(
    String bookId,
    String chapterId, {
    bool download = false,
  });

  // ══════════════════════════════════════════════════════════
  // 알림
  // ══════════════════════════════════════════════════════════

  /// 헤더 벨 드롭다운에 뜨는 목록. 최신순.
  Future<List<AppNotification>> notifications();

  /// "모두 읽음". 갱신된 목록을 돌려준다.
  Future<List<AppNotification>> markAllNotificationsRead();

  // ══════════════════════════════════════════════════════════
  // 설정
  // ══════════════════════════════════════════════════════════

  Future<AppSettings> settings();

  Future<AppSettings> updateSettings(AppSettings next);

  // ══════════════════════════════════════════════════════════
  // 인쇄본 배송지 (시안 F3 · F4)
  // ══════════════════════════════════════════════════════════

  /// 아직 등록하지 않았으면 빈 값이 채워진 [Address]를 돌려준다 —
  /// null이 아니다. 화면이 "없음"과 "못 불러옴"을 구분할 필요가 없어서다.
  Future<Address> shippingAddress();

  Future<Address> updateShippingAddress(Address next);
}

/// API 오류 — 화면은 [message]만 그대로 보여준다.
///
/// 실제 구현이 들어오면 DioException을 여기로 변환하는 계층이 생긴다.
/// 화면이 dio 타입을 직접 알지 않도록 지금부터 이 타입만 쓴다.
class ApiException implements Exception {
  const ApiException(this.message, {this.code});

  /// 사용자에게 그대로 보여줄 한국어 문장
  final String message;

  /// 화면이 분기해야 할 때 쓰는 식별자 (예: 'INVALID_CODE')
  final String? code;

  @override
  String toString() => 'ApiException($code): $message';
}

// ── OCTOMO 인증 모델 ──────────────────────────────────────────

/// 전화번호 조회 결과.
class PhoneLookupResult {
  const PhoneLookupResult({required this.nextStep});

  /// 항상 `"verify"`.
  final String nextStep;

  factory PhoneLookupResult.fromJson(Map<String, dynamic> json) =>
      PhoneLookupResult(nextStep: json['next_step'] as String? ?? 'verify');
}

/// OCTOMO 챌린지 — 사용자가 문자를 보낼 번호와 내용.
class OctomoChallenge {
  const OctomoChallenge({
    required this.sessionId,
    required this.receiverNumber,
    required this.verifyText,
    required this.expiresIn,
    required this.pollInterval,
  });

  final String sessionId;
  final String receiverNumber;
  final String verifyText;
  final int expiresIn;
  final int pollInterval;

  factory OctomoChallenge.fromJson(Map<String, dynamic> json) =>
      OctomoChallenge(
        sessionId: json['session_id'] as String,
        receiverNumber: json['receiver_number'] as String,
        verifyText: json['verify_text'] as String,
        expiresIn: json['expires_in'] as int? ?? 300,
        pollInterval: json['poll_interval'] as int? ?? 3,
      );
}

/// OCTOMO 폴링 결과.
class OctomoVerifyResult {
  const OctomoVerifyResult({
    required this.status,
    this.account,
    this.session,
    this.signupToken,
    this.requiredConsents = const [],
    this.expiresIn,
  });

  /// `"pending"` 또는 `"verified"`.
  final String status;

  /// `"existing"` 또는 `"new"`. `status`가 `"verified"`일 때만 있다.
  final String? account;

  /// 기존 사용자 — 로그인 세션.
  final AuthSession? session;

  /// 신규 사용자 — 회원가입용 단기 토큰.
  final String? signupToken;

  /// 신규 사용자 — 필수·선택 약관 목록.
  final List<ConsentDocument> requiredConsents;

  /// 남은 유효 시간(초). `pending`일 때만 있다.
  final int? expiresIn;

  bool get isPending => status == 'pending';
  bool get isVerified => status == 'verified';
  bool get isExisting => account == 'existing';
  bool get isNewUser => account == 'new';

  factory OctomoVerifyResult.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String;
    if (status == 'pending') {
      return OctomoVerifyResult(
        status: status,
        expiresIn: json['expires_in'] as int?,
      );
    }
    // verified
    final account = json['account'] as String?;
    return OctomoVerifyResult(
      status: status,
      account: account,
      session: json['session'] != null
          ? AuthSession.fromJson(
              json['session'] as Map<String, dynamic>,
            )
          : null,
      signupToken: json['signup_token'] as String?,
      requiredConsents: (json['required_consents'] as List?)
              ?.map(
                (e) => ConsentDocument.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }
}

/// 약관 문서 정보. 본문(`content`)은 DB 마크다운.
class ConsentDocument {
  const ConsentDocument({
    required this.key,
    required this.version,
    required this.title,
    this.url,
    this.content,
    required this.required,
    this.consentItem = true,
  });

  final String key;
  final String version;
  final String title;
  final String? url;

  /// 마크다운 본문. 없으면 체크만 하거나 URL로 연다.
  final String? content;
  final bool required;

  /// 가입 동의 체크리스트 대상 여부.
  final bool consentItem;

  bool get hasBody =>
      (content != null && content!.trim().isNotEmpty) ||
      (url != null && url!.trim().isNotEmpty);

  factory ConsentDocument.fromJson(Map<String, dynamic> json) =>
      ConsentDocument(
        key: json['key'] as String,
        version: json['version'] as String? ?? '1.0',
        title: json['title'] as String,
        url: json['url'] as String?,
        content: json['content'] as String?,
        required: json['required'] as bool? ?? true,
        consentItem: json['consent_item'] as bool? ?? true,
      );
}

/// 회원가입 시 보낼 약관 동의 항목.
class ConsentAgreement {
  const ConsentAgreement({
    required this.key,
    required this.version,
    required this.agreed,
  });

  final String key;
  final String version;
  final bool agreed;

  Map<String, dynamic> toJson() => {
    'key': key,
    'version': version,
    'agreed': agreed,
  };
}

/// POST /intro/answers 응답.
class TocGenerateResult {
  const TocGenerateResult({
    required this.bookId,
    required this.caseKey,
    required this.chapters,
  });

  final String bookId;
  final String caseKey;
  final List<Chapter> chapters;

  factory TocGenerateResult.fromJson(Map<String, dynamic> json) =>
      TocGenerateResult(
        bookId: json['book_id'] as String,
        caseKey: json['case_key'] as String? ?? '',
        chapters: (json['chapters'] as List)
            .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// POST /intro/toc/confirm 응답.
class TocConfirmResult {
  const TocConfirmResult({
    required this.bookId,
    this.firstQuestionId,
    required this.chapters,
  });

  final String bookId;
  final String? firstQuestionId;
  final List<Chapter> chapters;

  factory TocConfirmResult.fromJson(Map<String, dynamic> json) =>
      TocConfirmResult(
        bookId: json['book_id'] as String,
        firstQuestionId: json['first_question_id'] as String?,
        chapters: (json['chapters'] as List? ?? const [])
            .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// GET /books 목록 항목.
class BookListItem {
  const BookListItem({
    required this.id,
    required this.title,
    required this.authorName,
    required this.status,
    required this.chapterCount,
    required this.chapterDone,
    required this.progress,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String authorName;

  /// draft | writing | completed
  final String status;
  final int chapterCount;
  final int chapterDone;
  final double progress;
  final DateTime updatedAt;

  factory BookListItem.fromJson(Map<String, dynamic> json) => BookListItem(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    authorName: json['author_name'] as String? ?? '',
    status: json['status'] as String? ?? 'draft',
    chapterCount: json['chapter_count'] as int? ?? 0,
    chapterDone: json['chapter_done'] as int? ?? 0,
    progress: (json['progress'] as num?)?.toDouble() ?? 0,
    updatedAt:
        DateTime.tryParse(json['updated_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// GET/PUT /questions/{id}/draft
class AnswerDraft {
  const AnswerDraft({
    required this.questionId,
    required this.phase,
    required this.text,
    required this.inputMode,
    this.spokenSeconds,
    this.followupRound = 0,
    this.pendingFollowup,
  });

  final String questionId;

  /// first | followup
  final String phase;
  final String text;
  final ComposeMode inputMode;
  final int? spokenSeconds;
  final int followupRound;
  final Followup? pendingFollowup;

  bool get isFollowupPhase => phase == 'followup';

  factory AnswerDraft.fromJson(Map<String, dynamic> json) {
    final pending = json['pending_followup'];
    return AnswerDraft(
      questionId: json['question_id'] as String? ?? '',
      phase: json['phase'] as String? ?? 'first',
      text: json['text'] as String? ?? '',
      inputMode: ComposeMode.values.firstWhere(
        (e) => e.wire == json['input_mode'],
        orElse: () => ComposeMode.keyboard,
      ),
      spokenSeconds: json['spoken_seconds'] as int?,
      followupRound: json['followup_round'] as int? ?? 0,
      pendingFollowup: pending is Map<String, dynamic>
          ? Followup.fromJson(pending)
          : null,
    );
  }
}

/// TTS / sample 응답 (mpeg 바이트 + 선택 헤더).
class VoiceAudio {
  const VoiceAudio({
    required this.bytes,
    this.durationMs,
    this.nextParagraph,
  });

  final List<int> bytes;
  final int? durationMs;

  /// 리뷰 TTS 청크: null이면 마지막. -1도 마지막으로 취급.
  final int? nextParagraph;

  bool get hasMore => nextParagraph != null && nextParagraph! >= 0;
}

/// POST …/review/images/generate
class AiPhotoResult {
  const AiPhotoResult({
    required this.media,
    this.regenRemaining = 0,
    this.canRegenerate = false,
  });

  final ReviewMedia media;
  final int regenRemaining;
  final bool canRegenerate;

  factory AiPhotoResult.fromJson(Map<String, dynamic> json) {
    final mediaJson = json['media'];
    final ai = json['ai_photo'] as Map<String, dynamic>? ?? const {};
    return AiPhotoResult(
      media: ReviewMedia.fromJson(
        mediaJson is Map<String, dynamic> ? mediaJson : const {},
      ),
      regenRemaining: ai['regen_remaining'] as int? ??
          json['remaining_generations'] as int? ??
          0,
      canRegenerate: ai['can_regenerate'] as bool? ?? false,
    );
  }
}

class SttResult {
  const SttResult({required this.text, this.durationMs});

  final String text;
  final int? durationMs;

  factory SttResult.fromJson(Map<String, dynamic> json) => SttResult(
    text: json['text'] as String? ?? '',
    durationMs: json['duration_ms'] as int?,
  );
}

