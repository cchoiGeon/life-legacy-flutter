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
                      // 시안 341:649 — Medium 16. 제목이 굵으면 그 아래
                      // 명조 화면 제목과 경쟁한다.
                      style: AppTypography.weight(
                        AppTypography.bodyBase,
                        AppTypography.medium,
                      ).copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: -0.1,
                      ),
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

/// 왼쪽 **화살표**. 시안 342:679가 꺾쇠(`‹`)가 아니라 `←`로 바뀌었다 —
/// 꺾쇠는 목록 안의 "더 보기"에도 쓰여서 뒤로가기와 헷갈렸다.
///
/// 글리프를 그대로 쓰지 않고 직접 그리는 이유는 그대로다: 폰트마다 `←`의
/// 두께와 세로 위치가 달라 상단 바에서 흔들린다.
class _ChevronPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas
      ..drawLine(Offset(cx - 9, cy), Offset(cx + 9, cy), p)
      ..drawPath(
        Path()
          ..moveTo(cx - 2, cy - 7)
          ..lineTo(cx - 9, cy)
          ..lineTo(cx - 2, cy + 7),
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
                  // 시안의 상단 텍스트 액션(`보내기`·`모두 읽음`)은 15다.
                  AppTypography.bodyChat,
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
