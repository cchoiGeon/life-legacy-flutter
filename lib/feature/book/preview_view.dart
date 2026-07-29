import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'preview_controller.dart';

/// 20 책 미리보기 — Figma 154:292.
///
/// 배경을 크림색으로 깔고 흰 종이를 얹어 책장처럼 보이게 한다.
class BookPreviewView extends GetView<BookPreviewController> {
  const BookPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppSpinner());
        }
        final page = controller.page;
        return Column(
          children: [
            AppTopBar(
              title: '책 미리보기',
              background: AppColors.cream,
              trailing: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.share,
                child: const Padding(
                  padding: EdgeInsets.all(AppDimens.space2),
                  child: Icon(
                    Icons.ios_share_rounded,
                    size: 20,
                    color: AppColors.stone500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: page == null
                  ? _EmptyBook()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.gutter,
                        AppDimens.space2,
                        AppDimens.gutter,
                        AppDimens.space4,
                      ),
                      child: _Paper(page: page),
                    ),
            ),
            if (page != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  0,
                  AppDimens.gutter,
                  AppDimens.space5,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: '◀  이전 장',
                        variant: AppButtonVariant.neutral,
                        size: AppButtonSize.lg,
                        block: true,
                        enabled: controller.hasPrev,
                        onPressed: controller.prev,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space3),
                    Expanded(
                      child: AppButton(
                        label: '다음 장  ▶',
                        size: AppButtonSize.lg,
                        block: true,
                        enabled: controller.hasNext,
                        onPressed: controller.next,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }
}

/// 종이 한 장.
class _Paper extends StatelessWidget {
  const _Paper({required this.page});

  final BookPage page;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space6,
        vertical: AppDimens.space8,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandFg,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          Text(
            '제 ${page.chapterOrder} 장',
            style: AppTypography.caption.copyWith(color: AppColors.warm),
          ),
          const SizedBox(height: AppDimens.space3),
          Text(
            page.chapterTitle,
            textAlign: TextAlign.center,
            style: AppTypography.bookTitle,
          ),
          const SizedBox(height: AppDimens.space4),
          Container(width: 44, height: 1, color: AppColors.warm),
          const SizedBox(height: AppDimens.space6),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final p in page.paragraphs) ...[
                    Text(
                      p,
                      textAlign: TextAlign.justify,
                      style: AppTypography.bookBody,
                    ),
                    const SizedBox(height: AppDimens.space5),
                  ],
                ],
              ),
            ),
          ),
          Text(
            '— ${page.pageNumber} —',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBook extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
      child: Text(
        '아직 완성된 장이 없어요.\n질문에 답하시면 여기에 실려요.',
        textAlign: TextAlign.center,
        style: AppTypography.bodyBase.copyWith(color: AppColors.textSecondary),
      ),
    ),
  );
}
