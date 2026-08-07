import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'review_controller.dart';

/// 05 챕터 리뷰 — 종합 원고 읽기·편집·사진·문장 하이라이트 TTS.
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
                trailing: controller.canEdit
                    ? TextButton(
                        onPressed: controller.toggleEdit,
                        child: Text(
                          controller.isEditing.value ? '취소' : '수정',
                          style: AppTypography.label.copyWith(
                            color: AppColors.brand,
                          ),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: controller.isEditing.value
                    ? _EditBody(controller: controller)
                    : _ReadBody(controller: controller, review: review),
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
                    if (!controller.isEditing.value)
                      Obx(
                        () => AppButton(
                          label: controller.isSpeaking.value ? '중지' : '읽어주기',
                          size: AppButtonSize.md,
                          block: true,
                          variant: AppButtonVariant.outline,
                          onPressed: controller.playTts,
                        ),
                      ),
                    if (!controller.isEditing.value) const SizedBox(height: 10),
                    Obx(
                      () => AppButton(
                        label: controller.isEditing.value ? '수정 저장' : '저장하기',
                        size: AppButtonSize.lg,
                        block: true,
                        loading: controller.isSaving.value,
                        onPressed: () => controller.save(
                          markReviewed: !controller.isEditing.value,
                        ),
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

class _EditBody extends StatelessWidget {
  const _EditBody({required this.controller});

  final ReviewController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        12,
        AppDimens.gutter,
        8,
      ),
      child: TextField(
        controller: controller.bodyEditor,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        style: AppTypography.bookBody.copyWith(
          height: 30 / 16,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintText: '자서전 원고를 고치세요',
          hintStyle: AppTypography.bookBody.copyWith(
            color: AppColors.textTertiary,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _ReadBody extends StatelessWidget {
  const _ReadBody({required this.controller, required this.review});

  final ReviewController controller;
  final ChapterReview review;

  @override
  Widget build(BuildContext context) {
    final sentences = controller.sentences;
    final byParagraph = <int, List<ReviewSentence>>{};
    for (final s in sentences) {
      byParagraph.putIfAbsent(s.paragraphIndex, () => []).add(s);
    }

    return ListView(
      controller: controller.scrollController,
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
        const SizedBox(height: 12),
        Obx(() {
          final generating = controller.isGeneratingAiPhoto.value;
          if (controller.canGenerateAiPhoto) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppButton(
                label: generating ? 'AI 사진 만드는 중…' : 'AI 사진 만들기',
                size: AppButtonSize.md,
                block: true,
                variant: AppButtonVariant.outline,
                loading: generating,
                onPressed: generating
                    ? null
                    : () => controller.generateAiPhoto(),
              ),
            );
          }
          if (controller.canRegenAiPhoto) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppButton(
                label: generating
                    ? '다시 만드는 중…'
                    : 'AI 사진 다시 만들기 · 남은 ${controller.aiPhotoRegenRemaining}회',
                size: AppButtonSize.md,
                block: true,
                variant: AppButtonVariant.outline,
                loading: generating,
                onPressed: generating
                    ? null
                    : () => controller.generateAiPhoto(regenerate: true),
              ),
            );
          }
          if (controller.hasAiPhoto &&
              !controller.canRegenAiPhoto &&
              controller.aiPhotoRegenRemaining <= 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'AI 사진 재생성을 모두 썼어요',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            );
          }
          if (controller.hasAiPhoto && !controller.canRegenAiPhoto) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'AI 사진 재생성은 T3·T4에서 가능해요',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 8),
        for (var pi = 0; pi < review.paragraphs.length; pi++) ...[
          if (pi > 0) const SizedBox(height: 22),
          Builder(
            builder: (context) {
              final paraKey = controller.sentenceKeys.putIfAbsent(
                -1 - pi, // 문단 앵커 (음수 키)
                GlobalKey.new,
              );
              return Obx(() {
                final hi = controller.highlightSentence.value;
                final parts = byParagraph[pi] ?? const <ReviewSentence>[];
                if (parts.isEmpty) {
                  return Text(
                    key: paraKey,
                    review.paragraphs[pi],
                    style: AppTypography.bookBody.copyWith(
                      height: 30 / 16,
                      letterSpacing: -0.2,
                    ),
                  );
                }
                return Text.rich(
                  key: paraKey,
                  TextSpan(
                    children: [
                      for (final s in parts)
                        TextSpan(
                          text: '${s.text} ',
                          style: AppTypography.bookBody.copyWith(
                            height: 30 / 16,
                            letterSpacing: -0.2,
                            backgroundColor: hi == s.globalIndex
                                ? AppColors.warm.withValues(alpha: 0.35)
                                : null,
                          ),
                        ),
                    ],
                  ),
                );
              });
            },
          ),
          ...controller.mediaAfter(pi).map(
                (m) => _MediaBlock(
                  media: m,
                  bytes: controller.mediaBytes[m.id],
                  canRemove: controller.canAddPhoto,
                  onRemove: () => controller.removePhoto(m.id),
                ),
              ),
          if (controller.canAddPhoto)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Obx(
                () => TextButton.icon(
                  onPressed: controller.isUploadingPhoto.value
                      ? null
                      : () => controller.navigateToPhotoSuggest(pi),
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: Text(
                    '이 문단 뒤에 사진 넣기',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _MediaBlock extends StatelessWidget {
  const _MediaBlock({
    required this.media,
    required this.bytes,
    required this.canRemove,
    required this.onRemove,
  });

  final ReviewMedia media;
  final Uint8List? bytes;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: bytes == null
                ? Container(
                    height: 180,
                    color: AppColors.cream,
                    alignment: Alignment.center,
                    child: const AppSpinner(),
                  )
                : Image.memory(
                    bytes!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          if (canRemove)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: onRemove,
                  tooltip: '사진 삭제',
                ),
              ),
            ),
        ],
      ),
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
            if (controller.canAddPhoto) ...[
              AppButton(
                label: '사진 첨부하기',
                size: AppButtonSize.lg,
                block: true,
                onPressed: () {
                  controller.navigateToPhotoSuggest(0);
                },
              ),
              const SizedBox(height: 12),
            ],
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
