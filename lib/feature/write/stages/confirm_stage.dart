import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';

/// 16 답변 확인 — Figma 151:221.
///
/// 음성이든 키보드든 저장 직전에 한 번 보여준다. 저장한 글은 그대로
/// 자서전에 실리므로, 잘못 들었거나 잘못 적은 걸 되돌릴 자리가 필요하다.
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
                Obx(
                  () => Text(
                    controller.answerSource.value == WriteStage.keyboard
                        ? '이렇게 적으셨어요'
                        : '이렇게 들었어요',
                    style: AppTypography.titlePage,
                  ),
                ),
                const SizedBox(height: AppDimens.space3),
                Obx(
                  () => Text(
                    controller.answerSource.value == WriteStage.keyboard
                        ? '맞으면 다음으로 넘어가고,\n아니면 다시 고쳐 주세요.'
                        : '맞으면 다음으로 넘어가고,\n아니면 다시 말씀해 주세요.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
              Obx(
                () => AppButton(
                  label: controller.retryLabel,
                  variant: AppButtonVariant.neutral,
                  size: AppButtonSize.lg,
                  block: true,
                  onPressed: controller.retryAnswer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
