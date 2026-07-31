import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/feature/write/question_edit_sheet.dart';

/// D10 질문 문구 고치기 시트.
void main() {
  const question = '친구들과의 추억 하나를 들려주세요.';

  /// 시트를 띄우고, 닫힐 때 나온 값을 담아 둔다.
  Future<List<String?>> open(WidgetTester tester) async {
    final results = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showQuestionEditSheet(context, question: question),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('지금 질문이 미리 채워져 있다', (tester) async {
    await open(tester);

    // 처음부터 다시 적게 하면 긴 문장을 통째로 타이핑해야 한다.
    expect(find.text(question), findsOneWidget);
  });

  testWidgets('버튼은 시트 폭을 가득 채운다', (tester) async {
    await open(tester);

    // 앱의 다른 시트·화면이 전부 전체 폭 버튼이다. 여기만 글자 크기에
    // 맞춰 쪼그라들면 누르는 자리가 좁아지고 화면이 낯설어진다.
    final sheetWidth = tester.getSize(find.byType(AppField)).width;
    for (final label in ['이렇게 고칠게요', '그만두기']) {
      expect(
        tester.getSize(find.widgetWithText(AppButton, label)).width,
        sheetWidth,
        reason: '$label 버튼이 폭을 채워야 한다',
      );
    }
  });

  testWidgets('고친 문구를 돌려준다', (tester) async {
    final results = await open(tester);

    await tester.enterText(find.byType(AppField), '친구와 어떤 추억이 있으신가요?');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, '이렇게 고칠게요'));
    await tester.pumpAndSettle();

    expect(results.single, '친구와 어떤 추억이 있으신가요?');
  });

  testWidgets('그만두면 아무것도 돌려주지 않는다', (tester) async {
    final results = await open(tester);

    await tester.enterText(find.byType(AppField), '고치다 말았어요');
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, '그만두기'));
    await tester.pumpAndSettle();

    expect(results.single, isNull, reason: '고치다 만 글이 저장되면 안 된다');
  });

  testWidgets('빈 문구로는 고칠 수 없다', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(AppField), '   ');
    await tester.pump();

    expect(
      tester.widget<AppButton>(find.widgetWithText(AppButton, '이렇게 고칠게요')).enabled,
      isFalse,
    );
  });
}
