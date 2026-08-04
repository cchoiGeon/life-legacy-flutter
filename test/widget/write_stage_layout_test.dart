import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/feature/write/stages/ask_stage.dart';
import 'package:life_legacy/feature/write/stages/question_panel.dart';
import 'package:life_legacy/feature/write/stages/recording_stage.dart';
import 'package:life_legacy/feature/write/write_controller.dart';
import 'package:life_legacy/service/services.dart';

import '../support/test_env.dart';

/// D1(대기)과 D2(녹음 중)는 **같은 자리에 같은 크기로** 서 있어야 한다.
///
/// 말하는 동안에도 질문을 보며 답해야 하고, 방금 누른 버튼이 손 밑에서
/// 움직이면 다시 누르려다 엉뚱한 곳을 누른다.
void main() {
  setUpAll(() => initTestEnv('write_stage_layout'));

  /// 화면 하나를 세우고 [measure]로 잰 값을 돌려준다.
  Future<T> render<T>(
    WidgetTester tester, {
    required bool recording,
    required T Function(WidgetTester) measure,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Get.put<WriteController>(
      WriteController(MockApiClient(), SpeechService(), ToastService(), VoicePlayerService()),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: recording ? const RecordingStage() : const AskStage(),
        ),
      ),
    );
    // 목업이 질문과 장을 돌려줄 때까지(450 + 450).
    // 파문이 계속 도니 pumpAndSettle은 못 쓴다.
    await tester.pump(const Duration(milliseconds: 1200));

    final result = measure(tester);

    // 애니메이션과 컨트롤러를 정리하지 않으면 다음 테스트로 새어 나간다.
    await tester.pumpWidget(const SizedBox.shrink());
    Get.reset();
    // 남아 있는 목업 타이머를 흘려보낸다. 안 그러면 "Pending timers"로 깨진다.
    await tester.pump(const Duration(seconds: 1));
    return result;
  }

  double panelHeight(WidgetTester t) =>
      t.getSize(find.byType(QuestionPanel)).height;

  testWidgets('녹음을 시작해도 질문판이 작아지지 않는다', (tester) async {
    final idle = await render(tester, recording: false, measure: panelHeight);
    final busy = await render(tester, recording: true, measure: panelHeight);

    // 받아쓴 글에 자리를 내주느라 질문이 줄어들면, 정작 답할 때 질문이 안 보인다.
    expect(busy, idle);
  });

  testWidgets('녹음을 시작해도 마이크가 움직이지 않는다', (tester) async {
    Rect micRect(WidgetTester t) => t.getRect(find.byType(AppMicButton));

    final idle = await render(tester, recording: false, measure: micRect);
    final busy = await render(tester, recording: true, measure: micRect);

    expect(busy, idle);
  });
}
