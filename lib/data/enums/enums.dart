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

/// 자기소개 문항의 답변 방식.
///
/// 서버 계약이 정해지면 wire 값이 붙을 자리다. 지금은 화면이 어떤 입력을
/// 그릴지 정하는 데만 쓴다.
enum IntroAnswerType {
  /// 성함처럼 직접 적거나 말해서 받는 문항
  text,

  /// 예/아니요처럼 버튼을 눌러 고르는 문항. 고르는 즉시 다음으로 넘어간다.
  choice,
}

/// 작성 화면 입력 방식.
///
/// 화면이 어떤 입력을 그릴지 정하는 값이면서, 답변을 보낼 때 **어느 경로로
/// 들어온 글인지** 서버에 함께 알리는 값이기도 하다. 음성으로 받아쓴 글은
/// 사람이 적은 글보다 오탈자가 많아 서버가 다듬는 정도를 달리 잡을 수 있다.
enum ComposeMode {
  voice('voice'),
  keyboard('keyboard');

  const ComposeMode(this.wire);

  final String wire;
}
