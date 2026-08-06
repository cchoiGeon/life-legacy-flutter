import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 메뉴 열기/닫기 — 헤더 [AppMenuButton]이 Scaffold drawer 대신 이걸 쓴다.
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.openMenu,
    required this.closeMenu,
    required super.child,
  });

  final VoidCallback openMenu;
  final VoidCallback closeMenu;

  static AppShellScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppShellScope>();
    assert(scope != null, 'AppShellScope를 찾을 수 없습니다');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppShellScope old) =>
      openMenu != old.openMenu || closeMenu != old.closeMenu;
}

/// 메인 화면 공통 껍데기 — 오른쪽 슬라이딩 메뉴 + (선택) 하단 탭바.
///
/// 햄버거(메뉴) 버튼은 각 화면 헤더에서 [AppMenuButton]으로 연다.
/// 메뉴는 앱 너비의 약 절반만 덮고, 슬라이드·페이드를 천천히 한다.
/// [tab]을 주면 하단에 홈·작성·자서전·설정 탭바를 붙인다.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.body,
    this.backgroundColor,
    this.tab,
  });

  final Widget body;
  final Color? backgroundColor;

  /// null이면 하단 탭바를 숨긴다(상세·작성 중 화면 등).
  final AppTab? tab;

  /// 열기/닫기 공통 길이 — 슬라이드와 페이드에 같이 쓴다.
  static const menuAnimDuration = Duration(milliseconds: 520);

  static const tabRoutes = {
    AppTab.home: AppRoutes.home,
    AppTab.write: AppRoutes.write,
    AppTab.book: AppRoutes.book,
    AppTab.settings: AppRoutes.settings,
  };

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _menu = AnimationController(
    vsync: this,
    duration: AppShell.menuAnimDuration,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(1, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _menu, curve: Curves.easeOutCubic));

  late final Animation<double> _fade = CurvedAnimation(
    parent: _menu,
    curve: Curves.easeOut,
  );

  void _openMenu() {
    if (_menu.isDismissed || _menu.status == AnimationStatus.reverse) {
      _menu.forward();
    }
  }

  void _closeMenu() {
    if (_menu.isCompleted || _menu.status == AnimationStatus.forward) {
      _menu.reverse();
    }
  }

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuWidth = MediaQuery.sizeOf(context).width * 0.5;
    final tab = widget.tab;

    return AppShellScope(
      openMenu: _openMenu,
      closeMenu: _closeMenu,
      child: Scaffold(
        backgroundColor: widget.backgroundColor ?? AppColors.background,
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(child: widget.body),
                  if (tab != null)
                    AppTabBar(
                      current: tab,
                      onSelect: (next) {
                        if (next == tab) return;
                        _closeMenu();
                        final bookId = Storage.currentBookId;
                        Get.offNamed(
                          AppShell.tabRoutes[next]!,
                          arguments:
                              bookId == null ? null : {'bookId': bookId},
                        );
                      },
                    ),
                ],
              ),
            ),
            // 딤 — 페이드만. 닫힌 뒤에는 터치를 통과시킨다.
            AnimatedBuilder(
              animation: _menu,
              builder: (context, _) {
                final open = _menu.value > 0;
                return IgnorePointer(
                  ignoring: !open,
                  child: FadeTransition(
                    opacity: _fade,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _closeMenu,
                      child: const ColoredBox(color: AppColors.overlayScrim),
                    ),
                  ),
                );
              },
            ),
            // 패널 — 오른쪽에서 절반만 슬라이드 + 페이드
            AnimatedBuilder(
              animation: _menu,
              builder: (context, child) {
                return IgnorePointer(
                  ignoring: _menu.value == 0,
                  child: child,
                );
              },
              child: Align(
                alignment: Alignment.centerRight,
                child: SlideTransition(
                  position: _slide,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Material(
                      elevation: 8,
                      color: AppColors.background,
                      child: SizedBox(
                        width: menuWidth,
                        height: double.infinity,
                        child: AppSideMenu(onClose: _closeMenu),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 헤더용 햄버거 — 탭하면 [AppShell] 오른쪽 메뉴를 연다.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '메뉴 열기',
      child: IconButton(
        onPressed: () => AppShellScope.of(context).openMenu(),
        icon: const Icon(Icons.menu_rounded, size: 28),
        color: AppColors.textPrimary,
        tooltip: '메뉴',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: AppDimens.touchMin,
          minHeight: AppDimens.touchMin,
        ),
      ),
    );
  }
}

/// 오른쪽에서 슬라이드되는 메뉴 내용.
class AppSideMenu extends StatelessWidget {
  const AppSideMenu({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();

    return SafeArea(
      child: Obx(() {
        final user = auth.user.value;
        final avatar = auth.avatarBytes.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutter,
                12,
                8,
                8,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: AppWordmark(fontSize: 18, letterSpacing: 0.2),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                onClose();
                Get.toNamed(AppRoutes.settingsProfile);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.gutter,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    AppAvatar(
                      initial: user?.initial ?? '?',
                      size: 48,
                      imageBytes: avatar,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (user?.name.isNotEmpty ?? false)
                                ? user!.name
                                : '내 프로필',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.weight(
                              AppTypography.titleSection,
                              AppTypography.bold,
                            ).copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.phone.isNotEmpty == true
                                ? Address.formatPhone(user!.phone)
                                : (user?.loginId ?? '프로필 보기'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const AppChevron(),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _MenuTile(
                    icon: Icons.home_outlined,
                    label: '홈',
                    onTap: () => _go(context, AppRoutes.home),
                  ),
                  _MenuTile(
                    icon: Icons.edit_outlined,
                    label: '작성',
                    onTap: () => _go(context, AppRoutes.write),
                  ),
                  _MenuTile(
                    icon: Icons.menu_book_outlined,
                    label: '자서전',
                    onTap: () => _go(context, AppRoutes.book),
                  ),
                  _MenuTile(
                    icon: Icons.settings_outlined,
                    label: '설정',
                    onTap: () => _go(context, AppRoutes.settings),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      '안내',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.info_outline,
                    label: '소개',
                    onTap: () => _go(context, AppRoutes.about, stack: true),
                  ),
                  _MenuTile(
                    icon: Icons.help_outline,
                    label: '사용설명서',
                    onTap: () => _go(context, AppRoutes.guide, stack: true),
                  ),
                  const Divider(height: 24),
                  _MenuTile(
                    icon: Icons.logout_rounded,
                    label: '로그아웃',
                    danger: true,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await AppDialog.confirm(
      context,
      title: '로그아웃할까요?',
      message: '작성하신 내용은 그대로 남아 있어요.',
      confirmLabel: '로그아웃',
      cancelLabel: '취소',
      danger: true,
    );
    if (!ok) return;
    onClose();
    await Get.find<AuthService>().logout();
    Get.offAllNamed(AppRoutes.splash);
  }

  void _go(BuildContext context, String route, {bool stack = false}) {
    onClose();
    final bookId = Storage.currentBookId;
    final args = bookId == null ? null : {'bookId': bookId};
    if (stack) {
      Get.toNamed(route);
    } else {
      Get.offNamed(route, arguments: args);
    }
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.destructive : AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: AppTypography.weight(
          AppTypography.bodyBase,
          AppTypography.medium,
        ).copyWith(fontSize: 16, color: color),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 12,
      visualDensity: VisualDensity.compact,
    );
  }
}
