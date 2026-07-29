import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/route/app_pages.dart';

import 'preview_controller.dart';

/// 21 완성 — Figma 154:325.
class BookCompleteView extends GetView<BookPreviewController> {
  const BookCompleteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: AppSpinner());
          }
          final book = controller.book.value;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
            child: Column(
              children: [
                const SizedBox(height: AppDimens.space10),
                Text(
                  '✦',
                  style: AppTypography.weight(
                    AppTypography.headingXl,
                    AppTypography.bold,
                  ).copyWith(color: AppColors.warm, fontSize: 28),
                ),
                const SizedBox(height: AppDimens.space4),
                Text(
                  '축하드려요!\n한 권의 책이 완성됐어요',
                  textAlign: TextAlign.center,
                  style: AppTypography.titlePage,
                ),
                const SizedBox(height: AppDimens.space3),
                Text(
                  book == null
                      ? ''
                      : '총 ${book.chapterCount}장 · ${book.pageCount}쪽 · ${book.title}',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.space8),
                _Cover(title: book?.title ?? ''),
                const SizedBox(height: AppDimens.space10),
                AppButton(
                  label: '책 넘겨보기',
                  size: AppButtonSize.lg,
                  block: true,
                  onPressed: () => Get.toNamed(AppRoutes.bookPreview),
                ),
                const SizedBox(height: AppDimens.space3),
                AppButton(
                  label: '인쇄본 신청하기',
                  variant: AppButtonVariant.neutral,
                  size: AppButtonSize.lg,
                  block: true,
                  onPressed: controller.orderPrint,
                ),
                const SizedBox(height: AppDimens.space4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: controller.sendToFamily,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.space2),
                    child: Text(
                      '가족에게 전자책 보내기',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.space8),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// 책 표지 — 브랜드색 사각형에 제목을 얹은 형태.
class _Cover extends StatelessWidget {
  const _Cover({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 188,
      height: 244,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppDimens.space5),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
          topRight: Radius.circular(AppDimens.radiusBase),
          bottomRight: Radius.circular(AppDimens.radiusBase),
        ),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '자 서 전',
            style: AppTypography.caption.copyWith(
              color: AppColors.brandFg.withValues(alpha: 0.7),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: AppDimens.space5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bookTitle.copyWith(
              color: AppColors.brandFg,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}
