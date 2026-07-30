import 'package:flutter/material.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/data/data_manager.dart';

/// 헤더의 알림 표시 — Figma 341:588.
///
/// ⚠️ 벨 아이콘이 아니라 **글자**다("알림 2"). 시안이 아이콘+배지를 걷어내고
///    글자로 바꿨다 — 시니어 사용자에게 벨 그림보다 "알림"이라는 말이 빠르고,
///    배지 숫자가 작아서 안 보인다는 문제도 같이 없어진다.
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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space2,
            vertical: AppDimens.space3,
          ),
          // 화면 글자는 "알림 2"지만 읽어 줄 때는 "알림 2건"이 자연스럽다.
          // 둘 다 내보내면 "알림 2건 알림 2"로 두 번 읽힌다.
          child: ExcludeSemantics(
            child: Text(
              unreadCount > 0 ? '알림 $unreadCount' : '알림',
              style: AppTypography.weight(
                AppTypography.bodySm,
                AppTypography.medium,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

/// 헤더 아래로 펼쳐지는 알림 목록 — Figma 349:886.
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
    this.visibleCount = 3,
  });

  final List<AppNotification> items;
  final VoidCallback onDismiss;
  final VoidCallback onMarkAllRead;
  final VoidCallback onSeeAll;
  final bool isLoading;

  /// 드롭다운에 보여줄 최대 개수. 나머지는 "알림 모두 보기"로 넘긴다.
  /// 시안(349:886)이 3건까지만 보여준다 — 헤더 아래로 길게 늘어지면
  /// 뒤 화면을 다 덮어 드롭다운이 아니라 전체 화면처럼 보인다.
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 스크림 — 바깥을 누르면 닫는다.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: const ColoredBox(color: AppColors.overlayScrim),
          ),
        ),
        // 시안 349:886 — 왼쪽 46 · 오른쪽 22. 헤더 바로 아래에 붙는다.
        Positioned(
          left: 46,
          right: 22,
          top: 6,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppShadows.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(onMarkAllRead: onMarkAllRead),
                  const SizedBox(height: 12),
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
                    for (final (i, n) in items.take(visibleCount).indexed) ...[
                      if (i > 0)
                        Container(height: 1, color: AppColors.borderSoft),
                      _DropdownNote(notification: n),
                    ],
                  const SizedBox(height: 10),
                  _SeeAll(onTap: onSeeAll),
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
    return Row(
      children: [
        Text(
          '알림',
          style: AppTypography.weight(
            AppTypography.bodyBase,
            AppTypography.bold,
          ).copyWith(letterSpacing: -0.1, height: 1.3),
        ),
        const Spacer(),
        Semantics(
          button: true,
          child: GestureDetector(
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
        ),
      ],
    );
  }
}

/// 드롭다운 안의 한 줄 (시안 349:892).
///
/// 알림 센터의 [AppNotificationTile]과 **모양이 다르다** — 드롭다운은 좁은
/// 카드 안이라 배경 없이 구분선으로만 나누고, 센터는 줄마다 카드가 된다.
/// 안 읽음 표시(굵기·점)의 규칙은 둘이 같다.
class _DropdownNote extends StatelessWidget {
  const _DropdownNote({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UnreadDot(visible: unread, size: 7, top: 5),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style:
                      AppTypography.weight(
                        AppTypography.bodySm,
                        unread ? AppTypography.bold : AppTypography.medium,
                      ).copyWith(
                        letterSpacing: -0.1,
                        height: 1.3,
                        color: unread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  notification.timeLabel,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 0,
                    height: 1.3,
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

/// 안 읽음 점. 읽은 항목도 **자리는 차지한다** — 안 그러면 읽는 순간
/// 글자가 왼쪽으로 밀려 목록이 들썩인다.
class _UnreadDot extends StatelessWidget {
  const _UnreadDot({
    required this.visible,
    required this.size,
    required this.top,
  });

  final bool visible;
  final double size;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top),
    child: SizedBox(
      width: size,
      height: size,
      child: visible
          ? const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
            )
          : null,
    ),
  );
}

/// 알림 센터의 한 줄 — Figma 349:926.
///
/// 안 읽은 항목은 크림으로 채우고, 읽은 항목은 흰 카드에 테두리만 남긴다.
class AppNotificationTile extends StatelessWidget {
  const AppNotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    final tile = Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: unread ? AppColors.cream : AppColors.background,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: unread
            ? null
            : Border.all(
                color: AppColors.borderSoft,
                width: AppDimens.borderWidth,
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UnreadDot(visible: unread, size: 8, top: 5),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style:
                      AppTypography.weight(
                        AppTypography.bodyBase,
                        unread ? AppTypography.bold : AppTypography.medium,
                      ).copyWith(
                        letterSpacing: -0.2,
                        height: 1.3,
                        color: unread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  notification.timeLabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: tile,
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

class _SeeAll extends StatelessWidget {
  const _SeeAll({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          child: Text(
            '알림 모두 보기',
            textAlign: TextAlign.center,
            style: AppTypography.weight(
              AppTypography.bodySm,
              AppTypography.bold,
            ).copyWith(color: AppColors.brand),
          ),
        ),
      ),
    );
  }
}
