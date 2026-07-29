import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 버튼 변형 — Figma `sec/버튼 · Button`(130:2131)의 6종.
enum AppButtonVariant {
  /// 브랜드 채움. 화면당 하나만 쓴다.
  primary,

  /// 브랜드 테두리 + 브랜드 글자
  outline,

  /// 크림 채움 — "다시 들려줘"처럼 가벼운 보조 액션
  soft,

  /// 회색 테두리 — "닫기"
  neutral,

  /// 배경·테두리 없음 — "취소"
  ghost,

  /// 파괴적 액션 — "삭제"
  danger,
}

/// sm 13px · md 15px · lg 16px (시안의 세 가지 패딩 조합)
enum AppButtonSize { sm, md, lg }

/// 시안 버튼. 눌림은 살짝 축소(0.97) + 배경 어둡게.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.block = false,
    this.loading = false,
    this.enabled = true,
    this.icon,
  });

  final String label;

  /// null이면 비활성으로 본다.
  final VoidCallback? onPressed;

  final AppButtonVariant variant;
  final AppButtonSize size;

  /// 가로 100% — 하단 CTA
  final bool block;

  /// 진행 중. 시안의 "저장 중..." 상태와 같은 모양이 된다.
  final bool loading;

  final bool enabled;

  /// 글자 왼쪽 아이콘(이모지 텍스트도 가능)
  final Widget? icon;

  bool get _disabled => !enabled || loading || onPressed == null;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  ({double padX, double padY, TextStyle text}) get _metrics => switch (widget
      .size) {
    AppButtonSize.sm => (padX: 14.0, padY: 6.0, text: AppTypography.caption),
    AppButtonSize.md => (padX: 20.0, padY: 11.0, text: AppTypography.bodyChat),
    AppButtonSize.lg => (padX: 24.0, padY: 16.0, text: AppTypography.bodyBase),
  };

  ({Color bg, Color press, Color fg, Color? border}) get _palette =>
      switch (widget.variant) {
        AppButtonVariant.primary => (
          bg: AppColors.primary,
          press: AppColors.primaryPress,
          fg: AppColors.onPrimary,
          border: null,
        ),
        AppButtonVariant.outline => (
          bg: const Color(0x00000000),
          press: AppColors.bubbleSys,
          fg: AppColors.brand,
          border: AppColors.brand,
        ),
        AppButtonVariant.soft => (
          bg: AppColors.bubbleSys,
          press: AppColors.btnMuted,
          fg: AppColors.brand,
          border: null,
        ),
        AppButtonVariant.neutral => (
          bg: AppColors.background,
          press: AppColors.stone100,
          fg: AppColors.textStrong,
          border: AppColors.stone200,
        ),
        AppButtonVariant.ghost => (
          bg: const Color(0x00000000),
          press: AppColors.stone100,
          fg: AppColors.textSecondary,
          border: null,
        ),
        AppButtonVariant.danger => (
          bg: AppColors.destructive,
          press: const Color(0xFFB91C1C),
          fg: AppColors.onPrimary,
          border: null,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final m = _metrics;
    final p = _palette;
    final disabled = widget._disabled;

    // 비활성·진행중은 시안의 "저장 중..." 칩과 같은 모양 —
    // 색을 흐리게 하는 대신 muted 배경으로 바꾼다.
    final bg = disabled && widget.variant == AppButtonVariant.primary
        ? AppColors.primaryDisabled
        : (_pressed ? p.press : p.bg);

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? AppMotion.pressScale : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: Opacity(
            opacity: disabled && !widget.loading ? 0.7 : 1,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              width: widget.block ? double.infinity : null,
              padding: EdgeInsets.symmetric(
                horizontal: m.padX,
                vertical: m.padY,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppDimens.radiusBase),
                border: p.border == null
                    ? null
                    : Border.all(
                        color: p.border!,
                        width: AppDimens.borderWidthStrong,
                      ),
              ),
              child: Row(
                mainAxisSize: widget.block
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    widget.icon!,
                    const SizedBox(width: AppDimens.space2),
                  ],
                  Flexible(
                    child: Text(
                      widget.loading ? '저장 중...' : widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.weight(
                        m.text,
                        AppTypography.medium,
                      ).copyWith(height: 1.2, color: p.fg),
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

/// 알약 모양 보조 칩 — "🔊 다시 들려줘", "■ 멈춤".
/// Figma `pill`(130:2221 · 130:2268).
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.onTap,
    this.danger = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;

  /// "멈춤"처럼 빨간 계열로 표시할지
  final bool danger;

  /// 채팅 말풍선 아래 붙는 작은 크기(12px)
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? AppColors.destructive : AppColors.brand;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 13,
            vertical: compact ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: danger && !compact
                ? const Color(0xFFFEF2F2)
                : AppColors.brandFg,
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            border: danger && !compact
                ? null
                : Border.all(
                    color: AppColors.stone200,
                    width: compact
                        ? AppDimens.borderWidth
                        : AppDimens.borderWidthStrong,
                  ),
          ),
          child: Text(
            label,
            style: AppTypography.weight(
              compact ? AppTypography.label : AppTypography.caption,
              AppTypography.medium,
            ).copyWith(color: fg),
          ),
        ),
      ),
    );
  }
}

/// 원형 아이콘 버튼 — 채팅 입력줄의 마이크·전송(44px).
class AppCircleButton extends StatelessWidget {
  const AppCircleButton({
    super.key,
    required this.child,
    this.onTap,
    this.filled = false,
    this.size = 44,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// true면 브랜드 채움(전송), false면 크림 채움(마이크)
  final bool filled;

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.brand : AppColors.bubbleSys,
            shape: BoxShape.circle,
          ),
          child: child,
        ),
      ),
    );
  }
}
