import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'audiobook_controller.dart';

class AudiobookView extends GetView<AudiobookController> {
  const AudiobookView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppSpinner());
        }
        final o = controller.overview.value;
        final title = o?.bookTitle ?? '오디오북';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTopBar(title: '오디오북', onBack: Get.back),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.gutter,
                      8,
                      AppDimens.gutter,
                      AppDimens.space6,
                    ),
                    children: [
                      Text(title, style: AppTypography.titleSection),
                      const SizedBox(height: 8),
                      if (o == null || !o.allowed)
                        _LockedPanel(onUpgrade: controller.onUpgradeTap)
                      else ...[
                        Text(
                          '플랜 ${o.planCode ?? ''} · 예상 ${((o.estimatedDurationMs) / 60000).round()}분',
                          style: AppTypography.bodyChat.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('목소리', style: AppTypography.caption),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final v in controller.voices.take(12))
                              ChoiceChip(
                                label: Text(v.name),
                                selected:
                                    controller.selectedVoiceCode.value ==
                                    v.voiceCode,
                                onSelected: (_) =>
                                    controller.selectVoice(v.voiceCode),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: controller.previewSelectedVoice,
                            child: Text(
                              '미리듣기',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('배경음', style: AppTypography.caption),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('끄기'),
                              selected: controller.selectedBgmId.value == null,
                              onSelected: (_) => controller.selectBgm(null),
                            ),
                            for (final b in controller.bgms)
                              ChoiceChip(
                                label: Text(b.title),
                                selected:
                                    controller.selectedBgmId.value == b.id,
                                onSelected: (_) => controller.selectBgm(b.id),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        for (final c in o.chapters)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChapterTile(
                              chapter: c,
                              onCreate: () =>
                                  controller.createForChapter(c),
                              onPlay: () => controller.playChapter(c),
                              onDownload: () =>
                                  controller.downloadChapter(c),
                              onCancel: () =>
                                  controller.cancelChapterJob(c),
                            ),
                          ),
                      ],
                    ],
                  ),
                  if (controller.isWorking.value)
                    ColoredBox(
                      color: const Color(0x66000000),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppSpinner(),
                            if (controller.activeJobId.value != null) ...[
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: controller.cancelActiveJob,
                                child: const Text(
                                  '생성 멈추기',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
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

class _LockedPanel extends StatelessWidget {
  const _LockedPanel({required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '잠김',
            style: AppTypography.caption.copyWith(color: AppColors.brand),
          ),
          const SizedBox(height: 10),
          const Text(
            '유료 플랜에서 이용할 수 있어요',
            style: AppTypography.titleSerifSm,
          ),
          const SizedBox(height: 8),
          Text(
            '리뷰를 마친 장을 네이버 보이스로 만들고 들을 수 있어요. T1 이상 플랜에서 열립니다.',
            style: AppTypography.bodyChat.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 18),
          AppButton(
            label: '플랜 안내 보기',
            size: AppButtonSize.card,
            block: true,
            onPressed: onUpgrade,
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.chapter,
    required this.onCreate,
    required this.onPlay,
    required this.onDownload,
    required this.onCancel,
  });

  final AudiobookChapterStatus chapter;
  final VoidCallback onCreate;
  final VoidCallback onPlay;
  final VoidCallback onDownload;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final canCreate = chapter.state == 'ready' ||
        chapter.state == 'failed' ||
        (chapter.state == 'completed' && chapter.remainingGenerations > 0);
    final canPlay = chapter.state == 'completed';
    final canCancel = chapter.state == 'processing';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '제${chapter.order}장 · ${chapter.title}',
            style: AppTypography.titleSection,
          ),
          const SizedBox(height: 4),
          Text(
            '${chapter.stateLabel} · 잔여 ${chapter.remainingGenerations}회'
            '${chapter.latestJob?.stale == true ? ' · 이전 원고' : ''}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          if (canCancel)
            AppButton(
              label: '생성 중 ${chapter.latestJob?.progress ?? 0}% · 멈추기',
              size: AppButtonSize.card,
              block: true,
              variant: AppButtonVariant.outline,
              onPressed: onCancel,
            )
          else
            Row(
              children: [
                if (canPlay)
                  Expanded(
                    child: AppButton(
                      label: '듣기',
                      size: AppButtonSize.card,
                      block: true,
                      onPressed: onPlay,
                    ),
                  ),
                if (canPlay) const SizedBox(width: 8),
                if (canPlay)
                  Expanded(
                    child: AppButton(
                      label: '받기',
                      size: AppButtonSize.card,
                      block: true,
                      variant: AppButtonVariant.soft,
                      onPressed: onDownload,
                    ),
                  ),
                if (canPlay && canCreate) const SizedBox(width: 8),
                if (canCreate)
                  Expanded(
                    child: AppButton(
                      label: chapter.state == 'completed' ? '다시' : '만들기',
                      size: AppButtonSize.card,
                      block: true,
                      onPressed: onCreate,
                    ),
                  ),
                if (!canPlay && !canCreate && chapter.state == 'not_ready')
                  Text(
                    '리뷰 필요',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
