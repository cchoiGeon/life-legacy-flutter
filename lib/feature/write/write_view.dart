import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/feature/shared/tab_scaffold.dart';

import 'stages/ask_stage.dart';
import 'stages/chat_stage.dart';
import 'stages/confirm_stage.dart';
import 'stages/edit_stage.dart';
import 'stages/polish_stage.dart';
import 'stages/recording_stage.dart';
import 'write_controller.dart';

/// 13~18 작성 — Figma 148:170 ~ 152:246.
///
/// 단계에 따라 몸통이 바뀐다. 탭바는 13번(대기)에서만 보인다 — 나머지
/// 단계는 답변 중이라 탭을 옮길 자리가 아니다(시안도 그렇게 그려져 있다).
class WriteView extends GetView<WriteController> {
  const WriteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const TabScaffold(
          tab: AppTab.write,
          body: Center(child: AppSpinner()),
        );
      }

      if (controller.isAllDone.value) {
        return const TabScaffold(tab: AppTab.write, body: _AllDone());
      }

      return switch (controller.stage.value) {
        WriteStage.ask => const TabScaffold(
          tab: AppTab.write,
          body: AskStage(),
        ),
        WriteStage.recording => const Scaffold(
          backgroundColor: AppColors.background,
          body: RecordingStage(),
        ),
        WriteStage.chat => const Scaffold(
          backgroundColor: AppColors.stone50,
          resizeToAvoidBottomInset: true,
          body: ChatStage(),
        ),
        WriteStage.confirm => const Scaffold(
          backgroundColor: AppColors.background,
          body: ConfirmStage(),
        ),
        WriteStage.polish => const Scaffold(
          backgroundColor: AppColors.background,
          body: PolishStage(),
        ),
        WriteStage.edit => const Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: true,
          body: EditStage(),
        ),
      };
    });
  }
}

/// 모든 장을 끝냈을 때. 시안에 대응 프레임이 없어 최소한으로 만들었다.
class _AllDone extends StatelessWidget {
  const _AllDone();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: AppColors.accentSoft,
            ),
            const SizedBox(height: AppDimens.space5),
            Text(
              '모든 질문에 답하셨어요',
              style: AppTypography.weight(
                AppTypography.headingXl,
                AppTypography.bold,
              ),
            ),
            const SizedBox(height: AppDimens.space3),
            Text(
              '이제 완성된 책을 확인해 보세요',
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
