import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/feature/write/stages/question_panel.dart';

/// 질문판이 1차 질문과 꼬리질문을 다르게 그리는 규칙 (시안 341:654).
///
/// 꼬리질문은 AI가 요약·공감한 뒤 되묻는 글이라 원래 질문의 서너 배다.
/// 시안의 고정 높이 244를 그대로 두면 화면 밖으로 넘친다.
void main() {
  const short = '어린 시절 살던 동네는 어떤 모습이었나요?';
  const long =
      '말씀해 주신 장면이 눈에 그려집니다. 그 시간이 지금까지도 마음에 남아 계신 것 같아요. '
      '그때 곁에 누가 함께 있었는지, 기억나는 대로 조금만 더 들려주시겠어요? '
      '작은 이야기라도 괜찮으니 떠오르는 대로 말씀해 주세요.';

  Future<void> pump(
    WidgetTester tester, {
    required String question,
    String? badge,
    bool tall = true,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            QuestionPanel(question: question, badge: badge, tall: tall),
          ],
        ),
      ),
    ),
  );

  testWidgets('1차 질문에는 배지가 붙지 않는다', (tester) async {
    await pump(tester, question: short);

    expect(find.text(short), findsOneWidget);
    expect(find.text('이어서 여쭤볼게요'), findsNothing);
  });

  testWidgets('꼬리질문에는 배지가 붙는다', (tester) async {
    await pump(tester, question: long, badge: '이어서 여쭤볼게요');

    expect(find.text('이어서 여쭤볼게요'), findsOneWidget);
  });

  testWidgets('1차 질문은 시안 높이 244를 지킨다', (tester) async {
    await pump(tester, question: short);

    expect(tester.getSize(find.byType(QuestionPanel)).height, 244);
  });

  testWidgets('긴 꼬리질문도 화면을 넘기지 않는다', (tester) async {
    await pump(tester, question: long, badge: '이어서 여쭤볼게요');

    // 844 화면에서 마이크·버튼 자리를 남겨야 한다. 넘치면 렌더 오버플로가
    // 나고 tester가 예외로 잡는다.
    expect(
      tester.getSize(find.byType(QuestionPanel)).height,
      lessThanOrEqualTo(330.0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('글자 입력 화면에서는 긴 꼬리질문을 줄여 보여준다', (tester) async {
    await pump(tester, question: long, badge: '이어서 여쭤볼게요', tall: false);

    // 입력칸에 자리를 내줘야 해서 전문을 펼치지 않는다.
    final text = tester.widget<Text>(find.text(long));
    expect(text.maxLines, 4);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('글자 입력 화면의 1차 질문은 줄 수를 제한하지 않는다', (tester) async {
    await pump(tester, question: short, tall: false);

    expect(tester.widget<Text>(find.text(short)).maxLines, isNull);
  });
}
