import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/shared/tab_scaffold.dart';

import 'book_controller.dart';

/// E1 나의 자서전 · 목차 — Figma 341:670.
///
/// 홈(C1)에도 같은 목차가 뜨지만 여기는 카드 한 장씩이라 장마다 **다음에
/// 뭘 물어볼지**까지 보여준다. 홈은 "얼마나 왔나", 여기는 "무엇이 남았나"다.
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  20,
                  AppDimens.gutter,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '나의 자서전',
                      style: AppTypography.titleScreen,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.summaryCaption,
                      style: AppTypography.bodyChat.copyWith(
                        color: AppColors.textTertiary,
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
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final c = controller.chapters[i];
                    return AppChapterCard(
                      number: c.order,
                      title: c.title,
                      subtitle: c.subtitle,
                      state: switch (c.status) {
                        ChapterStatus.done => AppChapterState.done,
                        ChapterStatus.writing => AppChapterState.writing,
                        ChapterStatus.locked => AppChapterState.locked,
                      },
                      trailing: c.statusLabel,
                      onTap: () => controller.openChapter(c),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  0,
                  AppDimens.gutter,
                  AppInsets.bottom(context, 16),
                ),
                child: AppButton(
                  label: controller.ctaLabel,
                  size: AppButtonSize.card,
                  block: true,
                  onPressed: controller.onCtaPressed,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
