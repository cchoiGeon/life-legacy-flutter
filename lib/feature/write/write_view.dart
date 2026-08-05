import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'stages/ai_loading_stage.dart';
import 'stages/ask_stage.dart';
import 'stages/confirm_stage.dart';
import 'stages/followup_failed_stage.dart';
import 'stages/keyboard_stage.dart';
import 'stages/recording_stage.dart';
import 'write_controller.dart';

/// D1~D5 작성 — Figma 341:646 · 350:875 · 351:874 · 351:964 · 354:1035.
///
/// ⚠️ **탭바가 없다.** 작성은 탭 중 하나지만 시안의 다섯 프레임 어디에도
///    탭바가 그려져 있지 않다. 말하거나 적는 동안 다른 탭이 눈에 들어오면
///    하던 이야기를 놓치기 때문이다. 나가는 길은 상단 `←` 하나다.
class WriteView extends GetView<WriteController> {
  const WriteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: AppSpinner()),
        );
      }

      if (controller.isChapterComplete.value) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: _ChapterComplete(),
        );
      }

      if (controller.isAllDone.value) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: _AllDone(),
        );
      }

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.requestLeave();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset:
              controller.stage.value == WriteStage.keyboard,
          body: Stack(
            children: [
              Positioned.fill(
                child: switch (controller.stage.value) {
                  WriteStage.ask => const AskStage(),
                  WriteStage.recording => const RecordingStage(),
                  WriteStage.keyboard => const KeyboardStage(),
                  // 정상 흐름에서는 확인 화면을 건너뛴다. 저장 실패(D5) 시에만 진입.
                  WriteStage.confirm => const ConfirmStage(),
                  WriteStage.generatingFollowup ||
                  WriteStage.saving => const AiLoadingStage(),
                  WriteStage.followupFailed => const FollowupFailedStage(),
                },
              ),
              if (controller.showTutorial.value) const _TutorialOverlay(),
            ],
          ),
        ),
      );
    });
  }
}

