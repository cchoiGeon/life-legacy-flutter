import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'faq_controller.dart';

/// FAQ · 게시 QnA.
class FaqView extends GetView<FaqController> {
  const FaqView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(title: 'FAQ'),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: AppSpinner());
              }

              return RefreshIndicator(
                onRefresh: controller.load,
                color: AppColors.brand,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.gutter,
                    AppDimens.space3,
                    AppDimens.gutter,
                    AppDimens.space8,
                  ),
                  children: [
                    Text(
                      '자주 묻는 질문',
                      style: AppTypography.weight(
                        AppTypography.bodyBase,
                        AppTypography.medium,
                      ).copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppDimens.space3),
                    _CategoryChips(controller: controller),
                    const SizedBox(height: AppDimens.space4),
                    for (final section in controller.visibleSections) ...[
                      Text(
                        section.label,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space2),
                      for (var i = 0; i < section.items.length; i++)
                        _ExpandTile(
                          title: section.items[i].question,
                          body: section.items[i].answer,
                          expanded: controller.expandedKeys.contains(
                            '${section.id}-$i',
                          ),
                          onTap: () => controller.toggleExpanded(
                            '${section.id}-$i',
                          ),
                        ),
                      const SizedBox(height: AppDimens.space4),
                    ],
                    Text(
                      '게시된 문의 답변',
                      style: AppTypography.weight(
                        AppTypography.bodyBase,
                        AppTypography.medium,
                      ).copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppDimens.space2),
                    if (controller.published.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          '아직 공개된 문의 답변이 없어요',
                          style: AppTypography.bodyBase.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      )
                    else
                      for (final item in controller.published)
                        _ExpandTile(
                          title: item.question,
                          body: item.answer,
                          expanded: controller.expandedKeys.contains(
                            'pub-${item.id}',
                          ),
                          onTap: () =>
                              controller.toggleExpanded('pub-${item.id}'),
                        ),
                    const SizedBox(height: AppDimens.space6),
                    AppButton(
                      label: '원하는 답이 없으면 문의하기',
                      size: AppButtonSize.lg,
                      block: true,
                      onPressed: controller.openQna,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.controller});

  final FaqController controller;

  @override
  Widget build(BuildContext context) {
    final categories = controller.catalog.value?.categories ?? const [];
    final selected = controller.selectedCategoryId.value;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: '전체',
            selected: selected == null,
            onTap: () => controller.selectCategory(null),
          ),
          for (final c in categories) ...[
            const SizedBox(width: 8),
            _Chip(
              label: c.label,
              selected: selected == c.id,
              onTap: () => controller.selectCategory(c.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand : AppColors.cream,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: selected ? AppColors.brandFg : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ExpandTile extends StatelessWidget {
  const _ExpandTile({
    required this.title,
    required this.body,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final String body;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.weight(
                          AppTypography.bodyBase,
                          AppTypography.medium,
                        ).copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 10),
                  Text(
                    body,
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
