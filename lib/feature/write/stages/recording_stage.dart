import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';

/// 14 음성 모드 · 녹음 중 — Figma 149:201.
///
/// 탭바도 상단바도 없다. 말하는 동안 다른 곳으로 새지 않게 하려는 의도라
/// 그대로 따랐다.
class RecordingStage extends GetView<WriteController> {
  const RecordingStage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
        child: Column(
          children: [
            const SizedBox(height: AppDimens.space6),
            Text(
              controller.headerTitle,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const Spacer(flex: 2),
            Text(
              controller.question.value?.text ?? '',
              textAlign: TextAlign.center,
              style: AppTypography.weight(
                AppTypography.headingXl,
                AppTypography.medium,
              ).copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            AppMicButton(recording: true, onTap: controller.stopRecording),
            const SizedBox(height: AppDimens.space5),
            const SizedBox(width: 160, child: AppWaveform()),
            const SizedBox(height: AppDimens.space6),
            Text(
              '듣고 있어요…',
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.space2),
            Obx(
              () => Text(
                _mmss(controller.elapsed.value),
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const Spacer(flex: 2),
            Obx(
              () => AppButton(
                label: '■  멈춤',
                size: AppButtonSize.lg,
                block: true,
                loading: controller.isBusy.value,
                onPressed: controller.stopRecording,
              ),
            ),
            const SizedBox(height: AppDimens.space5),
          ],
        ),
      ),
    );
  }

  /// 12 → "0:12"
  static String _mmss(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