class _ChapterComplete extends GetView<WriteController> {
  const _ChapterComplete();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final completion = controller.chapterCompletion.value;
      final chapter = controller.completedChapter.value;
      final order = completion?.chapterOrder ?? chapter?.order;
      final title = order == null ? '이 장을 마쳤어요' : '제$order장을 마쳤어요';
      final subtitle = completion == null
          ? '원하신다면 리뷰로 가도 되고, 책 목록으로 돌아갈 수도 있어요'
          : '${completion.chapterTitle} · 답 ${completion.answeredCount}'
              '${completion.skippedCount > 0 ? ' · 건너뜀 ${completion.skippedCount}' : ''}'
              ' / ${completion.questionCount}';
      final showReview = completion?.canReview ?? true;
      final showNext = completion?.hasNextChapter ?? controller.hasPendingNext;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.gutter,
            40,
            AppDimens.gutter,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppScreenHeading(title: title, subtitle: subtitle),
              const Spacer(),
              if (showReview) ...[
                AppButton(
                  label: completion?.needsReview == false
                      ? '리뷰 다시 보기'
                      : '리뷰하러 가기',
                  size: AppButtonSize.lg,
                  block: true,
                  onPressed: controller.goReview,
                ),
                const SizedBox(height: 12),
              ],
              if (completion?.canHub ?? true)
                AppButton(
                  label: showNext ? '홈으로 이동' : '책 보러 가기',
                  size: AppButtonSize.lg,
                  block: true,
                  variant: AppButtonVariant.outline,
                  onPressed: controller.goBookHub,
                ),
              if (showNext) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: controller.proceedAfterChapterComplete,
                  child: Text(
                    completion?.nextChapter == null
                        ? '다음 장 이어서 쓰기'
                        : '다음 장 · ${completion!.nextChapter!.title}',
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}

/// 모든 장을 끝냈을 때.
class _AllDone extends GetView<WriteController> {
  const _AllDone();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          AppTopBar(onBack: controller.goBookHub),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.gutter,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 64,
                      color: AppColors.accentSoft,
                    ),
                    const SizedBox(height: AppDimens.space5),
                    const Text(
                      '모든 질문에 답하셨어요',
                      style: AppTypography.titleSerifSm,
                    ),
                    const SizedBox(height: AppDimens.space3),
                    Text(
                      '이제 완성된 책을 확인해 보세요',
                      style: AppTypography.subtitle,
                    ),
                    const SizedBox(height: AppDimens.space8),
                    AppButton(
                      label: '책 보러 가기',
                      size: AppButtonSize.lg,
                      block: true,
                      onPressed: controller.goBookHub,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialOverlay extends GetView<WriteController> {
  const _TutorialOverlay();

  static const _cardWidth = 300.0;
  static const _holePad = 10.0;
  static const _gap = 14.0;

  @override
  Widget build(BuildContext context) {
    // 첫 프레임 후 타깃 Rect 확보
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.scheduleTutorialTargetRefresh();
    });

    return Obx(() {
      final step = controller.tutorialStep.value;
      final (title, body) = WriteController.tutorialSteps[step];
      final isLast = step + 1 >= WriteController.tutorialSteps.length;
      final target = controller.tutorialTargetRect.value;
      final media = MediaQuery.of(context);
      final screen = media.size;

      final hole = target == null
          ? null
          : RRect.fromRectAndRadius(
              target.inflate(_holePad).intersect(
                    Offset.zero & screen,
                  ),
              const Radius.circular(14),
            );

      final cardTop = _cardTop(
        hole: hole,
        screenHeight: screen.height,
        safeBottom: media.padding.bottom,
        safeTop: media.padding.top,
      );
      final cardLeft = _cardLeft(
        hole: hole,
        screenWidth: screen.width,
      );

      return Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // 딤 + 하이라이트 구멍 + 점선. 바탕 탭 → 다음.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.nextTutorial,
                child: CustomPaint(
                  painter: _TutorialSpotlightPainter(
                    hole: hole,
                    dimColor: Colors.black.withValues(alpha: 0.58),
                    dashColor: AppColors.brand,
                  ),
                ),
              ),
            ),

            // 건너뛰기
            Positioned(
              top: media.padding.top + 4,
              right: 8,
              child: TextButton(
                onPressed: controller.finishTutorial,
                child: const Text(
                  '건너뛰기',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            // 타깃 근처 다이얼로그 (카드 탭은 다음으로 가지 않음)
            Positioned(
              left: cardLeft,
              top: cardTop,
              width: _cardWidth,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppShadows.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${step + 1} / ${WriteController.tutorialSteps.length}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: AppTypography.weight(
                          AppTypography.bodyBase,
                          AppTypography.bold,
                        ).copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(body, style: AppTypography.subtitle),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (step > 0)
                            TextButton(
                              onPressed: controller.prevTutorial,
                              child: const Text('이전'),
                            ),
                          const Spacer(),
                          AppButton(
                            label: isLast ? '시작하기' : '다음',
                            size: AppButtonSize.md,
                            onPressed: controller.nextTutorial,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '화면을 눌러도 다음으로 넘어가요',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  double _cardLeft({required RRect? hole, required double screenWidth}) {
    const gutter = AppDimens.gutter;
    if (hole == null) {
      return (screenWidth - _cardWidth) / 2;
    }
    final preferred = hole.center.dx - _cardWidth / 2;
    return preferred.clamp(gutter, screenWidth - gutter - _cardWidth);
  }

  double _cardTop({
    required RRect? hole,
    required double screenHeight,
    required double safeBottom,
    required double safeTop,
  }) {
    // 카드 대략 높이(제목·본문·버튼). 레이아웃 전이라 여유 있게.
    const estimatedH = 200.0;
    if (hole == null) {
      return screenHeight - safeBottom - estimatedH - 48;
    }

    final below = hole.bottom + _gap;
    final above = hole.top - _gap - estimatedH;
    final fitsBelow = below + estimatedH <= screenHeight - safeBottom - 12;
    if (fitsBelow) return below;
    if (above >= safeTop + 40) return above;
    // 둘 다 애매하면 화면 중앙
    return (screenHeight - estimatedH) / 2;
  }
}

/// 딤 오버레이에서 타깃만 뚫고, 둘레에 점선 테두리를 그린다.
class _TutorialSpotlightPainter extends CustomPainter {
  const _TutorialSpotlightPainter({
    required this.hole,
    required this.dimColor,
    required this.dashColor,
  });

  final RRect? hole;
  final Color dimColor;
  final Color dashColor;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    if (hole == null) {
      canvas.drawPath(overlay, Paint()..color = dimColor);
      return;
    }

    final holePath = Path()..addRRect(hole!);
    final cut = Path.combine(PathOperation.difference, overlay, holePath);
    canvas.drawPath(cut, Paint()..color = dimColor);

    final border = Paint()
      ..color = dashColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final metrics = holePath.computeMetrics();
    const dash = 7.0;
    const gap = 5.0;
    for (final metric in metrics) {
      var d = 0.0;
      while (d < metric.length) {
        final next = (d + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(d, next), border);
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TutorialSpotlightPainter old) =>
      old.hole != hole || old.dimColor != dimColor || old.dashColor != dashColor;
}
