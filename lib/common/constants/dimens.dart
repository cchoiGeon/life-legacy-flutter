import 'package:flutter/widgets.dart';

/// Life Legacy 간격·반경·그림자 토큰.
/// Figma `sec/Spacing`(130:2050) · `sec/Radius`(130:2092) ·
/// `sec/Elevation`(130:2110) 이식.
abstract final class AppDimens {
  // ── Spacing (4px 그리드) ───────────────────────────────────
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 20.0;
  static const space6 = 24.0;
  static const space8 = 32.0;
  static const space10 = 40.0;
  static const space12 = 48.0;
  static const space16 = 64.0;

  // ── Semantic spacing ───────────────────────────────────────
  /// 화면 좌우 여백
  static const gutter = 24.0;
  static const sectionGap = 32.0;

  // ── Touch targets ──────────────────────────────────────────
  /// 시니어 대상이라 iOS 권장(44)보다 크게 잡는다.
  static const touchMin = 48.0;

  // ── Layout ─────────────────────────────────────────────────
  /// 시안 프레임 폭. 태블릿에서 가운데 정렬 기준이 된다.
  static const maxContent = 430.0;
  static const headerHeight = 56.0;
  static const tabbarHeight = 64.0;

  // ── Button heights ─────────────────────────────────────────
  static const buttonSm = 36.0;
  static const buttonMd = 44.0;

  /// 주요 CTA. 시안의 하단 버튼 높이.
  static const buttonLg = 56.0;

  // ── Radius ─────────────────────────────────────────────────
  static const radiusBase = 12.0;
  static const radiusCard = 16.0;
  static const radiusSheet = 20.0;
  static const radiusBubble = 18.0;
  static const radiusPill = 999.0;

  // ── Border widths ──────────────────────────────────────────
  static const borderWidth = 1.0;
  static const borderWidthStrong = 1.5;
}

/// Elevation — Figma 이펙트 스타일 `shadow/sm · md · lg` 실측값.
///
/// 그림자 색은 stone-900(#1C1917)이다. 순수 검정보다 따뜻해서 크림 배경
/// 위에 얹혔을 때 회색으로 뜨지 않는다.
abstract final class AppShadows {
  static const _ink = Color(0xFF1C1917);

  static const none = <BoxShadow>[];

  /// 카드 기본
  static final sm = [
    BoxShadow(
      color: _ink.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: _ink.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  /// 주요 버튼 · 토스트
  static final md = [
    BoxShadow(
      color: _ink.withValues(alpha: 0.04),
      offset: const Offset(0, 2),
      blurRadius: 4,
    ),
    BoxShadow(
      color: _ink.withValues(alpha: 0.06),
      offset: const Offset(0, 6),
      blurRadius: 16,
    ),
  ];

  /// 다이얼로그
  static final lg = [
    BoxShadow(
      color: _ink.withValues(alpha: 0.05),
      offset: const Offset(0, 4),
      blurRadius: 8,
    ),
    BoxShadow(
      color: _ink.withValues(alpha: 0.10),
      offset: const Offset(0, 12),
      blurRadius: 32,
    ),
  ];

  /// 하단 입력 바 — 위로 드리운다.
  /// 시안에 없는 값이라 md를 뒤집어 만들었다.
  static final composer = [
    BoxShadow(
      color: _ink.withValues(alpha: 0.06),
      offset: const Offset(0, -2),
      blurRadius: 12,
    ),
  ];
}

/// Motion — 느리고 차분하게. 시니어 대상이라 급한 전환을 쓰지 않는다.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 400);

  static const standard = Cubic(0.2, 0, 0, 1);

  /// 눌림 축소 배율
  static const pressScale = 0.97;
}
