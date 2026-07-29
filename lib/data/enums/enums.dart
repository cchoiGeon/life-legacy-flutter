/// 도메인 열거형 모음.
///
/// ⚠️ 서버 계약이 정해지지 않아 wire 값(`_wire`)은 **가정**이다.
///    실제 API가 정해지면 `_wire` 문자열만 고치면 되고, 화면 코드는
///    enum 값만 보므로 영향이 없다.
library;

/// 장(章)의 진행 상태.
enum ChapterStatus {
  /// 아직 열리지 않음 — 앞 장을 끝내야 열린다
  locked('locked'),

  /// 작성 중
  writing('writing'),

  /// 모든 질문 답변 완료
  done('done');

  const ChapterStatus(this.wire);

  final String wire;

  static ChapterStatus fromWire(String? v) =>
      ChapterStatus.values.firstWhere((e) => e.wire == v, orElse: () => locked);
}

/// 채팅 말풍선 주체.
enum ChatRole {
  ai('ai'),
  user('user');

  const ChatRole(this.wire);

  final String wire;

  static ChatRole fromWire(String? v) =>
      ChatRole.values.firstWhere((e) => e.wire == v, orElse: () => ai);
}

/// 작성 화면 입력 방식.
///
/// 서버와 무관한 **클라이언트 전용** 상태다. 시니어 사용자가 음성을 기본으로
/// 쓰되 언제든 키보드로 바꿀 수 있어야 해서 화면이 이 값을 들고 있는다.
enum ComposeMode { voice, keyboard }
