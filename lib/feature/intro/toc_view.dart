import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'toc_controller.dart';

/// 10 목차 제안 확인 — Figma 145:97.
class TocView extends GetView<TocController> {
  const TocView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimens.space4),
                  Text('이런 순서로\n이야기를 담아볼게요', style: AppTypography.titlePage),
                  const SizedBox(height: AppDimens.space3),
                  Text(
                    '자기소개를 바탕으로 목차를 만들었어요. 마음에 들면 시작해요.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space6),
                  Obx(
                    () => Container(
                      decoration: BoxDecoration(
                        color: AppColors.brandFg,
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusCard,
                        ),
                        border: Border.all(color: AppColors.stone200),
                      ),
                      child: Column(
                        children: [
                          for (final (i, c) in controller.chapters.indexed) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: AppColors.stone100,
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.space4,
                                vertical: AppDimens.space4,
                              ),
                              child: Row(
                                children: [
                                  AppChapterBadge(
                                    number: c.order,
                                    active: false,
                                    size: 26,
                                  ),
                                  const SizedBox(width: AppDimens.space3),
                                  Expanded(
                                    child: Text(
                                      c.title,
                                      style: AppTypography.weight(
                                        AppTypography.titleSection,
                                        AppTypography.medium,
                                      ).copyWith(color: AppColors.textStrong),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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
                    label: '이 목차로 시작하기',
                    size: AppButtonSize.lg,
                    block: true,
                    loading: controller.isConfirming.value,
                    onPressed: controller.confirm,
                  ),
                ),
                const SizedBox(height: AppDimens.space3),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.regenerate,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.space2),
                    child: Text(
                      '목차 바꿔줄게요',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
