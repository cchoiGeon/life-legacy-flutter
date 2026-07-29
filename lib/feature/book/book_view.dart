import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/shared/tab_scaffold.dart';

import 'book_controller.dart';

/// 19 나의 자서전 — Figma 153:260.
class BookView extends GetView<BookController> {
  const BookView({super.key});

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      tab: AppTab.book,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: AppSpinner());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  AppDimens.space4,
                  AppDimens.gutter,
                  AppDimens.space4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('나의 자서전', style: AppTypography.titlePage),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '전체 ${(controller.progress * 100).round()}%',
                        style: AppTypography.weight(
                          AppTypography.caption,
                          AppTypography.medium,
                        ).copyWith(color: AppColors.warm),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.gutter,
                    0,
                    AppDimens.gutter,
                    AppDimens.space6,
                  ),
                  itemCount: controller.chapters.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDimens.space3),
                  itemBuilder: (_, i) =>
                      _ChapterTile(chapter: controller.chapters[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  0,
                  AppDimens.gutter,
                  AppDimens.space4,
                ),
                child: Column(
                  children: [
                    AppButton(
                      label: '이어서 쓰기',
                      size: AppButtonSize.lg,
                      block: true,
                      onPressed: controller.continueWriting,
                    ),
                    const SizedBox(height: AppDimens.space3),
                    AppButton(
                      label: '책 미리보기',
                      variant: AppButtonVariant.neutral,
                      size: AppButtonSize.lg,
                      block: true,
                      onPressed: controller.openPreview,
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ChapterTile extends GetView<BookController> {
  const _ChapterTile({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final locked = chapter.status == ChapterStatus.locked;

    return AppCard(
      onTap: () => controller.openChapter(chapter),
      padding: const EdgeInsets.all(AppDimens.space4),
      child: Row(
        children: [
          AppChapterBadge(number: chapter.order, active: !locked),
          const SizedBox(width: AppDimens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${chapter.order}장 · ${chapter.title}',
                  style:
                      AppTypography.weight(
                        AppTypography.titleSection,
                        AppTypography.medium,
                      ).copyWith(
                        color: locked
                            ? AppColors.textTertiary
                            : AppColors.textStrong,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  chapter.subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.space2),
          _Trailing(chapter: chapter),
        ],
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({required this.chapter});

  final Chapter chapter;

  @override
  Widget build(BuildContext context) => switch (chapter.status) {
    ChapterStatus.done => const AppCheckBadge(),
    ChapterStatus.locked => const AppLockIcon(),
    ChapterStatus.writing => Text(
      '${chapter.answeredCount}/${chapter.questionCount}',
      style: AppTypography.weight(
        AppTypography.caption,
        AppTypography.medium,
      ).copyWith(color: AppColors.warm),
    ),
  };
}
