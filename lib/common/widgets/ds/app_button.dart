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

/// 버튼 크기.
///
/// [sm]·[md]는 패딩으로 높이가 정해지는 인라인 버튼이고, 아래 셋은 시안
/// 340:592가 **고정 높이 + 알약 반경**으로 그린 것이다:
///
/// | 크기 | 높이 | 반경 | 라벨 | 쓰는 곳 |
/// |---|---|---|---|---|
/// | [lg] | 62 | 31 | 18 Bold | 하단 주 CTA (`btn/다음`·`btn/저장하기`) |
/// | [card] | 60 | 30 | 18 Bold | 카드 **안**의 CTA (`말로 답하기`) |
/// | [secondary] | 58 | 29 | 17 Bold | 주 CTA 아래 보조 (`다시 말하기`) |
/// | [assist] | 50 | 25 | 16 Bold | 본문 안 보조 (`글로 답하기`) |
enum AppButtonSize { sm, md, lg, card, secondary, assist }

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
    this.minHeight,
    this.labelStyle,
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

  /// 시안 기본 높이(패딩으로 정해진다)보다 크게 잡아야 할 때만 쓴다.
  ///
  /// ⚠️ 예외용이다. 화면 대부분은 [size]로 충분하다. 자기소개의 "예 / 아니요"
  ///    처럼 **그 화면의 유일한 조작**이라 손에 잡히게 키워야 하는 경우만.
  final double? minHeight;

  /// 라벨 스타일 교체 — **굵기까지 그대로 쓴다.** [size]가 정한 스타일을
  /// 통째로 갈아 끼우므로 시안에 없는 조합이 나오지 않게 조심한다.
  final TextStyle? labelStyle;

  bool get _disabled => !enabled || loading || onPressed == null;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  /// [height]가 있으면 세로 패딩 대신 그 높이로 고정하고 반경도 알약이 된다.
  ///
  /// 라벨 굵기는 여기서 이미 정해져 나온다 — 예전처럼 바깥에서 medium으로
  /// 덮어쓰지 않는다. 시안의 CTA는 medium이 아니라 **bold**다.
  ({double padX, double padY, double? height, TextStyle text}) get _metrics =>
      switch (widget.size) {
        AppButtonSize.sm => (
          padX: 14.0,
          padY: 6.0,
          height: null,
          text: AppTypography.weight(
            AppTypography.caption,
            AppTypography.medium,
          ),
        ),
        AppButtonSize.md => (
          padX: 20.0,
          padY: 11.0,
          height: null,
          text: AppTypography.weight(
            AppTypography.bodyChat,
            AppTypography.medium,
          ),
        ),
        AppButtonSize.lg => (
          padX: 24.0,
          padY: 0.0,
          height: AppDimens.buttonCta,
          text: AppTypography.ctaLabel,
        ),
        AppButtonSize.card => (
          padX: 24.0,
          padY: 0.0,
          height: AppDimens.buttonCard,
          text: AppTypography.ctaLabel,
        ),
        AppButtonSize.secondary => (
          padX: 24.0,
          padY: 0.0,
          height: 58.0,
          text: AppTypography.ctaLabelSecondary,
        ),
        AppButtonSize.assist => (
          padX: 26.0,
          padY: 0.0,
          height: AppDimens.buttonAssist,
          text: AppTypography.ctaLabelAssist,
        ),
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
        // 시안 351:977 `btn/다시 말하기` · 341:667 `btn/글로 답하기` —
        // 채움 없이 `border-soft` 테두리에 `text-secondary` 글자다.
        AppButtonVariant.neutral => (
          bg: AppColors.background,
          press: AppColors.stone100,
          fg: AppColors.textSecondary,
          border: AppColors.borderSoft,
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

    // 비활성 주 버튼은 시안 343:716(`btn/확인` 비활성)처럼 `surface-soft`
    // 배경 + `text-tertiary` 글자가 된다. 흐리게(opacity) 처리하지 않는다 —
    // 크림 배경 위에서는 반투명이 지저분하게 비친다.
    final primaryOff = disabled && widget.variant == AppButtonVariant.primary;
    final bg = primaryOff
        ? AppColors.primaryDisabled
        : (_pressed ? p.press : p.bg);
    final fg = primaryOff ? AppColors.onPrimaryDisabled : p.fg;

    // 고정 높이(lg·secondary·assist)는 알약이고, 패딩으로 크는 sm·md는 기본 반경이다.
    final radius = m.height == null
        ? AppDimens.radiusBase
        : m.height! / 2;

    // 라벨은 안쪽 [Text]가 내보낸다 — 여기서 또 주면 두 번 읽힌다.
    return Semantics(
      button: true,
      enabled: !disabled,
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
            opacity: disabled && !widget.loading && !primaryOff ? 0.7 : 1,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              width: widget.block ? double.infinity : null,
              height: m.height,
              constraints: widget.minHeight == null
                  ? null
                  : BoxConstraints(minHeight: widget.minHeight!),
              padding: EdgeInsets.symmetric(
                horizontal: m.padX,
                vertical: m.padY,
              ),
              // ⚠️ `block`이 아닐 때는 alignment를 주지 않는다.
              //    Container에 alignment가 있으면 자식을 Align으로 감싸는데,
              //    Align은 부모가 준 **최대 폭까지 늘어난다.** 그래서 시안이
              //    129 폭으로 그린 "글로 답하기"가 화면 전체로 퍼졌었다.
              //    가운데 정렬은 아래 Row의 mainAxisAlignment가 이미 한다.
              alignment: widget.block ? Alignment.center : null,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(radius),
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
                      style: (widget.labelStyle ?? m.text).copyWith(
                        height: 1.2,
                        color: fg,
                      ),
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
