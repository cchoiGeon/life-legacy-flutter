import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/shared/app_shell.dart';

import 'preview_controller.dart';

/// E3 자서전 완성 — Figma 352:949.
///
/// 모든 장을 끝냈을 때 자서전 탭이 보여주는 화면. 탭바가 남아 있어
/// 여기서 다른 탭으로 나갈 수 있다(시안 352:962).
class BookCompleteView extends GetView<BookPreviewController> {
  const BookCompleteView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: AppSpinner());
          }
          final book = controller.book.value;
          if (book == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              60,
              AppDimens.gutter,
              AppDimens.space6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '자서전이 완성됐어요',
                  style: AppTypography.titleScreen,
                ),
                const SizedBox(height: 8),
                Text(
                  book.completionCaption,
                  // 시안 352:951 — 여기는 한 줄 높이가 24다.
                  style: AppTypography.subtitle.copyWith(height: 24 / 16),
                ),
                const SizedBox(height: 38),
                Center(child: _Cover(book: book)),
                const SizedBox(height: 56),
                AppButton(
                  label: '종이책으로 주문하기',
                  size: AppButtonSize.lg,
                  block: true,
                  onPressed: controller.orderPrint,
                ),
                const SizedBox(height: 14),
                Obx(
                  () => AppButton(
                    label: controller.isSharing.value
                        ? '공유 준비 중…'
                        : '가족에게 보내기',
                    variant: AppButtonVariant.neutral,
                    size: AppButtonSize.secondary,
                    block: true,
                    enabled: !controller.isSharing.value,
                    onPressed: controller.sendToFamily,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  book.summary,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// 책 표지 — Figma 352:952.
///
/// 왼쪽 7px 띠가 책등이다. 검정 22% 를 덮어 브랜드색을 어둡게 만든다 —
/// 별도 색 토큰을 두지 않은 건 표지 색이 바뀌어도 따라오게 하려는 것이다.
class _Cover extends StatelessWidget {
  const _Cover({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      height: 274,
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(4),
        boxShadow: AppShadows.lg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 7,
            child: ColoredBox(
              color: AppColors.foreground.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            left: 24,
            right: 16,
            top: 92,
            child: Column(
              children: [
                Text(
                  book.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.bookTitle.copyWith(
                    fontSize: 21,
                    height: 1.3,
                    letterSpacing: -0.2,
                    color: AppColors.brandFg,
                  ),
                ),
                const SizedBox(height: 22),
                Container(width: 36, height: 1, color: AppColors.btnMuted),
                const SizedBox(height: 19),
                Text(
                  book.authorName,
                  textAlign: TextAlign.center,
                  style: AppTypography.bookBody.copyWith(
                    fontSize: 14,
                    height: 1.5,
                    letterSpacing: 0.4,
                    color: AppColors.btnMuted,
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
