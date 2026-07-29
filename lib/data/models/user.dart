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
