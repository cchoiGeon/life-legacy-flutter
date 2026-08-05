import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/feature/shared/tab_scaffold.dart';

import 'book_controller.dart';

/// 06 책 허브 — 제작 중/완료 가로 카드 + 하단 요약.
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

          final writing = controller.writingBooks;
          final completed = controller.completedBooks;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  20,
                  AppDimens.gutter,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('내 책', style: AppTypography.titleScreen),
                    const SizedBox(height: 6),
                    Text(
                      controller.books.isEmpty
                          ? '아직 만든 자서전이 없어요'
                          : '제작 중 ${controller.writingCount}권 · 완료 ${controller.completedCount}권',
                      style: AppTypography.bodyChat.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    if (writing.isNotEmpty) ...[
                      const _SectionTitle('제작 중인 자서전'),
                      _HorizontalBookStrip(
                        items: writing,
                        onOpen: controller.openBook,
                        progressLabel: controller.progressLabel,
                        statusLabel: controller.statusLabel,
                      ),
                    ],
                    if (completed.isNotEmpty) ...[
                      const _SectionTitle('제작 완료된 자서전'),
                      _HorizontalBookStrip(
                        items: completed,
                        onOpen: controller.openBook,
                        progressLabel: controller.progressLabel,
                        statusLabel: controller.statusLabel,
                      ),
                    ],
                    if (controller.books.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppDimens.gutter,
                          48,
                          AppDimens.gutter,
                          24,
                        ),
                        child: Text(
                          '목차를 확정하면 여기에 내 책이 보여요.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyChat.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _FooterSummary(
                name: controller.userName,
                writingCount: controller.writingCount,
                completedCount: controller.completedCount,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        16,
        AppDimens.gutter,
        12,
      ),
      child: Text(
        label,
        style: AppTypography.titleSection.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _HorizontalBookStrip extends StatelessWidget {
  const _HorizontalBookStrip({
    required this.items,
    required this.onOpen,
    required this.progressLabel,
    required this.statusLabel,
  });

  final List<BookListItem> items;
  final void Function(BookListItem) onOpen;
  final String Function(BookListItem) progressLabel;
  final String Function(BookListItem) statusLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // 표지 88 + 여백·제목·저자·상태 2줄이 들어가도록 넉넉히
      height: 228,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final item = items[i];
          return _BookCard(
            item: item,
            progressLabel: progressLabel(item),
            statusLabel: statusLabel(item),
            onTap: () => onOpen(item),
          );
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.item,
    required this.progressLabel,
    required this.statusLabel,
    required this.onTap,
  });

  final BookListItem item;
  final String progressLabel;
  final String statusLabel;
  final VoidCallback onTap;

  String get _coverGlyph {
    final title = item.title.trim();
    if (title.isEmpty) return '자';
    return String.fromCharCode(title.runes.first);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 148,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 88,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _coverGlyph,
                  style: AppTypography.titleScreen.copyWith(
                    color: AppColors.brandFg,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.title.isEmpty ? '나의 이야기' : item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleSection,
              ),
              const SizedBox(height: 4),
              Text(
                item.authorName.isEmpty ? '저자' : item.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: AppColors.brand),
              ),
              Text(
                progressLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterSummary extends StatelessWidget {
  const _FooterSummary({
    required this.name,
    required this.writingCount,
    required this.completedCount,
  });

  final String name;
  final int writingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimens.gutter,
        8,
        AppDimens.gutter,
        AppInsets.bottom(context, 16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isEmpty ? '내 정보' : name,
              style: AppTypography.titleSection,
            ),
            const SizedBox(height: 4),
            Text(
              '제작 중 $writingCount권 · 완료 $completedCount권',
              style: AppTypography.bodyChat.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
