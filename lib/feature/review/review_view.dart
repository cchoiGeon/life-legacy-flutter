import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'review_controller.dart';

/// 05 챕터 리뷰 — 종합 원고 읽기·저장.
class ReviewView extends GetView<ReviewController> {
  const ReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppSpinner());
        }

        if (controller.isSaved.value) {
          return _SavedPanel(controller: controller);
        }

        final review = controller.review.value;
        if (review == null) {
          return SafeArea(
            child: Column(
              children: [
                AppTopBar(onBack: () => Get.back()),
                const Expanded(
                  child: Center(child: Text('원고를 불러오지 못했어요')),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppTopBar(
                title: controller.headerTitle,
                onBack: () => Get.back(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.gutter,
                    12,
                    AppDimens.gutter,
                    24,
                  ),
                  children: [
                    Text(
                      review.editHint,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (final (i, p) in review.paragraphs.indexed) ...[
                      if (i > 0) const SizedBox(height: 22),
                      Text(
                        p,
                        style: AppTypography.bookBody.copyWith(
                          height: 30 / 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  8,
                  AppDimens.gutter,
                  AppInsets.bottom(context, 22),
                ),
                child: Column(
                  children: [
                    AppButton(
                      label: '읽어주기',
                      size: AppButtonSize.md,
                      block: true,
                      variant: AppButtonVariant.outline,
                      onPressed: controller.playTts,
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => AppButton(
                        label: '저장하기',
                        size: AppButtonSize.lg,
                        block: true,
                        loading: controller.isSaving.value,
                        onPressed: controller.save,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SavedPanel extends StatelessWidget {
  const _SavedPanel({required this.controller});

  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          48,
          AppDimens.gutter,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppScreenHeading(
              title: controller.saveDoneMessage,
              subtitle: '나중에 수정 가능해요',
            ),
            const Spacer(),
            AppButton(
              label: '다음 장 이어서 쓰기',
              size: AppButtonSize.lg,
              block: true,
              onPressed: controller.goWrite,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: '홈으로 이동',
              size: AppButtonSize.lg,
              block: true,
              variant: AppButtonVariant.outline,
              onPressed: controller.goBookHub,
            ),
          ],
        ),
      ),
    );
  }
}
