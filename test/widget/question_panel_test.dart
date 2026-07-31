import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/common/text/korean_wrap.dart';
import 'package:life_legacy/feature/write/stages/question_panel.dart';

/// 질문판이 1차 질문과 꼬리질문을 다르게 그리는 규칙 (시안 341:654).
///
/// 꼬리질문은 AI가 요약·공감한 뒤 되묻는 글이라 원래 질문의 서너 배다.
/// 시안의 고정 높이 244를 그대로 두면 화면 밖으로 넘친다.
/// "다시 들려주기"의 누르는 상자(글자 + 상하 4 패딩).
final _replayBox = find.ancestor(
  of: find.text('다시 들려주기'),
  matching: find.byType(GestureDetector),
);

void main() {
  const short = '어린 시절 살던 동네는 어떤 모습이었나요?';

  /// 꼬리질문의 실제 모양 — 요약·공감 뒤에 빈 줄, 그다음이 묻는 문장이다.
  const question = '그때 곁에 누가 함께 있었는지, 기억나는 대로 조금만 더 들려주시겠어요?';
  const long =
      '말씀해 주신 장면이 눈에 그려집니다. 그 시간이 지금까지도 마음에 남아 계신 것 같아요.\n\n'
      '$question';

  Future<void> pump(
    WidgetTester tester, {
    required String question,
    String? badge,
    bool tall = true,
    VoidCallback? onReplay,
  }) async {
    // ⚠️ 기본 테스트 화면은 800x600이라 질문판이 두 배 넓게 그려진다. 그러면
    //    글이 절반의 줄 수로 접혀서 "넘치는" 상황이 재현되지 않는다.
    //    시안과 같은 390 폭으로 맞춘다.
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // 바깥은 Align으로 감싼다 — Column으로 감싸면 질문판 안의 Column과
          // 섞여서 어느 쪽을 잡았는지 알 수 없다.
          body: Align(
            alignment: Alignment.topCenter,
            child: QuestionPanel(
              question: question,
              badge: badge,
              tall: tall,
              onReplay: onReplay,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('1차 질문에는 배지가 붙지 않는다', (tester) async {
    await pump(tester, question: short);

    expect(find.text(keepAll(short)), findsOneWidget);
    expect(find.text('이어서 여쭤볼게요'), findsNothing);
  });

  testWidgets('질문은 어절이 쪼개지지 않게 묶어서 그린다', (tester) async {
    await pump(tester, question: short);

    // 큰 글씨라 한 줄에 들어가는 글자가 적다. 그대로 두면 "들려/주세요"처럼
    // 낱말 한가운데서 줄이 갈린다.
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, contains('⁠'));
    expect(text.data, keepAll(short));
  });

  testWidgets('꼬리질문에는 배지가 붙는다', (tester) async {
    await pump(tester, question: long, badge: '이어서 여쭤볼게요');

    expect(find.text('이어서 여쭤볼게요'), findsOneWidget);
  });

  testWidgets('1차 질문은 시안 높이 244를 지킨다', (tester) async {
    await pump(tester, question: short);

    expect(tester.getSize(find.byType(QuestionPanel)).height, 244);
  });

  testWidgets('질문과 "다시 들려주기"가 한 덩어리로 판 가운데에 놓인다', (tester) async {
    await pump(tester, question: short, onReplay: () {});

    // 가운데로 오는 건 질문 글자가 아니라 **덩어리 전체**다. 질문만 가운데에
    // 두면 아래 "다시 들려주기"가 밀려 내려가 둘이 따로 놀아 보인다.
    // 위아래 여백이 같은지로 잰다.
    final panel = tester.getRect(find.byType(QuestionPanel));
    final text = tester.getRect(find.text(keepAll(short)));
    // 글자 상자가 아니라 **누르는 상자**를 잰다 — 링크에는 위아래 4 패딩이
    // 붙어 있어서 글자 기준으로 재면 그만큼 어긋나 보인다.
    final link = tester.getRect(_replayBox);

    expect(text.top - panel.top, closeTo(panel.bottom - link.bottom, 2.0));
    expect(text.center.dy, lessThan(panel.center.dy), reason: '글자는 덩어리 위쪽이다');
  });

  testWidgets('"다시 들려주기"가 없으면 질문이 곧 덩어리다', (tester) async {
    await pump(tester, question: short);

    final panel = tester.getRect(find.byType(QuestionPanel));
    final text = tester.getRect(find.text(keepAll(short)));
    expect(text.center.dy, closeTo(panel.center.dy, 1.0));
  });

  testWidgets('글이 길어져도 "다시 들려주기"는 판 안에 남는다', (tester) async {
    // 판(최대 348)을 확실히 넘기는 길이. 실기기의 꼬리질문이 이만큼 된다.
    const overflowing =
        '말씀해 주신 장면이 눈에 그려집니다. 그 시간이 지금까지도 마음에 남아 계신 것 같아요. '
        '함께한 분들 얼굴도 떠오르시는 듯합니다.\n\n'
        '그때 곁에 누가 함께 있었는지, 기억나는 대로 조금만 더 들려주시겠어요? '
        '작은 이야기라도 괜찮으니 떠오르는 대로 말씀해 주세요.';
    await pump(tester, question: overflowing, badge: '이어서 여쭤볼게요', onReplay: () {});

    // 스크롤 안에 함께 넣으면 긴 꼬리질문에 밀려 화면 밖으로 잘린다.
    // 스크롤하는 건 글이고, 이 링크는 판 아래에 남아 있어야 한다.
    final panel = tester.getRect(find.byType(QuestionPanel));
    final link = tester.getRect(_replayBox);

    expect(link.top, greaterThanOrEqualTo(panel.top));
    expect(link.bottom, lessThanOrEqualTo(panel.bottom));
  });

  testWidgets('긴 꼬리질문도 화면을 넘기지 않는다', (tester) async {
    await pump(tester, question: long, badge: '이어서 여쭤볼게요');

    // 844 화면에서 마이크·버튼 자리를 남겨야 한다. 넘치면 렌더 오버플로가
    // 나고 tester가 예외로 잡는다.
    expect(
      tester.getSize(find.byType(QuestionPanel)).height,
      lessThanOrEqualTo(348.0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('글자 입력 화면은 꼬리질문의 "묻는 문장"만 남긴다', (tester) async {
    await pump(tester, question: long, badge: '이어서 여쭤볼게요', tall: false);

    // 꼬리질문은 [요약·공감] 빈 줄 [질문] 꼴로 온다. 입력칸에 자리를 내주려고
    // 앞에서부터 잘라 버리면 정작 물어보는 문장이 사라진다 — 뒤쪽만 남긴다.
    expect(find.text(keepAll(question)), findsOneWidget);
    expect(find.text(keepAll(long)), findsNothing);
  });

  testWidgets('빈 줄이 없는 꼬리질문은 통째로 두되 줄 수를 제한한다', (tester) async {
    const flat = '말씀해 주신 장면이 눈에 그려집니다. 그때 곁에 누가 함께 있었는지 조금만 더 들려주시겠어요?';
    await pump(tester, question: flat, badge: '이어서 여쭤볼게요', tall: false);

    final text = tester.widget<Text>(find.text(keepAll(flat)));
    expect(text.maxLines, 4);
    expect(text.overflow, TextOverflow.ellipsis);
  });

  testWidgets('글자 입력 화면의 1차 질문은 줄 수를 제한하지 않는다', (tester) async {
    await pump(tester, question: short, tall: false);

    expect(tester.widget<Text>(find.text(keepAll(short))).maxLines, isNull);
  });
}
