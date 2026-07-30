import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

/// 인증번호 칸(A5·A6)은 **표시 전용**이다. 값은 키패드가 넣는다.
///
/// 칸 뒤에 숨은 입력칸을 두면 눌렀을 때 OS 키보드가 올라와 앱 키패드와
/// 겹친다 — 그래서 [TextField]가 하나도 없어야 한다.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required String value,
    bool hasError = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppCodeBoxes(value: value, hasError: hasError),
      ),
    ),
  );

  /// 칸 테두리 색을 읽는다.
  List<Color> borderColors(WidgetTester tester) => tester
      .widgetList<Container>(find.byType(Container))
      .map((c) => c.decoration)
      .whereType<BoxDecoration>()
      .map((d) => (d.border as Border?)?.top.color)
      .whereType<Color>()
      .toList();

  testWidgets('입력을 받지 않는다 — 숨은 입력칸이 없어야 한다', (tester) async {
    await pump(tester, value: '123');

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('입력된 숫자만 칸에 뜬다', (tester) async {
    await pump(tester, value: '123');

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
  });

  testWidgets('다음에 채울 칸만 브랜드색으로 굵어진다', (tester) async {
    await pump(tester, value: '123');

    final colors = borderColors(tester);
    expect(colors, hasLength(6));
    expect(colors[3], AppColors.borderSelected, reason: '커서 칸');
    expect(colors[2], AppColors.borderSoft, reason: '이미 채운 칸');
    expect(colors[4], AppColors.borderSoft, reason: '아직 빈 칸');
  });

  testWidgets('에러면 여섯 칸이 모두 빨개진다 — 커서 표시는 사라진다', (tester) async {
    await pump(tester, value: '123459', hasError: true);

    final colors = borderColors(tester);
    expect(colors, everyElement(AppColors.destructive));
  });

  testWidgets('여섯 자리를 넘는 값이 들어와도 여섯 칸만 그린다', (tester) async {
    await pump(tester, value: '12345678');

    expect(borderColors(tester), hasLength(6));
    expect(find.text('7'), findsNothing);
  });

  testWidgets('칸 높이는 시안 실측(64)이다', (tester) async {
    await pump(tester, value: '');

    final box = tester.widgetList<Container>(find.byType(Container)).first;
    expect(box.constraints?.maxHeight, AppDimens.fieldHeight);
  });
}
