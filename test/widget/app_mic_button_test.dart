import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

/// 녹음 버튼 — Figma 341:660(대기) · 350:889(녹음 중).
///
/// "지금 듣고 있다"는 신호를 **버튼 둘레의 원형 파형**이 맡는다.
/// 예전에는 버튼 위 막대 파형과 아래 "듣고 있어요 · 0:23"이 그 일을 했는데,
/// 세로로 자리를 두 군데나 먹어서 작은 화면이 깨졌다.
void main() {
  Future<void> pump(WidgetTester tester, {required bool recording}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppMicButton(recording: recording, onTap: () {}),
            ),
          ),
        ),
      );

  testWidgets('녹음 중이면 버튼 둘레에 원형 파형이 생긴다', (tester) async {
    await pump(tester, recording: true);

    expect(find.byKey(AppMicButton.ringKey), findsOneWidget);
  });

  testWidgets('대기 중에는 파형이 없다', (tester) async {
    await pump(tester, recording: false);

    expect(find.byKey(AppMicButton.ringKey), findsNothing);
  });

  testWidgets('파형은 자리를 차지하지 않는다', (tester) async {
    await pump(tester, recording: false);
    final idle = tester.getRect(find.byType(AppMicButton));

    await pump(tester, recording: true);
    final busy = tester.getRect(find.byType(AppMicButton));

    // 자리를 차지하면 녹음을 시작하는 순간 마이크가 위로 밀린다 —
    // 방금 누른 버튼이 손 밑에서 움직이는 셈이다.
    expect(busy, idle);
  });

  testWidgets('녹음 중에만 움직인다', (tester) async {
    await pump(tester, recording: false);
    expect(tester.hasRunningAnimations, isFalse);

    await pump(tester, recording: true);
    expect(tester.hasRunningAnimations, isTrue, reason: '멈춰 있으면 듣는 중인지 알 수 없다');

    // 애니메이션이 계속 돌면 테스트가 끝나지 않는다.
    await pump(tester, recording: false);
  });
}
