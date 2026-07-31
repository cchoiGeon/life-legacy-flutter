import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/common/text/korean_wrap.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

/// 화면 제목(A·B·D4·F 전 화면)의 줄바꿈 규칙.
///
/// 자기소개 문항·답변 확인 제목이 전부 이 위젯을 지난다. 명조 28이라
/// 한 줄에 들어가는 글자가 적어서, 그대로 두면 낱말이 두 줄로 쪼개진다.
void main() {
  Future<void> pump(WidgetTester tester, String title, {String? subtitle}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppScreenHeading(title: title, subtitle: subtitle),
          ),
        ),
      );

  testWidgets('제목은 어절이 쪼개지지 않게 묶어서 그린다', (tester) async {
    const title = '성함을 알려주세요';
    await pump(tester, title);

    expect(find.text(keepAll(title)), findsOneWidget);
    expect(find.text(title), findsNothing);
  });

  testWidgets('시안이 손으로 끊은 줄바꿈은 그대로 지킨다', (tester) async {
    await pump(tester, '학교는 어디까지\n다니셨나요?');

    final text = tester.widget<Text>(find.byType(Text).first);
    expect(text.data, contains('\n'));
  });

  testWidgets('부제도 같은 규칙을 따른다', (tester) async {
    const subtitle = '책 표지에 들어갈 이름이에요';
    await pump(tester, '성함을', subtitle: subtitle);

    expect(find.text(keepAll(subtitle)), findsOneWidget);
  });
}
