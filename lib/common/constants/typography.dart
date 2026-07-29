import 'package:flutter/widgets.dart';

import 'colors.dart';

/// Life Legacy 타이포 토큰 — Figma `sec/Typography`(node 130:2017) 이식.
///
/// 시니어 사용자가 주 대상이라 **본문 기준이 16px**로 크다(일반 앱은 14~15).
/// 스케일 이름과 값은 시안 그대로다:
///   Display/3xl 32 Bold · Title/page 24 Bold · Heading/xl 20 Bold ·
///   Title/section 18 Medium · Body/base 16 · Body/chat 15 ·
///   Body/sm 14 · Caption 13 · Label 12 Medium
abstract final class AppTypography {
  static const fontFamily = 'NotoSansKR';

  /// 자서전 본문 전용 명조. 시안의 "Book serif".
  static const bookFamily = 'NanumMyeongjo';

  // ── Weights ────────────────────────────────────────────────
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;

  /// 가변 폰트의 wght 축 지정.
  ///
  /// ⚠️ Noto Sans KR은 가변 폰트 파일 하나로만 배포돼서 pubspec에 굵기별
  ///    등록을 할 수 없다(pubspec.yaml 주석 참고). `fontWeight`만 주면
  ///    굵기가 바뀌지 않으므로 `fontVariations`로 축을 직접 지정한다.
  ///    둘 다 넣는 이유: fontWeight는 폴백 폰트(명조 등)에서 여전히 의미가 있다.
  static List<FontVariation> _wght(FontWeight w) => [
    FontVariation('wght', w.value.toDouble()),
  ];

  /// 스케일은 그대로 두고 굵기만 바꾼다.
  ///
  /// ⚠️ `style.copyWith(fontWeight: ...)`만 쓰면 **굵기가 안 바뀐다**
  ///    (가변 폰트라 wght 축을 같이 줘야 한다). 굵기를 조정할 땐 항상 이걸 쓴다.
  static TextStyle weight(TextStyle base, FontWeight w) =>
      base.copyWith(fontWeight: w, fontVariations: _wght(w));

  static TextStyle _style({
    required double size,
    required double lineHeight,
    FontWeight weight = regular,
    double letterSpacing = 0,
  }) => TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    fontVariations: _wght(weight),
    letterSpacing: letterSpacing,
  );

  // ── Type scale ─────────────────────────────────────────────

  /// 32 · Bold — 온보딩 히어로
  static final display3xl = _style(
    size: 32,
    lineHeight: 44,
    weight: bold,
    letterSpacing: -0.64,
  );

  /// 24 · Bold — 화면 제목
  static final titlePage = _style(
    size: 24,
    lineHeight: 33,
    weight: bold,
    letterSpacing: -0.48,
  );

  /// 20 · Bold — 섹션 제목
  static final headingXl = _style(
    size: 20,
    lineHeight: 28,
    weight: bold,
    letterSpacing: -0.3,
  );

  /// 18 · Medium — 카드 제목 · 목록 항목
  static final titleSection = _style(
    size: 18,
    lineHeight: 26,
    weight: medium,
    letterSpacing: -0.18,
  );

  /// 16 · Regular — 기본 본문
  static final bodyBase = _style(size: 16, lineHeight: 26);

  /// 15 · Regular — 채팅 버블
  static final bodyChat = _style(size: 15, lineHeight: 24);

  /// 14 · Regular — 보조 본문
  static final bodySm = _style(size: 14, lineHeight: 22);

  /// 13 · Regular — 캡션
  static final caption = _style(size: 13, lineHeight: 19);

  /// 12 · Medium — 라벨 · 뱃지
  static final label = _style(
    size: 12,
    lineHeight: 17,
    weight: medium,
    letterSpacing: 0.12,
  );

  // ── Book serif — 자서전 본문 전용 ───────────────────────────

  /// 책 본문. 행간을 넉넉히(1.9) 둬서 읽는 호흡을 늦춘다.
  static const bookBody = TextStyle(
    fontFamily: bookFamily,
    color: AppColors.textPrimary,
    fontSize: 16,
    height: 1.9,
    fontWeight: regular,
  );

  /// 책 장 제목
  static const bookTitle = TextStyle(
    fontFamily: bookFamily,
    color: AppColors.textPrimary,
    fontSize: 22,
    height: 1.5,
    fontWeight: bold,
  );

  /// 로고 워드마크 "LIFE LEGACY" — 명조 + 넓은 자간
  static const wordmark = TextStyle(
    fontFamily: bookFamily,
    color: AppColors.textBrand,
    fontSize: 20,
    height: 1.4,
    fontWeight: bold,
    letterSpacing: 2.4,
  );
}
