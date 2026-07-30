import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

/// 자기소개 선택지(B2~B5).
///
/// ⚠️ 예전에는 고른 표시를 **일부러 하지 않았다**(한쪽만 진해지면 기본값처럼
///    보인다는 이유). 시안이 이걸 뒤집었다 — 고른 뒤 하단 "다음"을 눌러야
///    넘어가므로 무엇을 골랐는지 화면에 남아야 한다.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool selected,
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppChoiceTile(
          label: '여성',
          selected: selected,
          height: AppChoiceTile.heightFor(2),
          onTap: onTap ?? () {},
        ),
      ),
    ),
  );

  BoxDecoration decoration(WidgetTester tester) =>
      tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration
          as BoxDecoration;

  testWidgets('고르지 않았으면 흰 바탕에 연한 테두리다', (tester) async {
    await pump(tester, selected: false);
    final d = decoration(tester);

    expect(d.color, AppColors.background);
    expect((d.border as Border).top.color, AppColors.borderSoft);
  });

  testWidgets('고른 쪽은 크림으로 채워지고 테두리가 브랜드색이 된다', (tester) async {
    await pump(tester, selected: true);
    final d = decoration(tester);

    expect(d.color, AppColors.cream);
    expect((d.border as Border).top.color, AppColors.borderSelected);
  });

  testWidgets('고른 쪽은 글자도 브랜드색이 된다', (tester) async {
    await pump(tester, selected: true);

    final text = tester.widget<Text>(find.text('여성'));
    expect(text.style?.color, AppColors.brand);
  });

  testWidgets('누르면 콜백이 온다', (tester) async {
    var taps = 0;
    await pump(tester, selected: false, onTap: () => taps++);

    await tester.tap(find.text('여성'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('선택지가 둘이면 96, 셋 이상이면 74로 줄어든다', (tester) async {
    expect(AppChoiceTile.heightFor(2), 96);
    expect(AppChoiceTile.heightFor(4), 74);
  });

  testWidgets('접근성에 선택 상태가 실린다', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, selected: true);

    // 색만으로 고른 걸 알리면 스크린리더 사용자에게는 아무 표시가 없다.
    expect(
      tester.getSemantics(find.byType(AppChoiceTile)),
      matchesSemantics(
        label: '여성', // 라벨이 "여성 여성"으로 겹치지 않아야 한다
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );

    handle.dispose();
  });
}
