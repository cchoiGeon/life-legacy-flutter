import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

/// 헤더 알림 벨의 안 읽음 개수 배지 (시안 341:585).
///
/// ⚠️ 배지가 48 탭 영역 밖으로 나가면 헤더에서 아바타를 밀어내 시안의
///    벨↔아바타 간격 12가 깨진다. 그래서 폭을 재는 테스트가 있다.
void main() {
  Future<void> pump(WidgetTester tester, int unread) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: AppNotificationBell(unreadCount: unread, onTap: () {}),
        ),
      ),
    ),
  );

  final badge = find.descendant(
    of: find.byType(AppNotificationBell),
    matching: find.byType(Container),
  );

  testWidgets('0건이면 배지 없이 벨만 그린다', (tester) async {
    await pump(tester, 0);

    // 알림이 없다고 벨까지 지우면 알림 센터로 갈 길이 사라진다.
    expect(find.byType(AppIcon), findsOneWidget);
    expect(badge, findsNothing);
  });

  testWidgets('안 읽은 개수를 그대로 적는다', (tester) async {
    await pump(tester, 3);

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('9건까지는 숫자, 10건부터는 9+로 끊는다', (tester) async {
    await pump(tester, 9);
    expect(find.text('9'), findsOneWidget);

    await pump(tester, 10);
    expect(find.text('9+'), findsOneWidget);
    expect(find.text('10'), findsNothing);
  });

  testWidgets('배지는 빨간색이다', (tester) async {
    await pump(tester, 3);

    final d = tester.widget<Container>(badge).decoration as BoxDecoration;
    expect(d.color, AppColors.destructive);
  });

  testWidgets('한 글자면 정원이다', (tester) async {
    await pump(tester, 3);

    // 폭이 글꼴 메트릭에 딸려 가면 안 된다 — 테스트 글꼴에서 20이 나온 적 있다.
    final r = tester.getRect(badge);
    expect(r.width, 18);
    expect(r.height, 18);
  });

  testWidgets('두 글자가 되어도 48 탭 영역 밖으로 나가지 않는다', (tester) async {
    await pump(tester, 10);

    final box = tester.getRect(find.byType(AppNotificationBell));
    final r = tester.getRect(badge);

    expect(box.width, AppDimens.touchMin);
    expect(box.height, AppDimens.touchMin);
    expect(r.width, 22);
    expect(r.right, lessThanOrEqualTo(box.right));
    expect(r.top, greaterThanOrEqualTo(box.top));
  });

  testWidgets('개수는 읽어 줄 때 한 번만 나온다', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, 3);

    // 배지 숫자까지 내보내면 "알림 3건 3"으로 두 번 읽힌다.
    expect(
      tester.getSemantics(find.byType(AppNotificationBell)),
      matchesSemantics(label: '알림 3건', isButton: true, hasTapAction: true),
    );

    handle.dispose();
  });

  testWidgets('0건이면 읽어 줄 때 개수를 붙이지 않는다', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, 0);

    expect(
      tester.getSemantics(find.byType(AppNotificationBell)),
      matchesSemantics(label: '알림', isButton: true, hasTapAction: true),
    );

    handle.dispose();
  });

  testWidgets('누르면 콜백이 온다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppNotificationBell(unreadCount: 3, onTap: () => taps++),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(AppNotificationBell));
    await tester.pump();

    expect(taps, 1);
  });
}
