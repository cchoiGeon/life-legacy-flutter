import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 자기소개 선택지 한 칸 — Figma 346:736 (2지) · 346:811 (4지).
///
/// ⚠️ 예전 자기소개는 선택지 두 개를 **가로**로 놓고 고른 표시를 하지 않았다
///    (한쪽만 진해지면 기본값처럼 보인다는 이유였다). 새 시안은 세로로 쌓고
///    **고른 쪽을 크림으로 채운다** — 고른 뒤 하단 "다음"을 눌러야 넘어가므로
///    무엇을 골랐는지 화면에 남아 있어야 하기 때문이다.
///
/// 높이는 선택지 개수에 따라 다르다. 화면이 [AppChoiceTile.heightFor]로
/// 정해서 넘긴다.
class AppChoiceTile extends StatelessWidget {
  const AppChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.height,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  /// 선택지가 둘이면 96, 셋 이상이면 74. 시안 B2~B4와 B5의 차이다.
  /// 개수가 늘어도 한 화면에 들어오도록 줄어드는 값이다.
  static double heightFor(int count) => count <= 2 ? 96 : 74;

  /// 타일 사이 간격 (시안 346:810 `gap: 14`)
  static const gap = 14.0;

  @override
  Widget build(BuildContext context) {
    // ⚠️ `label:`을 따로 주지 않는다. 아래 [Text]가 이미 같은 글자를 내보내고
    //    있어서 둘을 다 주면 스크린리더가 "여성 여성"으로 두 번 읽는다.
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          height: height,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.cream : AppColors.background,
            borderRadius: BorderRadius.circular(AppDimens.radiusTile),
            border: Border.all(
              color: selected ? AppColors.borderSelected : AppColors.borderSoft,
              width: selected
                  ? AppDimens.borderWidthSelected
                  : AppDimens.borderWidthStrong,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.optionLabel.copyWith(
              color: selected ? AppColors.brand : AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
