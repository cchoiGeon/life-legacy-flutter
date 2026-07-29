import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'notifications_controller.dart';

/// 13 알림 센터 — Figma 169:553.
///
/// 참고 프레임은 IAM 팔레트로 그려져 있어 구조만 가져오고 색은 웜 브라운
/// 토큰으로 옮겼다(홈 드롭다운과 같은 규칙).
class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: Column(
        children: [
          AppTopBar(
            title: '알림',
            centerTitle: false,
            trailing: Obx(
              () => AppNotificationBell(
                unreadCount: controller.unreadCount,
                // 이미 알림 화면이라 벨은 목록을 새로고침하는 역할만 한다.
                onTap: controller.load,
              ),
            ),
          ),
          _SubHeader(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: AppSpinner());
              }
              if (controller.items.isEmpty) return const _Empty();
              return RefreshIndicator(
                onRefresh: controller.load,
                color: AppColors.brand,
                child: ListView.builder(
                  itemCount: controller.items.length,
                  itemBuilder: (_, i) {
                    final n = controller.items[i];
                    return AppNotificationTile(
                      notification: n,
                      onTap: () => controller.openItem(n),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// "안읽은 알림 N개" + "모두 읽음"
class _SubHeader extends GetView<NotificationsController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfacePage,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Obx(
            () => Text(
              controller.unreadCount == 0
                  ? '모두 읽었어요'
                  : '안읽은 알림 ${controller.unreadCount}개',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const Spacer(),
          Obx(() {
            final enabled = controller.unreadCount > 0;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? controller.markAllRead : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '모두 읽음',
                  style:
                      AppTypography.weight(
                        AppTypography.bodySm,
                        AppTypography.medium,
                      ).copyWith(
                        color: enabled
                            ? AppColors.brand
                            : AppColors.textDisabled,
                      ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: AppDimens.space5),
          Text(
            '새 알림이 없어요',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
