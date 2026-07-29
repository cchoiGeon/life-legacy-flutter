import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/shared/tab_scaffold.dart';

import 'home_controller.dart';

/// 11 홈 대시보드 · 12 빈 상태 — Figma 146:102 · 147:134.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      tab: AppTab.home,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) return const _Skeleton();
                final s = controller.summary.value;
                if (s == null) {
                  return _Retry(onRetry: controller.load);
                }
                return s.isEmpty ? const _Empty() : _Dashboard(summary: s);
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.space4,
        AppDimens.gutter,
        0,
      ),
      child: Row(
        children: [
          const AppWordmark(fontSize: 18),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.openNotifications,
            child: const Padding(
              padding: EdgeInsets.all(AppDimens.space2),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 24,
                color: AppColors.stone500,
              ),
            ),
          ),
          const SizedBox(width: AppDimens.space2),
          Obx(() => AppAvatar(initial: controller.initial)),
        ],
      ),
    );
  }
}

/// 11 — 오늘의 질문 카드 + 진행률 카드.
class _Dashboard extends GetView<HomeController> {
  const _Dashboard({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.brand,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          AppDimens.space5,
          AppDimens.gutter,
          AppDimens.space8,
        ),
        children: [
          Text(
            '${controller.userName} 님,\n오늘도 반가워요',
            style: AppTypography.titlePage,
          ),
          const SizedBox(height: AppDimens.space5),
          AppCard(
            warm: true,
            padding: const EdgeInsets.all(AppDimens.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.accentSoft,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space2),
                    Text(
                      '오늘의 질문',
                      style: AppTypography.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space3),
                Text(
                  summary.todayQuestion!,
                  style: AppTypography.weight(
                    AppTypography.headingXl,
                    AppTypography.bold,
                  ),
                ),
                const SizedBox(height: AppDimens.space5),
                AppButton(
                  label: '이어서 이야기하기',
                  block: true,
                  size: AppButtonSize.lg,
                  onPressed: controller.continueWriting,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space3),
          AppCard(
            onTap: controller.openBook,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '내 자서전 진행',
                      style: AppTypography.weight(
                        AppTypography.titleSection,
                        AppTypography.bold,
                      ).copyWith(color: AppColors.textStrong),
                    ),
                    const Spacer(),
                    Text(
                      '${(summary.progress * 100).round()}%',
                      style: AppTypography.weight(
                        AppTypography.titleSection,
                        AppTypography.bold,
                      ).copyWith(color: AppColors.brand),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimens.space3),
                AppProgressBar(value: summary.progress),
                const SizedBox(height: AppDimens.space3),
                Text(
                  summary.progressCaption,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 12 — 아직 시작한 이야기가 없을 때.
class _Empty extends GetView<HomeController> {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 116,
            height: 116,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 48,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: AppDimens.space6),
          Text(
            '아직 시작한 이야기가 없어요',
            style: AppTypography.weight(
              AppTypography.headingXl,
              AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppDimens.space3),
          Text(
            '첫 질문에 답하시면\n자서전이 시작돼요',
            textAlign: TextAlign.center,
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.space8),
          AppButton(
            label: '첫 이야기 시작하기',
            size: AppButtonSize.lg,
            onPressed: controller.continueWriting,
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.space5,
        AppDimens.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: 180, height: 28, radius: 8),
          SizedBox(height: AppDimens.space2),
          AppSkeleton(width: 140, height: 28, radius: 8),
          SizedBox(height: AppDimens.space6),
          AppSkeleton(width: double.infinity, height: 180, radius: 16),
          SizedBox(height: AppDimens.space3),
          AppSkeleton(width: double.infinity, height: 110, radius: 16),
        ],
      ),
    );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '불러오지 못했어요',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          AppButton(
            label: '다시 시도',
            variant: AppButtonVariant.neutral,
            onPressed: () => onRetry(),
          ),
        ],
      ),
    );
  }
}
