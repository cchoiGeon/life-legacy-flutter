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

  /// 명조 — 시안이 지정한 **Noto Serif KR** 그대로다.
  /// 화면 제목 · 질문 · 책 본문이 쓴다.
  ///
  /// ⚠️ 예전에는 나눔명조로 대체했지만 자형이 달라 시안과 겹쳐 보면 어긋난다.
  static const bookFamily = 'NotoSerifKR';

  /// 명조도 가변 폰트라 wght 축을 직접 줘야 한다.
  ///
  /// ⚠️ Noto Serif KR의 wght **기본값은 200(ExtraLight)** 이다. 축을 안 주면
  ///    `fontWeight: bold`를 적어도 실처럼 얇게 나온다 — 나눔명조(정적 400/700)
  ///    때는 없던 문제다.
  static const _serifRegular = [FontVariation('wght', 400)];
  static const _serifBold = [FontVariation('wght', 700)];

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

  // ── 화면 골격 — 시안 340:592(★★ 최종 A~F)의 공통 배치 ────────
  //
  // A~F 전 화면이 같은 뼈대를 쓴다: ← / 제목 / 부제 / 본문 / 하단 CTA.
  // 아래 넷은 그 자리에만 쓰는 스타일이라 따로 묶어 뒀다.

  /// 화면 제목 — **명조** 28 · 행간 42 · 자간 -0.6.
  ///
  /// ⚠️ 예전에는 고딕 `titlePage`(24)였다. 새 시안은 제목만 명조로 돌려
  ///    "읽는 영역"과 "누르는 영역"을 서체로 갈라놓는다. 버튼·라벨은
  ///    그대로 고딕이다 — 여기에 [titlePage]를 쓰면 그 구분이 무너진다.
  static const titleScreen = TextStyle(
    fontFamily: bookFamily,
    color: AppColors.textPrimary,
    fontSize: 28,
    height: 42 / 28,
    fontWeight: bold,
    fontVariations: _serifBold,
    letterSpacing: -0.6,
  );

  /// 제목 아래 한 줄 설명 — 16 · `text-secondary`.
  ///
  /// ⚠️ 행간이 **19**다(16px에 24가 아니다). 시안 342:681의 한 줄 높이가
  ///    19라, 24로 잡으면 아래 입력칸이 5px씩 밀려 내려간다.
  ///    여러 줄로 쓰는 곳(B6 안내문 등)은 호출부에서 `height`를 다시 준다.
  static final subtitle = _style(
    size: 16,
    lineHeight: 19,
    letterSpacing: -0.1,
  ).copyWith(color: AppColors.textSecondary);

  /// 화면 안 구획 제목 — 명조 26 · 자간 -0.5 (시안 351:970 `이렇게 정리했어요`).
  /// [titleScreen]보다 한 단계 작다. 진행바 아래에서 시작하는 화면이 쓴다.
  static const titleSerifSm = TextStyle(
    fontFamily: bookFamily,
    color: AppColors.textPrimary,
    fontSize: 26,
    height: 38 / 26,
    fontWeight: bold,
    fontVariations: _serifBold,
    letterSpacing: -0.5,
  );

  /// 하단 주 CTA 라벨 — 18 Bold (시안 346:820).
  static final ctaLabel = _style(
    size: 18,
    lineHeight: 26,
    weight: bold,
    letterSpacing: -0.2,
  );

  /// 하단 보조 버튼 라벨 — 17 Bold (시안 351:978 `다시 말하기`).
  static final ctaLabelSecondary = _style(
    size: 17,
    lineHeight: 25,
    weight: bold,
    letterSpacing: -0.2,
  );

  /// 본문 안 보조 버튼 라벨 — 16 Bold (시안 341:668 `글로 답하기`).
  static final ctaLabelAssist = _style(
    size: 16,
    lineHeight: 24,
    weight: bold,
    letterSpacing: -0.1,
  );

  /// 진행률 바 아래 "질문 3 / 6" — 14 Medium (시안 341:653).
  static final metaLabel = _style(
    size: 14,
    lineHeight: 20,
    weight: medium,
    letterSpacing: 0.2,
  ).copyWith(color: AppColors.textTertiary);

  /// 자기소개 선택지 라벨 — 20 Bold (시안 346:812).
  static final optionLabel = _style(
    size: 20,
    lineHeight: 28,
    weight: bold,
    letterSpacing: -0.2,
  );

  /// 우상단 진행 표시 "3 / 5" · 타이머 "2분 47초 남음" — 15 Medium.
  static final stepLabel = _style(
    size: 15,
    lineHeight: 22,
    weight: medium,
    letterSpacing: 0.2,
  ).copyWith(color: AppColors.textTertiary);

  // ── Book serif — 자서전 본문 전용 ───────────────────────────

  /// 책 본문. 행간을 넉넉히(1.9) 둬서 읽는 호흡을 늦춘다.
  static const bookBody = TextStyle(
    fontFamily: bookFamily,
    color: AppColors.textPrimary,
    fontSize: 16,
    height: 1.9,
    fontWeight: regular,
    fontVariations: _serifRegular,
  );

  /// 책 장 제목
  static const bookTitle = TextStyle(
    fontFamily: bookFamily,
    color: AppColors.textPrimary,
    fontSize: 22,
    height: 1.5,
    fontWeight: bold,
    fontVariations: _serifBold,
  );

  /// 로고 워드마크 "Life Legacy" — 명조 Bold.
  ///
  /// ⚠️ 예전에는 대문자 "LIFE LEGACY"에 자간 2.4를 줬다. 새 시안(341:727)은
  ///    **대소문자 그대로** 쓰고 자간도 0.4로 좁다. 대문자로 늘려 놓으면
  ///    본문 명조와 다른 서체처럼 보인다.
  static const wordmark = TextStyle(
    fontFamily: bookFamily,
    color: AppColors.textBrand,
    fontSize: 30,
    height: 1.3,
    fontWeight: bold,
    fontVariations: _serifBold,
    letterSpacing: 0.3,
  );

  /// 브랜드 문구 — "말로 이야기하면 자서전이 됩니다" (명조 Regular 18).
  static const brandTagline = TextStyle(
    fontFamily: bookFamily,
    color: AppColors.textSecondary,
    fontSize: 18,
    height: 31 / 18,
    fontWeight: regular,
    fontVariations: _serifRegular,
    letterSpacing: -0.2,
  );
}
