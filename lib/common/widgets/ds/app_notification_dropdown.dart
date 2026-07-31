import 'package:flutter/material.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'app_icon.dart';

/// 헤더의 알림 표시 — Figma 341:582의 `377:911` · 175:362의 `175:367`.
///
/// ⚠️ 글자("알림 2")가 아니라 **벨 아이콘**이다. 시안이 다시 아이콘으로
///    되돌렸다 — 워드마크 옆에 글자가 하나 더 붙으면 "Life Legacy 알림 2"가
///    한 덩어리로 읽혀서 제목인지 버튼인지 구분이 안 됐다.
///
/// ⚠️ 안 읽은 알림이 0건이어도 벨은 그대로 둔다 — 알림이 없다고 아이콘을
///    지우면 알림 센터로 갈 길이 사라진다. 0건일 때는 배지만 빠진다.
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
        // 아이콘은 24지만 누르는 자리는 48이다(AppDimens.touchMin).
        // 좌우 12씩 남는 여백이 시안의 벨↔아바타 간격 12을 그대로 만든다 —
        // 그래서 헤더에서 둘 사이에 SizedBox를 따로 두지 않는다.
        child: SizedBox(
          width: AppDimens.touchMin,
          height: AppDimens.touchMin,
          child: Stack(
            children: [
              // 벨 그림은 장식이다. 빼지 않으면 SvgPicture가 isImage를 올려
              // 보내서 버튼이 "이미지"로도 읽힌다.
              const ExcludeSemantics(
                child: Center(
                  child: AppIcon(
                    AppIcons.bell,
                    size: 24,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              // ⚠️ 24 박스의 모서리(36,12)가 아니라 **글리프의** 모서리에 건다.
              //    bell.svg의 벡터는 24 박스 안에서 x 3..21 · y 2..22에만
              //    그려져서, 박스 모서리에 붙이면 눈에 띄게 떠 보인다.
              //    48 박스로 환산한 글리프 오른쪽 위 꼭짓점이 (33,14)다.
              if (unreadCount > 0)
                Positioned(
                  left: 23,
                  top: 5,
                  child: _UnreadBadge(count: unreadCount),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 벨에 걸치는 빨간 개수 배지.
///
/// ⚠️ 두 글자를 넘기지 않는다(10건부터 "9+"). 세 글자가 되면 배지가 48 탭
///    영역을 넘어가 아바타를 밀어낸다 — 헤더가 시안과 어긋난다.
///
/// ⚠️ 폭을 글자에 맡기지 **않는다.** 예전에 `minWidth`+좌우 패딩으로 두었더니
///    글꼴 메트릭에 따라 한 글자짜리가 정원(18)이 아니라 20이 됐고, "9+"는
///    48 밖으로 7px 삐져나갔다. 지금은 글자 수로 폭을 못박고, 글자는
///    [FittedBox]로 그 안에 맞춘다 — 어떤 글꼴에서도 기하가 같다.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  /// 한 글자 배지의 지름.
  static const _size = 18.0;

  /// "9+"용 폭. 왼쪽 23에서 시작해도 23+22=45라 48 안에 있다.
  static const _wideSize = 22.0;

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';

    // 개수는 벨의 Semantics.label("알림 3건")이 이미 읽어 준다.
    // 여기까지 내보내면 "알림 3건 3"으로 두 번 읽힌다.
    return ExcludeSemantics(
      child: Container(
        width: label.length > 1 ? _wideSize : _size,
        height: _size,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.destructive,
          borderRadius: BorderRadius.circular(_size / 2),
        ),
        child: FittedBox(
          child: Text(
            label,
            maxLines: 1,
            style: AppTypography.weight(
              AppTypography.label,
              AppTypography.bold,
            ).copyWith(color: AppColors.brandFg, height: 1, letterSpacing: 0),
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
