import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 목차 한 줄의 상태.
///
/// 도메인 `ChapterStatus`와 값이 같지만 일부러 따로 뒀다 — 디자인 시스템이
/// 데이터 모델을 알면 목차 외의 곳에서 이 줄을 재활용할 수 없다. 화면이
/// `switch` 한 줄로 옮겨 준다.
enum AppChapterState { done, writing, locked }

/// 홈 목차 한 줄 — Figma 341:614 (C1) · 348:815 (C2).
///
/// 상태에 따라 셋이 한꺼번에 바뀐다:
///
/// | 상태 | 뱃지 | 제목 | 오른쪽 |
/// |---|---|---|---|
/// | [AppChapterState.done] | 청록 + ✓ | Bold 검정 | `완료` 청록 |
/// | [AppChapterState.writing] | 브랜드 + 번호 | Bold 검정 | `3/8` 브랜드 |
/// | [AppChapterState.locked] | 크림 + 번호 | **Regular** 회색 | 없음 |
///
/// 잠긴 장만 제목이 Regular다. 굵기까지 낮춰야 "아직 못 여는 곳"으로 읽힌다.
class AppChapterRow extends StatelessWidget {
  const AppChapterRow({
    super.key,
    required this.number,
    required this.title,
    required this.state,
    this.trailing,
    this.onTap,
  });

  final int number;
  final String title;
  final AppChapterState state;

  /// 오른쪽 상태 글자 — `완료` · `3/8` · `시작하기`. 잠긴 장은 null.
  final String? trailing;

  final VoidCallback? onTap;

  /// 오른쪽 상태 글자가 화면 끝에 붙지 않게 남기는 여백.
  ///
  /// ⚠️ 시안(341:614)은 342 폭 안에서 줄 내용을 **298**까지만 쓴다.
  ///    구분선은 342 전체를 가로지른다 — 그래서 이 값만큼 어긋나 보이는 게
  ///    맞다. 0으로 만들면 상태 글자가 화면 가장자리에 닿는다.
  static const trailingInset = 44.0;

  @override
  Widget build(BuildContext context) {
    final locked = state == AppChapterState.locked;
    final accent = switch (state) {
      AppChapterState.done => AppColors.accentSoft,
      AppChapterState.writing => AppColors.brand,
      AppChapterState.locked => AppColors.textTertiary,
    };

    // 제목·상태 글자는 안쪽 [Text]가 내보낸다 — `label:`을 겹쳐 주면 두 번 읽힌다.
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.only(right: trailingInset),
            child: Row(
              children: [
                _Badge(number: number, state: state),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (locked
                                ? AppTypography.bodyBase
                                : AppTypography.weight(
                                    AppTypography.bodyBase,
                                    AppTypography.bold,
                                  ))
                            .copyWith(
                              fontSize: 17,
                              height: 1.3,
                              letterSpacing: -0.2,
                              color: locked
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                            ),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppDimens.space2),
                  Text(
                    trailing!,
                    style: AppTypography.weight(
                      AppTypography.bodySm,
                      AppTypography.bold,
                    ).copyWith(color: accent, height: 1.2),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 자서전 목록의 장 카드 — Figma 341:677 (E1).
///
/// [AppChapterRow]와 같은 정보를 담지만 모양이 다르다. 홈은 카드 아래
/// 곁들이는 목록이라 구분선만 긋고, 여기는 화면의 본체라 카드로 세운다.
///
/// | 상태 | 배경 | 테두리 |
/// |---|---|---|
/// | [AppChapterState.done] | 흰색 | 연한 회색 1 |
/// | [AppChapterState.writing] | 흰색 | **브랜드 1.5 + 그림자** |
/// | [AppChapterState.locked] | 크림 | 없음 |
///
/// 진행 중인 장에만 테두리와 그림자를 줘서 "지금 여기"를 한눈에 찍어 준다.
class AppChapterCard extends StatelessWidget {
  const AppChapterCard({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.state,
    this.trailing,
    this.onTap,
  });

  final int number;
  final String title;

  /// "질문 8개 모두 답했어요" · "다음 질문 · 첫 소풍의 기억" · "2장을 마치면 열려요"
  final String subtitle;

  final AppChapterState state;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = state == AppChapterState.locked;
    final current = state == AppChapterState.writing;
    final accent = state == AppChapterState.done
        ? AppColors.accentSoft
        : AppColors.brand;

    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: locked ? AppColors.cream : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(18),
            border: locked
                ? null
                : Border.all(
                    color: current
                        ? AppColors.brand
                        : AppColors.borderSoft,
                    width: current
                        ? AppDimens.borderWidthStrong
                        : AppDimens.borderWidth,
                  ),
            boxShadow: current ? AppShadows.md : null,
          ),
          child: Row(
            children: [
              _Badge(number: number, state: state, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (locked
                                  ? AppTypography.bodyBase
                                  : AppTypography.weight(
                                      AppTypography.bodyBase,
                                      AppTypography.bold,
                                    ))
                              .copyWith(
                                fontSize: 17,
                                height: 1.3,
                                letterSpacing: -0.2,
                                color: locked
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySm.copyWith(
                        height: 1.3,
                        letterSpacing: -0.1,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppDimens.space2),
                Text(
                  trailing!,
                  style: AppTypography.weight(
                    AppTypography.bodySm,
                    AppTypography.bold,
                  ).copyWith(color: accent, height: 1.2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 목차 줄 사이 구분선 — 줄 안쪽 여백과 달리 **가로 전체**를 가로지른다.
class AppChapterRule extends StatelessWidget {
  const AppChapterRule({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: AppColors.borderSoft);
}

class _Badge extends StatelessWidget {
  const _Badge({required this.number, required this.state, this.size = 28});

  final int number;
  final AppChapterState state;

  /// 홈 목록은 28, 자서전 카드는 32.
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (state) {
      AppChapterState.done => (AppColors.accentSoft, AppColors.brandFg),
      AppChapterState.writing => (AppColors.brand, AppColors.brandFg),
      AppChapterState.locked => (AppColors.surfaceSoft, AppColors.textTertiary),
    };
    final done = state == AppChapterState.done;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        done ? '✓' : '$number',
        style: AppTypography.weight(
          AppTypography.bodySm,
          AppTypography.bold,
        ).copyWith(
          // 체크는 숫자보다 글리프가 작아서 한 급 키워야 같은 크기로 보인다.
          fontSize: (done ? 14 : 13) * size / 28,
          height: 1.2,
          color: fg,
        ),
      ),
    );
  }
}
