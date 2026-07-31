import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/common/text/korean_wrap.dart';

/// 한글은 기본적으로 **음절 아무 데서나** 줄이 갈린다.
/// 큰 글씨 제목에서 "남아 계/신 것"처럼 낱말이 두 줄로 쪼개지면 읽기 어렵다.
/// 웹의 `word-break: keep-all`과 같은 규칙을 만든다.
///
/// 기댓값에 쓰인 `⁠`은 폭이 없는 word joiner다. 눈에 보이지 않으므로
/// 이스케이프로 적어 어디에 들어가는지 드러낸다.
void main() {
  test('어절 안의 음절을 묶어 낱말이 쪼개지지 않게 한다', () {
    expect(keepAll('들려주세요'), '들⁠려⁠주⁠세⁠요');
  });

  test('어절 사이 공백은 그대로 둔다 — 거기서 줄이 갈려야 한다', () {
    expect(keepAll('어린 시절'), '어⁠린 시⁠절');
  });

  test('줄바꿈은 건드리지 않는다', () {
    // 시안이 손으로 끊어 둔 자리는 그대로 지킨다.
    expect(
      keepAll('성함을\n알려주세요'),
      '성⁠함⁠을\n알⁠려⁠주⁠세⁠요',
    );
  });

  test('한글이 없는 낱말은 그대로 둔다', () {
    // 영문·숫자는 원래 공백에서만 갈린다. 손댈 이유가 없다.
    expect(keepAll('Life Legacy 2026'), 'Life Legacy 2026');
  });

  test('한글에 붙은 문장부호도 함께 묶인다', () {
    expect(keepAll('안녕하세요?'), '안⁠녕⁠하⁠세⁠요⁠?');
  });

  test('지나치게 긴 낱말은 묶지 않는다', () {
    // 묶어 버리면 줄을 갈 자리가 사라져 화면 밖으로 넘친다.
    // 넘치는 것보다는 어중간하게 갈리는 편이 낫다.
    const long = '가나다라마바사아자차카타파하가나다라마';
    expect(keepAll(long), long);
  });

  test('빈 문자열도 그대로 돌려준다', () {
    expect(keepAll(''), '');
  });

  test('이미 묶인 글을 다시 묶어도 달라지지 않는다', () {
    // 위젯이 두 번 감싸도 길이가 두 배로 뛰어 한도에 걸리면 안 된다.
    final once = keepAll('들려주세요');
    expect(keepAll(once), once);
  });
}
