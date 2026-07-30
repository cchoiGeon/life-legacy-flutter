import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'notifications_controller.dart';

/// C4 알림 센터 — Figma 349:921.
///
/// 홈 드롭다운의 "알림 모두 보기"에서 들어온다. 드롭다운이 3건까지만
/// 보여주므로 나머지는 여기서 본다.
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
            trailing: Obx(
              () => AppTextAction(
                label: '모두 읽음',
                enabled: controller.unreadCount > 0,
                onTap: controller.markAllRead,
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: AppSpinner());
              }
              if (controller.items.isEmpty) return const _Empty();
              return RefreshIndicator(
                onRefresh: controller.load,
                color: AppColors.brand,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.gutter,
                    AppDimens.space4,
                    AppDimens.gutter,
                    AppDimens.space4,
                  ),
                  itemCount: controller.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
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
          // 시안 350:874 — 목록 아래 고정 안내.
          //
          // ⚠️ 30일 보관은 **서버 정책을 적어 둔 문구**다. 앱이 지우지 않는다.
          //    보관 기간이 바뀌면 이 문장도 같이 고쳐야 한다.
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimens.gutter,
              0,
              AppDimens.gutter,
              AppInsets.bottom(context, AppDimens.space5),
            ),
            child: Text(
              '30일이 지난 알림은 자동으로 사라져요',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
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
