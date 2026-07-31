import 'package:life_legacy/data/data_manager.dart';

/// 서버 API 인터페이스 — **이 파일이 교체 지점이다.**
///
/// 지금은 [MockApiClient](mock_api_client.dart)가 유일한 구현이고, 모든
/// 컨트롤러는 이 추상 타입만 알고 있다. 실제 API가 정해지면:
///
///   1. pubspec에 dio · retrofit · json_annotation 추가
///   2. 모델의 `fromJson`을 실제 응답 스키마에 맞게 수정
///      (또는 `@JsonSerializable`로 바꾸고 코드 생성)
///   3. `RealApiClient implements ApiClient` 를 새로 작성
///   4. `main.dart`의 `Get.put<ApiClient>(MockApiClient())` 한 줄만 교체
///
/// 화면·컨트롤러는 **한 줄도 고치지 않는다.**
///
/// ⚠️ 메서드 이름과 파라미터는 서버 계약이 아니라 **화면이 필요로 하는 것**을
///    기준으로 잡았다. 실제 엔드포인트가 더 잘게 쪼개져 있으면 구현체가
///    여러 호출을 합쳐서 이 모양으로 맞춰준다.
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

  /// 카카오로 시작하기.
  Future<AuthSession> loginWithKakao();

  Future<User> me();

  Future<void> logout();


  // ══════════════════════════════════════════════════════════
  // 자기소개 → 목차 생성
  // ══════════════════════════════════════════════════════════

  /// 목차를 만들기 위한 사전 질문들(시안 07·08번).
  Future<List<IntroQuestion>> introQuestions();

  /// 자기소개 답변을 모두 제출하고 목차를 생성한다(시안 09번 로딩).
  /// 서버에서 오래 걸리는 작업이라 화면은 전용 로딩 화면을 띄운다.
  Future<List<Chapter>> generateToc(Map<String, String> answers);

  /// 제안된 목차를 확정한다(시안 B7 "이대로 시작하기").
  ///
  /// 사용자가 "순서 바꾸기"로 재배열했으면 바뀐 순서 그대로 넘어온다 —
  /// 구현체가 `order`를 다시 매겨 저장해야 한다.
  Future<void> confirmToc(List<Chapter> chapters);

  /// 자기소개 답변을 사람이 읽는 형태로 (시안 F3의 "자기소개" 구획).
  Future<IntroProfile> introProfile();

  // ══════════════════════════════════════════════════════════
  // 홈
  // ══════════════════════════════════════════════════════════

  Future<HomeSummary> home();

  // ══════════════════════════════════════════════════════════
  // 작성
  // ══════════════════════════════════════════════════════════

  Future<List<Chapter>> chapters();

  /// 지금 답해야 할 질문. 없으면 null(모든 장 완료).
  Future<Question?> currentQuestion();

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
  Future<Question?> submitFollowupAnswer({
    required String questionId,
    required String followupId,
    required String text,
    required ComposeMode inputMode,
    int? spokenSeconds,
  });

  /// 이 질문 건너뛰기.
  Future<Question?> skipQuestion(String questionId);

  // ══════════════════════════════════════════════════════════
  // 나의 자서전
  // ══════════════════════════════════════════════════════════

  Future<Book> book();

  /// 책 미리보기 쪽들. 완성된 장만 포함한다.
  Future<List<BookPage>> bookPages();

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
