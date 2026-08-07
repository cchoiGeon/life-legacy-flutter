/// 한글 줄바꿈을 **어절 단위**로 묶는다.
///
/// 한글은 유니코드 줄바꿈 규칙상 음절 아무 데서나 줄이 갈린다. 본문에서는
/// 그게 정상이지만(한국 책도 그렇게 조판한다), 큰 글씨 제목에서 낱말이
/// 쪼개지면 눈에 걸린다 —
///
///   ❌  그 시간이 지금까지도 마음에 남아 계
///       신 것 같아요.
///
///   ✅  그 시간이 지금까지도 마음에
///       남아 계신 것 같아요.
///
/// 시니어 대상이라 글씨가 크고 한 줄에 들어가는 글자가 적어서 더 자주
/// 생긴다. 웹의 `word-break: keep-all`과 같은 규칙이다.
library;

/// 줄이 갈리지 못하게 붙이는 보이지 않는 글자 (U+2060 WORD JOINER).
///
/// ZWSP(U+200B)와 반대다 — 이쪽은 "여기서 끊지 마라"는 뜻이고, 폭이 없어
/// 화면에 아무 자국도 남기지 않는다.
const _wordJoiner = '⁠';

/// 낱말 하나가 이보다 길면 묶지 않는다.
///
/// 전부 묶어 버리면 줄을 갈 자리가 사라져 긴 낱말이 화면 밖으로 넘친다.
/// 어중간하게 갈리는 것보다 넘치는 쪽이 훨씬 나쁘다. 한글 어절은 대개
/// 2~6음절이라 이 선에 걸리는 경우는 거의 없다.
const _maxWordLength = 12;

/// [text]의 어절 안쪽을 묶어 낱말이 두 줄로 쪼개지지 않게 한다.
///
/// 공백과 줄바꿈은 그대로 둔다 — 줄은 거기서 갈려야 한다.
/// 한글이 없는 낱말(영문·숫자)은 원래 공백에서만 갈리므로 손대지 않는다.
///
/// **본문에는 쓰지 않는다.** 책 미리보기처럼 긴 산문은 음절 단위로 갈리는
/// 편이 오히려 자연스럽고, 어절을 묶으면 오른쪽 여백이 들쭉날쭉해진다.
String keepAll(String text) {
  if (text.isEmpty) return text;

  return text.splitMapJoin(
    RegExp(r'[^\s]+'),
    onMatch: (m) => _joinWord(m[0]!),
    onNonMatch: (s) => s,
  );
}

/// 문장 끝에서 줄바꿈한 뒤 어절 단위로 묶는다 — 작성 질문 표시용.
///
/// 구두점(`.?!` 및 전각)과 흔한 한국어 종결 뒤에서 줄을 갈라, 가운데
/// 정렬·큰 글씨에서도 읽기 쉽게 한다. 이미 있는 `\n`은 유지한다.
String formatQuestionText(String text) {
  if (text.isEmpty) return text;
  return keepAll(_breakAtSentences(text));
}

String _breakAtSentences(String text) {
  var s = text.replaceAll('\r\n', '\n');

  // 구두점 뒤 공백 → 줄바꿈
  s = s.replaceAllMapped(
    RegExp(r'([.?!。？！])[ \t]+'),
    (m) => '${m[1]}\n',
  );
  // 구두점 바로 다음 글자(공백 없이 이어진 경우)
  s = s.replaceAllMapped(
    RegExp(r'([.?!。？！])(?=[^\n\s.?!。？！])'),
    (m) => '${m[1]}\n',
  );
  // 한국어 종결 + 공백 (이미 줄바꿈된 자리는 건드리지 않음)
  s = s.replaceAllMapped(
    RegExp(
      r'(요|다|까|죠|네요|습니다|습니까|세요|예요|이에요)[ \t]+(?=\S)',
    ),
    (m) => '${m[1]}\n',
  );

  // 연속 빈 줄은 하나로
  return s.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

String _joinWord(String word) {
  if (!_hasHangul(word)) return word;

  // 이미 묶인 글자는 세지 않는다 — 두 번 부르면 길이가 두 배로 뛰어
  // 멀쩡한 낱말이 한도에 걸린다.
  final bare = word.replaceAll(_wordJoiner, '');
  if (bare.length > _maxWordLength) return word;

  return bare.split('').join(_wordJoiner);
}

/// 한글 음절(가~힣)과 자모를 모두 본다.
bool _hasHangul(String s) =>
    RegExp(r'[가-힣ᄀ-ᇿ㄰-㆏]').hasMatch(s);
