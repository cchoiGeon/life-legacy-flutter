import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';
import 'chat_stage.dart' show AiBadge;

/// 17 AI 글 다듬기 — Figma 151:246.
///
/// 다듬은 결과는 **명조체**로 보여준다. 자서전에 실제로 실릴 모습 그대로를
/// 미리 보여주려는 것이다(시안도 본문 서체가 다르다).
class PolishStage extends GetView<WriteController> {
  const PolishStage({super.key});

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
                const SizedBox(height: AppDimens.space2),
                const AiBadge(),
                const SizedBox(height: AppDimens.space3),
                Text('글로 옮겨 봤어요', style: AppTypography.titlePage),
                const SizedBox(height: AppDimens.space5),
                Obx(
                  () => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimens.space5),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                    ),
                    child: Text(
                      controller.draft.value?.polished ?? '',
                      style: AppTypography.bookBody,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.space6),
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
                  label: '좋아요, 다음 질문',
                  size: AppButtonSize.lg,
                  block: true,
                  loading: controller.isBusy.value,
                  onPressed: controller.save,
                ),
              ),
              const SizedBox(height: AppDimens.space3),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => AppButton(
                        label: '다시 다듬기',
                        variant: AppButtonVariant.neutral,
                        size: AppButtonSize.lg,
                        block: true,
                        enabled: !controller.isBusy.value,
                        onPressed: controller.repolish,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.space3),
                  Expanded(
                    child: AppButton(
                      label: '직접 고치기',
                      variant: AppButtonVariant.neutral,
                      size: AppButtonSize.lg,
                      block: true,
                      onPressed: controller.startEditing,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
