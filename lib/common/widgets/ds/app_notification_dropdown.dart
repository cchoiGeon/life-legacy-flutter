import 'package:flutter/material.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/data/data_manager.dart';

/// 헤더 벨 옆 안 읽은 개수 배지.
///
/// Figma `15 헤더 알림 드롭다운 · 공통`(169:446)의 NotificationBell.
/// ⚠️ 참고 프레임은 IAM 팔레트(코랄 #ff6b52)로 그려져 있다. 이 앱은
///    파란색·코랄을 쓰지 않으므로 배지는 `destructive`로 옮겼다.
class AppNotificationBell extends StatelessWidget {
  const AppNotificationBell({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: unreadCount > 0 ? '알림 $unreadCount건' : '알림',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: AppDimens.touchMin,
          height: AppDimens.touchMin,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              // 배지가 아이콘 밖으로 삐져나오므로 자르지 않는다.
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned(
                    left: 2,
                    top: 3,
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 24,
                      color: AppColors.stone500,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      left: 14,
                      top: -3,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.destructive,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusPill,
                          ),
                          border: Border.all(
                            color: AppColors.background,
                            width: AppDimens.borderWidthStrong,
                          ),
                        ),
                        child: Text(
                          '$unreadCount',
                          style:
                              AppTypography.weight(
                                AppTypography.label,
                                AppTypography.bold,
                              ).copyWith(
                                fontSize: 8,
                                height: 12 / 8,
                                color: AppColors.brandFg,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 헤더 아래로 펼쳐지는 알림 목록 — Figma `Dropdown`(169:451).
///
/// 화면 전체를 덮는 스크림 위에 얹힌다. 바깥을 누르면 닫힌다.
class AppNotificationDropdown extends StatelessWidget {
  const AppNotificationDropdown({
    super.key,
    required this.items,
    required this.onDismiss,
    required this.onMarkAllRead,
    required this.onSeeAll,
    this.isLoading = false,
  });

  final List<AppNotification> items;
  final VoidCallback onDismiss;
  final VoidCallback onMarkAllRead;
  final VoidCallback onSeeAll;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 스크림 — 바깥을 누르면 닫는다.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: const ColoredBox(color: Color(0x4D141A1F)),
          ),
        ),
        Positioned(
          left: 44,
          right: 16,
          top: 8,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: AppColors.stone100),
                boxShadow: AppShadows.md,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(onMarkAllRead: onMarkAllRead),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppDimens.space8),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: AppColors.brand,
                        ),
                      ),
                    )
                  else if (items.isEmpty)
                    const _Empty()
                  else
                    for (final n in items) _Item(notification: n),
                  _Footer(onSeeAll: onSeeAll),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onMarkAllRead});

  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Text(
            '알림',
            style: AppTypography.weight(
              AppTypography.titleSection,
              AppTypography.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onMarkAllRead,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '모두 읽음',
                style: AppTypography.weight(
                  AppTypography.caption,
                  AppTypography.medium,
                ).copyWith(color: AppColors.brand),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Container(
      // 안 읽은 항목만 크림 배경으로 구분한다.
      color: unread ? AppColors.cream : AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.bubbleSys,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: AppDimens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: AppTypography.weight(
                    AppTypography.bodySm,
                    AppTypography.medium,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notification.timeLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (unread) ...[
            const SizedBox(width: AppDimens.space2),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.destructive,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppDimens.space8),
    child: Text(
      '새 알림이 없어요',
      style: AppTypography.bodySm.copyWith(color: AppColors.textTertiary),
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSeeAll,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 12, bottom: 14),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.stone100)),
        ),
        child: Text(
          '전체 보기',
          style: AppTypography.weight(
            AppTypography.bodySm,
            AppTypography.medium,
          ).copyWith(color: AppColors.brand),
        ),
      ),
    );
  }
}
