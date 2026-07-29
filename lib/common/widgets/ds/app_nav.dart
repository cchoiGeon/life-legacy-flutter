import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 하단 탭 — 시안의 4개 탭(홈 · 작성 · 자서전 · 설정).
///
/// ⚠️ 디자인 시스템 문서(130:2240)에는 탭이 3개지만, 실제 화면(11·13·19·22번)은
///    설정까지 4개다. 화면 쪽을 따랐다.
enum AppTab {
  home('홈', Icons.home_outlined),
  write('작성', Icons.edit_outlined),
  book('자서전', Icons.menu_book_outlined),
  settings('설정', Icons.settings_outlined);

  const AppTab(this.label, this.icon);

  final String label;

  /// 시안의 아이콘은 단순한 선 아이콘이라 Material 아웃라인 세트로 대체했다.
  /// 직접 그려 봤더니 24px에서 톱니·연필이 뭉개져서 오히려 알아보기 어려웠다.
  /// 전용 아이콘 에셋이 나오면 여기만 바꾸면 된다.
  final IconData icon;
}

class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.current, required this.onSelect});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.brandFg,
        border: Border(
          top: BorderSide(
            color: AppColors.stone100,
            width: AppDimens.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppDimens.tabbarHeight,
          child: Row(
            children: [
              for (final tab in AppTab.values)
                Expanded(
                  child: _TabItem(
                    tab: tab,
                    active: tab == current,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final AppTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brand : AppColors.stone400;
    return Semantics(
      button: true,
      selected: active,
      label: tab.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.icon, size: 24, color: color),
            const SizedBox(height: 5),
            Text(
              tab.label,
              style: AppTypography.weight(
                AppTypography.label,
                active ? AppTypography.medium : AppTypography.regular,
              ).copyWith(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
