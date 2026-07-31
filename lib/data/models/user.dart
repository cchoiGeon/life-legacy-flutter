/// 로그인한 사용자.
///
/// ⚠️ 서버 계약 미확정. 필드명은 snake_case 응답을 가정했다.
///    실제 스키마가 정해지면 `fromJson`만 고치면 된다.
class User {
  const User({
    required this.id,
    required this.name,
    required this.phone,
    this.childLinked = false,
  });

  final String id;

  /// 표시 이름. "영희 님, 오늘도 반가워요"처럼 인사에 쓴다.
  final String name;

  /// 010 1234 5678 형식(하이픈 없음)
  final String phone;

  /// 자녀 계정 연결 여부 (설정 화면)
  final bool childLinked;

  /// 아바타 원 안에 넣는 한 글자. 이름 마지막 글자가 아니라 **성**을 쓴다
  /// — 시안의 "김영희" → "김".
  String get initial => name.isEmpty ? '?' : name.substring(0, 1);

  /// "영희 님" 처럼 성을 뗀 호칭.
  /// 한국 이름은 대개 성이 한 글자라 그 규칙을 따랐다.
  /// ⚠️ 두 글자 성(남궁·황보 등)은 잘못 잘린다. 서버가 given_name을 주면
  ///    그 값을 쓰도록 바꿀 것.
  String get givenName => name.length > 1 ? name.substring(1) : name;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    childLinked: json['child_linked'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'child_linked': childLinked,
  };
}

/// 인증번호 발송 결과.
///
/// ⚠️ 두 시간은 **다른 것**이다. [expiresIn]은 번호가 언제까지 유효한지고,
///    [resendAfter]는 "다시 받기"를 언제부터 누를 수 있는지다. 하나로 묶으면
///    문자가 안 온 사람이 만료될 때까지 아무것도 못 하게 된다.
class VerificationChallenge {
  const VerificationChallenge({
    required this.expiresIn,
    required this.resendAfter,
  });

  /// 인증번호 유효 시간. 화면의 "2분 47초 남음"이 여기서 나온다.
  final Duration expiresIn;

  /// 재발송이 열릴 때까지 남은 시간.
  final Duration resendAfter;

  factory VerificationChallenge.fromJson(Map<String, dynamic> json) =>
      VerificationChallenge(
        expiresIn: Duration(seconds: json['expires_in'] as int? ?? 180),
        resendAfter: Duration(seconds: json['resend_after'] as int? ?? 30),
      );

  Map<String, dynamic> toJson() => {
    'expires_in': expiresIn.inSeconds,
    'resend_after': resendAfter.inSeconds,
  };
}

/// 로그인 결과 — 토큰과 사용자, 그리고 다음에 가야 할 화면 정보.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
    required this.needsIntro,
  });

  final String accessToken;
  final User user;

  /// 자기소개(목차 생성)를 아직 안 한 신규 사용자면 true.
  /// 스플래시·로그인 후 분기의 유일한 근거다.
  final bool needsIntro;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['access_token'] as String,
    user: User.fromJson(json['user'] as Map<String, dynamic>),
    needsIntro: json['needs_intro'] as bool? ?? false,
  );
}
