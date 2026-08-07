import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/shared/tab_scaffold.dart';
import 'package:life_legacy/service/services.dart';

import 'home_controller.dart';

/// C1 홈 대시보드 · C2 빈 상태 · C3 알림 드롭다운 — Figma 341:582 · 348:788 · 349:821.
///
/// ⚠️ 인사말("○○ 님, 오늘도 반가워요")이 없다. 시안이 걷어냈다 —
///    첫 화면의 가장 좋은 자리를 인사가 차지하면 정작 오늘 할 일(질문)이
///    아래로 밀린다. 이름은 카드 안 라벨("영희 님, 오늘의 질문")에 남아 있다.
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
            const _Header(),
            Expanded(
              // 드롭다운은 헤더 **아래** 영역만 덮는다 (시안 349:885 스크림).
              child: Stack(
                children: [
                  Obx(() {
                    if (controller.isLoading.value) return const _Skeleton();
                    final s = controller.summary.value;
                    if (s == null) return _Retry(onRetry: controller.load);
                    return _Body(summary: s);
                  }),
                  Obx(() {
                    if (!controller.isNotificationsOpen.value) {
                      return const SizedBox.shrink();
                    }
                    return AppNotificationDropdown(
                      items: controller.notifications,
                      isLoading: controller.isNotificationsLoading.value,
                      onDismiss: controller.closeNotifications,
                      onMarkAllRead: controller.markAllNotificationsRead,
                      onSeeAll: controller.openAllNotifications,
                      onItemTap: controller.openNotification,
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 워드마크 · 알림 벨 · 햄버거 메뉴.
class _Header extends GetView<HomeController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        7,
        AppDimens.gutter,
        0,
      ),
      child: Row(
        children: [
          const AppWordmark(fontSize: 19, letterSpacing: 0.2),
          const Spacer(),
          Obx(
            () => AppNotificationBell(
              unreadCount: controller.unreadCount,
              onTap: controller.toggleNotifications,
            ),
          ),
          const AppMenuButton(),
        ],
      ),
    );
  }
}

/// C1과 C2는 위쪽 카드만 다르다. 진행 카드와 목차는 두 상태가 공유한다.
class _Body extends GetView<HomeController> {
  const _Body({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.brand,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutter,
          22,
          AppDimens.gutter,
          AppDimens.space8,
        ),
        children: [
          const _FreeTrialBanner(),
          const SizedBox(height: 16),
          if (summary.isEmpty)
            const _StartCard()
          else
            _TodayCard(question: summary.todayQuestion!),
          const SizedBox(height: 20),
          _ProgressCard(summary: summary),
          const SizedBox(height: 20),
          const _ChapterList(),
        ],
      ),
    );
  }
}

/// 홈 상단 — 결제 없이 무료 체험 가능 홍보.
class _FreeTrialBanner extends StatelessWidget {
  const _FreeTrialBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F4A3A), Color(0xFF4A6B55)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '결제 없이 무료 체험',
            style: AppTypography.weight(
              AppTypography.titlePage,
              AppTypography.bold,
            ).copyWith(
              color: Colors.white,
              fontSize: 26,
              height: 1.25,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 장까지 결제 없이\n바로 써 보실 수 있어요.',
            style: AppTypography.bodyBase.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// C1 — 오늘의 질문 (흰 카드 · 그림자).
class _TodayCard extends GetView<HomeController> {
  const _TodayCard({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDimens.space2),
              Obx(
                () => Text(
                  '${controller.userName} 님, 오늘의 질문',
                  style: AppTypography.weight(
                    AppTypography.caption,
                    AppTypography.bold,
                  ).copyWith(color: AppColors.brand, letterSpacing: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 질문은 명조 — 카드 안에서 가장 먼저 읽혀야 하는 글이다.
          // 크기는 설정의 질문 글자 크기를 따른다.
          Obx(() {
            final size = Get.find<PrefsService>().questionCardSize;
            return Text(
              question,
              style: AppTypography.titleSerifSm.copyWith(
                fontSize: size,
                height: 1.45,
              ),
            );
          }),
          const SizedBox(height: 18),
          AppButton(
            label: '말로 답하기',
            size: AppButtonSize.card,
            block: true,
            onPressed: controller.continueWriting,
          ),
        ],
      ),
    );
  }
}

/// C2 — 아직 시작하지 않았을 때 (크림 카드).
class _StartCard extends GetView<HomeController> {
  const _StartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '첫 이야기를 시작해요',
            style: AppTypography.titleSerifSm.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 12),
          Obx(
            () => Text(
              controller.emptyCaption,
              style: AppTypography.subtitle.copyWith(height: 28 / 16),
            ),
          ),
          const SizedBox(height: 20),
          Obx(
            () => AppButton(
              label: controller.emptyCtaLabel,
              size: AppButtonSize.card,
              block: true,
              onPressed: controller.continueWriting,
            ),
          ),
        ],
      ),
    );
  }
}

