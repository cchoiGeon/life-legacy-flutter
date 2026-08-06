import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/shared/app_shell.dart';
import 'package:life_legacy/service/services.dart';

import 'book_detail_controller.dart';

/// 6-1 책 상세 허브.
class BookDetailView extends GetView<BookDetailController> {
  const BookDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppSpinner());
        }
        final title = controller.book.value?.title ?? '나의 자서전';
        final q = controller.currentQuestion;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTopBar(title: title, onBack: Get.back),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  8,
                  AppDimens.gutter,
                  AppDimens.space6,
                ),
                children: [
                  Text(
                    controller.summaryCaption,
                    style: AppTypography.bodyChat.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (q != null) ...[
                    const SizedBox(height: 16),
                    _CurrentQuestionCard(
                      question: q,
                      onAnswer: controller.answerCurrentQuestion,
                      onDismiss: controller.dismissCurrentQuestion,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    '목차',
                    style: AppTypography.titleSection.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...controller.chapters.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppChapterCard(
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '후처리',
                    style: AppTypography.titleSection.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PostActions(
                    onEbook: controller.openPreview,
                    onAudiobook: controller.openAudiobook,
                    onStorybook: controller.openStorybook,
                    ebookAllowed:
                        controller.book.value?.entitlements.ebook.allowed ??
                        true,
                    audiobookAllowed:
                        controller.book.value?.entitlements.audiobook.allowed ??
                        false,
                    storybookAllowed:
                        controller.book.value?.entitlements.storybook.allowed ??
                        false,
                  ),
                ],
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
    );
  }
}

class _CurrentQuestionCard extends StatelessWidget {
  const _CurrentQuestionCard({
    required this.question,
    required this.onAnswer,
    required this.onDismiss,
  });

  final BookCurrentQuestion question;
  final VoidCallback onAnswer;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderSoft,
          width: AppDimens.borderWidth,
        ),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${question.chapterTitle} · 질문 ${question.order}',
                  style: AppTypography.weight(
                    AppTypography.caption,
                    AppTypography.bold,
                  ).copyWith(color: AppColors.brand),
                ),
              ),
              InkWell(
                onTap: onDismiss,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close,
                    size: 22,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(() {
            final size = Get.find<PrefsService>().questionCardSize;
            return Text(
              question.text,
              style: AppTypography.titleSerifSm.copyWith(
                fontSize: size,
                height: 1.35,
              ),
            );
          }),
          const SizedBox(height: 16),
          AppButton(
            label: '답변하러 가기',
            size: AppButtonSize.card,
            block: true,
            onPressed: onAnswer,
          ),
        ],
      ),
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.onEbook,
    required this.onAudiobook,
    required this.onStorybook,
    required this.ebookAllowed,
    required this.audiobookAllowed,
    required this.storybookAllowed,
  });

  final VoidCallback onEbook;
  final VoidCallback onAudiobook;
  final VoidCallback onStorybook;
  final bool ebookAllowed;
  final bool audiobookAllowed;
  final bool storybookAllowed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          label: '전자책 미리보기',
          locked: !ebookAllowed,
          onTap: onEbook,
        ),
        const SizedBox(height: 8),
        _ActionTile(
          label: '음성책',
          locked: !audiobookAllowed,
          onTap: onAudiobook,
        ),
        const SizedBox(height: 8),
        _ActionTile(
          label: 'AI 영상 그림책',
          locked: !storybookAllowed,
          onTap: onStorybook,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.locked,
    required this.onTap,
  });

  final String label;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: AppTypography.titleSection),
              ),
              Text(
                locked ? '잠김' : '열기',
                style: AppTypography.caption.copyWith(
                  color: locked ? AppColors.textTertiary : AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
