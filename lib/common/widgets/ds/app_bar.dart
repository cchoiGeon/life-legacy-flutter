import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 상단 바 — 뒤로가기 · 가운데 제목 · 오른쪽 액션.
///
/// 시안의 화면들은 세 조합만 쓴다:
///   · 뒤로가기만 (02·03·05번)
///   · 뒤로가기 + 가운데 제목 + 오른쪽 (07·13·20번)
///   · 왼쪽 텍스트 + 제목 + 오른쪽 텍스트 (18번 "취소 / 직접 고치기 / 저장")
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.onBack,
    this.showBack = true,
    this.leading,
    this.trailing,
    this.background,
    this.centerTitle = true,
  });

  final String? title;

  /// null이면 `Get.back()`. 확인 다이얼로그를 끼워야 할 때만 넘긴다.
  final VoidCallback? onBack;

  final bool showBack;

  /// 뒤로가기 대신 놓을 것(예: "취소" 텍스트 버튼)
  final Widget? leading;

  final Widget? trailing;

  final Color? background;

  /// false면 뒤로가기 바로 오른쪽에 붙는다 (알림 센터처럼 목록형 화면).
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background ?? AppColors.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: AppDimens.headerHeight,
          child: Stack(
            children: [
              if (title != null)
                Align(
                  alignment: centerTitle
                      ? Alignment.center
                      : Alignment.centerLeft,
                  child: Padding(
                    // 좌우 액션과 겹치지 않게 여백을 준다.
                    padding: centerTitle
                        ? const EdgeInsets.symmetric(horizontal: 72)
                        : const EdgeInsets.only(left: 52, right: 60),
                    child: Text(
                      title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.weight(
                        AppTypography.titleSection,
                        AppTypography.bold,
                      ).copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child:
                    leading ??
                    (showBack
                        ? _BackButton(onTap: onBack ?? Get.back)
                        : const SizedBox.shrink()),
              ),
              if (trailing != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppDimens.space4),
                    child: trailing,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '뒤로',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: AppDimens.touchMin,
          height: AppDimens.touchMin,
          child: CustomPaint(painter: _ChevronPainter()),
        ),
      ),
    );
  }
}

/// 왼쪽 꺾쇠. 시안의 '‹' 글리프를 그대로 쓰면 폰트마다 두께가 달라져서
/// 직접 그린다.
class _ChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.textStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawPath(
      Path()
        ..moveTo(cx + 4, cy - 8)
        ..lineTo(cx - 4, cy)
        ..lineTo(cx + 4, cy + 8),
      p,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter oldDelegate) => false;
}

/// 상단 바 오른쪽에 놓는 텍스트 액션 ("저장", "취소").
class AppTextAction extends StatelessWidget {
  const AppTextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.emphasized = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;

  /// 브랜드색 + 굵게 (주 액션)
  final bool emphasized;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space2,
            vertical: AppDimens.space3,
          ),
          child: Text(
            label,
            style:
                AppTypography.weight(
                  AppTypography.bodySm,
                  emphasized ? AppTypography.bold : AppTypography.medium,
                ).copyWith(
                  color: !enabled
                      ? AppColors.textDisabled
                      : (emphasized
                            ? AppColors.brand
                            : AppColors.textSecondary),
                ),
          ),
        ),
      ),
    );
  }
}
