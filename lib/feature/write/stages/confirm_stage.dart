import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';

/// 16 답변 확인 — Figma 151:221.
///
/// 받아쓴 원문이 맞는지 먼저 확인받는다. 음성 인식이 틀린 채로 AI가
/// 다듬어 버리면 사용자가 무엇이 잘못됐는지 알기 어렵기 때문이다.
class ConfirmStage extends GetView<WriteController> {
  const ConfirmStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTopBar(onBack: controller.retryAnswer),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimens.space4),
                Text('이렇게 들었어요', style: AppTypography.titlePage),
                const SizedBox(height: AppDimens.space3),
                Text(
                  '맞으면 다음으로 넘어가고,\n아니면 다시 말씀해 주세요.',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.space6),
                Obx(
                  () => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimens.space4),
                    decoration: BoxDecoration(
                      color: AppColors.bubbleSys,
                      borderRadius: BorderRadius.circular(
                        AppDimens.radiusBubble,
                      ),
                    ),
                    child: Text(
                      controller.transcript.value,
                      style: AppTypography.bodyBase.copyWith(
                        color: AppColors.textStrong,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.gutter,
            0,
            AppDimens.gutter,
            AppDimens.space5,
          ),
          child: Column(
            children: [
              Obx(
                () => AppButton(
                  label: '네, 맞아요',
                  size: AppButtonSize.lg,
                  block: true,
                  loading: controller.isBusy.value,
                  onPressed: controller.confirmTranscript,
                ),
              ),
              const SizedBox(height: AppDimens.space3),
              AppButton(
                label: '다시 말할게요',
                variant: AppButtonVariant.neutral,
                size: AppButtonSize.lg,
                block: true,
                onPressed: controller.retryAnswer,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
