import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'stages/ai_loading_stage.dart';
import 'stages/ask_stage.dart';
import 'stages/confirm_stage.dart';
import 'stages/followup_failed_stage.dart';
import 'stages/keyboard_stage.dart';
import 'stages/recording_stage.dart';
import 'write_controller.dart';

/// D1~D5 작성 — Figma 341:646 · 350:875 · 351:874 · 351:964 · 354:1035.
///
/// ⚠️ **탭바가 없다.** 작성은 탭 중 하나지만 시안의 다섯 프레임 어디에도
///    탭바가 그려져 있지 않다. 말하거나 적는 동안 다른 탭이 눈에 들어오면
///    하던 이야기를 놓치기 때문이다. 나가는 길은 상단 `←` 하나다.
class WriteView extends GetView<WriteController> {
  const WriteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: AppSpinner()),
        );
      }

      if (controller.isAllDone.value) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: _AllDone(),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        // 글자 입력 단계에서만 키보드가 올라온다.
        resizeToAvoidBottomInset:
            controller.stage.value == WriteStage.keyboard,
        body: switch (controller.stage.value) {
          WriteStage.ask => const AskStage(),
          WriteStage.recording => const RecordingStage(),
          WriteStage.keyboard => const KeyboardStage(),
          WriteStage.confirm => const ConfirmStage(),
          // D6·D7은 같은 화면이고 문구만 바뀐다 — 사용자가 보기엔 둘 다
          // "기다리는 중"이라 서로 다른 그림을 만들 이유가 없다.
          WriteStage.generatingFollowup ||
          WriteStage.saving => const AiLoadingStage(),
          WriteStage.followupFailed => const FollowupFailedStage(),
        },
      );
    });
  }
}

/// 모든 장을 끝냈을 때. 시안에 대응 프레임이 없어 최소한으로 만들었다.
class _AllDone extends StatelessWidget {
  const _AllDone();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const AppTopBar(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.gutter,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 64,
                      color: AppColors.accentSoft,
                    ),
                    const SizedBox(height: AppDimens.space5),
                    const Text(
                      '모든 질문에 답하셨어요',
                      style: AppTypography.titleSerifSm,
                    ),
                    const SizedBox(height: AppDimens.space3),
                    Text(
                      '이제 완성된 책을 확인해 보세요',
                      style: AppTypography.subtitle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
