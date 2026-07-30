import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

/// 숫자 키패드(A3~A6)는 OS 키보드를 대신한다. 눌린 키가 그대로 전해지지
/// 않으면 전화번호를 넣을 방법이 아예 없어진다.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<String> digits,
    required List<int> backspaces,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AppNumberPad(
          onDigit: digits.add,
          onBackspace: () => backspaces.add(1),
        ),
      ),
    ),
  );

  testWidgets('0~9와 지우기가 모두 그려진다', (tester) async {
    await pump(tester, digits: [], backspaces: []);

    for (var i = 0; i <= 9; i++) {
      expect(find.text('$i'), findsOneWidget, reason: '$i 키가 없다');
    }
    expect(find.text('⌫'), findsOneWidget);
  });

  testWidgets('숫자를 누르면 그 숫자가 전해진다', (tester) async {
    final digits = <String>[];
    await pump(tester, digits: digits, backspaces: []);

    await tester.tap(find.text('7'));
    await tester.tap(find.text('0'));
    await tester.pump();

    expect(digits, ['7', '0']);
  });

  testWidgets('지우기는 숫자가 아니라 지우기로 전해진다', (tester) async {
    final digits = <String>[];
    final backspaces = <int>[];
    await pump(tester, digits: digits, backspaces: backspaces);

    await tester.tap(find.text('⌫'));
    await tester.pump();

    expect(backspaces, hasLength(1));
    expect(digits, isEmpty);
  });

  testWidgets('왼쪽 아래 빈 칸은 눌러도 아무 일이 없다', (tester) async {
    final digits = <String>[];
    final backspaces = <int>[];
    await pump(tester, digits: digits, backspaces: backspaces);

    // 빈 칸은 마지막 줄 맨 왼쪽이다 — "0" 키와 같은 높이의 화면 왼쪽 끝.
    final zero = tester.getCenter(find.text('0'));
    await tester.tapAt(Offset(20, zero.dy));
    await tester.pump();

    expect(digits, isEmpty);
    expect(backspaces, isEmpty);
  });
}
