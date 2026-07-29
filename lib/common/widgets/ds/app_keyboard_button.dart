import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// "키보드로 입력할게요" 버튼 — Figma `158:370`.
///
/// 음성 입력 화면에서 키보드 입력으로 넘어가는 전용 버튼이다.
/// 자기소개(07)와 작성(13) **두 곳에서 같은 컴포넌트를 쓴다.**
///
/// 시안 실측: 흰 배경 · 테두리 1.5px `#e5e5e5` · 알약 · 좌우 16 상하 11 ·
/// 아이콘 20px · 간격 8 · 본문 16px 브랜드색.
/// (AppButton의 neutral 변형과 다르다 — 저쪽은 모서리 12px에 글자가 회색이다.)
class AppKeyboardButton extends StatefulWidget {
  const AppKeyboardButton({
    super.key,
    required this.onPressed,
    this.label = '키보드로 입력할게요',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  State<AppKeyboardButton> createState() => _AppKeyboardButtonState();
}

class _AppKeyboardButtonState extends State<AppKeyboardButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? AppMotion.pressScale : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: _pressed ? AppColors.stone100 : AppColors.surfacePage,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              border: Border.all(
                color: AppColors.borderDefault,
                width: AppDimens.borderWidthStrong,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Figma에서 내보낸 에셋 그대로. 획 색이 브랜드색으로 박혀 있어
                // colorFilter를 따로 걸지 않는다.
                SvgPicture.asset(
                  'assets/icons/keyboard.svg',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: AppDimens.space2),
                Text(
                  widget.label,
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.brand,
                    letterSpacing: -0.16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
