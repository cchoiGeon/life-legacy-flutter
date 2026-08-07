import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'qna_controller.dart';

/// 문의 작성 · 내 문의 목록.
class QnaView extends GetView<QnaController> {
  const QnaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(title: '문의하기'),
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
                      '문의 작성',
                      style: AppTypography.weight(
                        AppTypography.bodyBase,
                        AppTypography.medium,
                      ).copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppDimens.space2),
                    Text(
                      '카테고리 (선택)',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0;
                              i < controller.categories.length;
                              i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            _CatChip(
                              label: controller.categories[i].label,
                              selected: controller.selectedCategoryId.value ==
                                  controller.categories[i].id,
                              onTap: () {
                                final id = controller.categories[i].id;
                                controller.selectCategory(
                                  controller.selectedCategoryId.value == id
                                      ? null
                                      : id,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimens.space3),
                    AppField(
                      controller: controller.questionController,
                      hint: '문의 내용을 적어 주세요',
                      maxLines: 6,
                      minLines: 4,
                    ),
                    const SizedBox(height: AppDimens.space3),
                    GetBuilder<QnaController>(
                      id: 'composer',
                      builder: (c) => AppButton(
                        label: '문의 보내기',
                        size: AppButtonSize.lg,
                        block: true,
                        enabled: c.canSubmit,
                        loading: c.isSubmitting.value,
                        onPressed: c.submit,
                      ),
                    ),
                    const SizedBox(height: AppDimens.space6),
                    Text(
                      '내 문의',
                      style: AppTypography.weight(
                        AppTypography.bodyBase,
                        AppTypography.medium,
                      ).copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppDimens.space2),
                    if (controller.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '아직 남긴 문의가 없어요',
                          style: AppTypography.bodyBase.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      )
                    else
                      for (final item in controller.items)
                        _QnaCard(item: item),
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

class _CatChip extends StatelessWidget {
  const _CatChip({
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

class _QnaCard extends StatelessWidget {
  const _QnaCard({required this.item});

  final QnaItem item;

  @override
  Widget build(BuildContext context) {
    final answer = item.answer;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.statusLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _shortDate(item.createdAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.question,
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          if (answer != null && answer.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '답변',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    answer,
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
