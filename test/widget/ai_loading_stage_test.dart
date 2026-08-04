import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/feature/write/stages/ai_loading_stage.dart';
import 'package:life_legacy/feature/write/write_controller.dart';
import 'package:life_legacy/service/services.dart';

import '../support/test_env.dart';

/// D7 꼬리질문 준비 중 · D8 이야기 정리 중 — Figma 398:6 / 398:30.
///
/// 시안 실측을 그대로 잠근다. B6(목차 준비 중)과 같은 덩어리라 숫자가 어긋나면
/// 두 화면이 미묘하게 달라 보인다.
void main() {
  setUpAll(() => initTestEnv('ai_loading_stage'));

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Get.put<WriteController>(
      WriteController(MockApiClient(), SpeechService(), ToastService(), VoicePlayerService()),
    );
    addTearDown(Get.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AiLoadingStage())),
    );
    await tester.pump(const Duration(milliseconds: 1200));
  }

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('크림 바탕이 화면을 가득 채운다', (tester) async {
    await pump(tester);

    // ⚠️ 작성 화면(D1~D5)은 흰 바탕이지만 대기 화면은 크림이다(시안 398:6).
    //    Scaffold 기본색을 그대로 쓰면 흰 화면이 된다.
    final colored = find
        .descendant(
          of: find.byType(AiLoadingStage),
          matching: find.byType(ColoredBox),
        )
        .first;
    expect(tester.widget<ColoredBox>(colored).color, AppColors.cream);

    // 색만 맞고 크기를 안 채우면 크림이 글자 뒤에만 깔린다 —
    // 실기기에서 화면 왼쪽 위만 크림이고 나머지가 흰색으로 나왔다.
    expect(tester.getSize(colored), const Size(390, 844));

    await teardown(tester);
  });

  testWidgets('덩어리가 가로 가운데에 온다', (tester) async {
    await pump(tester);

    expect(tester.getRect(find.byType(AppWaitingRing)).center.dx, 195);

    await teardown(tester);
  });

  testWidgets('대기 덩어리가 시안 자리(위에서 274)에서 시작한다', (tester) async {
    await pump(tester);

    // 가운데 정렬이 아니다 — 시안 398:7이 y=274에 놓여 있다.
    expect(tester.getRect(find.byType(AppWaitingRing)).top, 274);

    await teardown(tester);
  });

  testWidgets('링은 116, 그 안 브랜드 마크는 76이다', (tester) async {
    await pump(tester);

    expect(tester.getSize(find.byType(AppWaitingRing)), const Size(116, 116));
    expect(tester.getSize(find.byType(AppBrandMark)), const Size(76, 76));

    await teardown(tester);
  });

  testWidgets('간격은 링 아래 34 · 제목 아래 14 · 부제 아래 40이다', (tester) async {
    await pump(tester);

    final ring = tester.getRect(find.byType(AppWaitingRing));
    final title = tester.getRect(find.text('말씀을 듣고 있어요'));
    final subtitle = tester.getRect(find.text('조금만 더\n여쭤볼게요'));
    final note = tester.getRect(find.text('말씀해 주신 이야기는 잘 담아 두었어요'));

    expect(title.top - ring.bottom, 34);
    expect(subtitle.top - title.bottom, 14);
    expect(note.top - subtitle.bottom, 40);

    await teardown(tester);
  });

  testWidgets('글자는 시안 크기·색을 따른다', (tester) async {
    await pump(tester);

    final title = tester.widget<Text>(find.text('말씀을 듣고 있어요'));
    expect(title.style?.fontSize, 25);
    expect(title.style?.color, AppColors.textPrimary);

    final subtitle = tester.widget<Text>(find.text('조금만 더\n여쭤볼게요'));
    expect(subtitle.style?.fontSize, 16);
    expect(subtitle.style?.height, 28 / 16);
    expect(subtitle.style?.color, AppColors.textStrong);

    final note = tester.widget<Text>(
      find.text('말씀해 주신 이야기는 잘 담아 두었어요'),
    );
    expect(note.style?.fontSize, 13);
    expect(note.style?.color, AppColors.textTertiary);

    await teardown(tester);
  });
}