/// "내 자서전 · 42%" 크림 카드 (시안 341:602).
class _ProgressCard extends GetView<HomeController> {
  const _ProgressCard({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controller.openBook,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '내 자서전',
                  style: AppTypography.weight(
                    AppTypography.bodyBase,
                    AppTypography.bold,
                  ).copyWith(fontSize: 17, height: 1.3, letterSpacing: -0.2),
                ),
                const Spacer(),
                // 퍼센트만 명조다 — 숫자를 크게 세워 카드의 초점으로 삼는다.
                Text(
                  '${(summary.progress * 100).round()}%',
                  style: AppTypography.titleSerifSm.copyWith(
                    color: AppColors.brand,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppProgressBar(
              value: summary.progress,
              height: 8,
              fill: AppColors.brand,
            ),
            const SizedBox(height: 8),
            // ⚠️ Obx로 감싸지 않는다. 데이터가 있을 때 읽는 `progressCaption`은
            //    파라미터로 받은 평범한 객체라 관찰할 Rx가 하나도 없다 —
            //    GetX가 "improper use of a GetX" 오류를 화면에 띄운다.
            //    `summary`와 `chapters`는 `load()`에서 함께 채워지고 바깥
            //    [HomeView]의 Obx가 이미 그걸 보고 다시 그린다.
            Text(
              summary.isEmpty
                  ? controller.emptyProgressCaption
                  : summary.progressCaption,
              style: AppTypography.bodyChat.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 홈에 바로 펼쳐지는 목차 (시안 341:613).
class _ChapterList extends GetView<HomeController> {
  const _ChapterList();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          for (final (i, c) in controller.chapters.indexed) ...[
            if (i > 0) const AppChapterRule(),
            AppChapterRow(
              number: c.order,
              title: c.title,
              state: switch (c.status) {
                ChapterStatus.done => AppChapterState.done,
                ChapterStatus.writing => AppChapterState.writing,
                ChapterStatus.locked => AppChapterState.locked,
              },
              trailing: c.statusLabel,
              onTap: () => controller.openChapter(c),
            ),
          ],
        ],
      ),
    );
  }
}

/// 첫 로딩에서 카드 자리를 잡아 주는 뼈대.
///
/// ⚠️ **스크롤 가능해야 한다.** 고정 높이 Column으로 두면 본문이 짧을 때
///    넘쳐서 노랑·검정 줄무늬가 뜬다. 실제로 그랬다 — 작성 화면(D3)에서
///    키보드를 연 채 `←`를 누르면 키보드가 내려가기 전에 홈이 그려지는데,
///    그때 본문 높이가 442라 489짜리 뼈대가 46px 넘쳤다.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppDimens.gutter, 22, AppDimens.gutter, 0),
      // 로딩 중에는 끌어당길 게 없다 — 넘침만 막고 스크롤은 잠근다.
      physics: NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSkeleton(width: double.infinity, height: 226, radius: 20),
          SizedBox(height: 20),
          AppSkeleton(width: double.infinity, height: 119, radius: 20),
          SizedBox(height: 20),
          AppSkeleton(width: double.infinity, height: 48, radius: 8),
          SizedBox(height: AppDimens.space2),
          AppSkeleton(width: double.infinity, height: 48, radius: 8),
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
