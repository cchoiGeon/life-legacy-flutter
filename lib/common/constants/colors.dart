import 'package:flutter/widgets.dart';

/// Life Legacy 색 토큰 — Figma `life-legacy 디자인 시스템`(node 130:2) 이식.
///
/// 컨셉: **웜 브라운 팔레트 · 파란색 미사용**. 시니어 친화 자서전 앱이라
/// 차가운 색을 쓰지 않고 종이·나무 계열로 안정감을 준다.
///
/// ⚠️ 화면에서 raw hex를 쓰지 않는다. 반드시 아래 semantic alias를 참조한다.
abstract final class AppColors {
  // ── Brand · 웜 브라운 ───────────────────────────────────────
  /// 주 브랜드색. Primary 버튼 배경 · 로고 원.
  static const brand = Color(0xFF6B5344);

  /// 사용자 채팅 버블 (브랜드보다 한 톤 밝다)
  static const bubbleUser = Color(0xFF7C6B5A);

  /// 강조 · 진행률 바 · 장식 (모래빛)
  static const warm = Color(0xFFC4A77D);

  /// 비활성 버튼 배경
  static const btnMuted = Color(0xFFD4C4B0);

  /// 시스템(AI) 채팅 버블 배경
  static const bubbleSys = Color(0xFFF0EBE3);

  /// 카드·섹션 크림 배경
  static const cream = Color(0xFFF5F0E8);

  /// 브랜드 위 전경색 (순백이 아닌 살짝 따뜻한 흰색)
  static const brandFg = Color(0xFFFDFCFB);

  /// 유일한 청록 포인트 — 녹음 중 표시에만 쓴다.
  /// 파란색 금지 규칙의 예외가 아니라 "차분한 청록"으로 허용된 값이다.
  static const accentSoft = Color(0xFF5C7C7E);

  // ── Neutral · Stone scale ──────────────────────────────────
  static const stone50 = Color(0xFFFAFAF9);
  static const stone100 = Color(0xFFF5F5F4);
  static const stone200 = Color(0xFFE7E5E4);
  static const stone300 = Color(0xFFD6D3D1);
  static const stone400 = Color(0xFFA8A29E);
  static const stone500 = Color(0xFF78716C);
  static const stone600 = Color(0xFF57534E);
  static const stone700 = Color(0xFF44403C);

  // ── Semantic · 상태·역할 ───────────────────────────────────
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF262626);
  static const border = Color(0xFFE5E5E5);
  static const mutedFg = Color(0xFF737373);
  static const destructive = Color(0xFFDC2626);

  // ══════════════════════════════════════════════════════════
  // Semantic aliases — 컴포넌트는 여기만 참조한다
  // ══════════════════════════════════════════════════════════

  // Action
  static const primary = brand;

  /// 눌림 상태. 시안에 별도 값이 없어 브랜드색을 어둡게 파생시켰다.
  static const primaryPress = Color(0xFF574336);
  static const onPrimary = brandFg;
  static const primaryDisabled = btnMuted;

  // Text
  static const textPrimary = foreground;

  /// 컴포넌트 안쪽 제목·라벨. 시안은 본문 검정(#262626)과 구분해서
  /// 살짝 부드러운 stone-700을 쓴다.
  static const textStrong = stone700;
  static const textSecondary = stone600;
  static const textTertiary = mutedFg;
  static const textDisabled = stone400;
  static const textOnPrimary = brandFg;

  /// 브랜드색 글자 (로고 워드마크 · 강조 수치)
  static const textBrand = brand;

  // Surface
  static const surfacePage = background;

  /// 온보딩·완성 화면처럼 종이 느낌을 주는 배경
  static const surfaceWarm = cream;
  static const surfaceCard = background;
  static const surfaceSunken = stone100;
  static const overlayScrim = Color(0x66262626);

  // Border
  static const borderSubtle = stone100;
  static const borderDefault = border;
  static const borderStrong = stone300;
  static const borderFocus = brand;

  // Chat
  static const chatAiBg = bubbleSys;
  static const chatAiFg = foreground;
  static const chatUserBg = bubbleUser;
  static const chatUserFg = brandFg;

  // Progress
  static const progressTrack = stone200;

  /// ⚠️ 진행률 채움은 `warm`이 아니라 **브랜드색**이다(시안 130:2179).
  ///    warm은 장식·구분선 쪽에 쓴다.
  static const progressFill = brand;

  /// 브랜드 배경 위에 얹히는 진행률(홈 카드 안)
  static const progressTrackOnBrand = Color(0x33FDFCFB);
  static const progressFillOnBrand = brandFg;
}
