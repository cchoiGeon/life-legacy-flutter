import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

import 'app_icon.dart';

/// 하단 탭 — 시안의 4개 탭(홈 · 작성 · 자서전 · 설정).
///
/// ⚠️ 디자인 시스템 문서(130:2240)에는 탭이 3개지만, 실제 화면(11·13·19·22번)은
///    설정까지 4개다. 화면 쪽을 따랐다.
enum AppTab {
  home('홈', AppIcons.tabHome),
  write('작성', AppIcons.tabWrite),
  book('자서전', AppIcons.tabBook),
  settings('설정', AppIcons.tabSettings);

  const AppTab(this.label, this.icon);

  final String label;

  /// Figma에서 내보낸 에셋(148:209의 tab 아이콘). 색은 활성/비활성에 따라
  /// [AppIcon]이 덧칠한다.
  final AppIcons icon;
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
    // 시안: 활성 brand · 비활성 stone-500(#78716c), 라벨 11px Medium, gap 4
    final color = active ? AppColors.brand : AppColors.stone500;
    return Semantics(
      button: true,
      selected: active,
      label: tab.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(tab.icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                tab.label,
                style: AppTypography.weight(
                  AppTypography.label,
                  AppTypography.medium,
                ).copyWith(color: color, fontSize: 11, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
