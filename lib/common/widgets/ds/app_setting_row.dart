/// 설정 계열 화면(F1·F3·F4)이 공유하는 목록 부품 — Figma 363:901.
///
/// 예전에는 `settings_view.dart` 안의 private 위젯이었다. 시안에 내 정보(F3)와
/// 배송지 수정(F4)이 생기면서 세 화면이 같은 모양을 쓰게 돼 DS로 올렸다.
library;

import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/app_card.dart';

/// 섹션 라벨 — 앞에 7px 점이 붙는다 (시안 366:901).
///
/// 점은 장식이 아니라 **구획의 시작**을 알리는 표시다. 라벨만 있으면
/// 크림 배경 위에서 앞 그룹의 꼬리처럼 읽힌다.
class AppSettingSection extends StatelessWidget {
  const AppSettingSection(this.label, {super.key, this.dotColor});

  final String label;

  /// 점 색. 시안 366:901~903은 구획마다 **다른 색**을 쓴다 —
  /// 계정 `warm` · 알림 `accent-soft`(스위치 색과 맞춤) · 기타 `btn-muted`.
  /// null이면 warm.
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.space6, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 9),
            decoration: BoxDecoration(
              color: dotColor ?? AppColors.warm,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            label,
            style: AppTypography.weight(
              AppTypography.caption,
              AppTypography.bold,
            ).copyWith(color: AppColors.textTertiary, letterSpacing: 0.6),
          ),
        ],
      ),
    );
  }
}

/// 항목 묶음 — 흰 카드 안에 구분선으로 나눈다 (시안 363:912).
class AppSettingGroup extends StatelessWidget {
  const AppSettingGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderSoft,
          width: AppDimens.borderWidth,
        ),
        boxShadow: AppShadows.sm,
      ),
      // 구분선이 카드 모서리 밖으로 삐져나오지 않게 자른다.
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) Container(height: 1, color: AppColors.borderSoft),
            child,
          ],
        ],
      ),
    );
  }
}

/// 목록 한 줄 — 높이 60 · 좌우 18 (시안 363:913).
///
/// [value]는 F3(내 정보)처럼 **오른쪽에 값을 보여주는** 보기 전용 줄에 쓴다.
/// [trailing]을 주면 값 대신 그 위젯이 들어간다(스위치 등).
/// 셋 다 없고 [onTap]만 있으면 `›` 화살표가 붙는다.
class AppSettingRow extends StatelessWidget {
  const AppSettingRow({
    super.key,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// 로그아웃처럼 되돌리기 어려운 항목
  final bool danger;

  @override
  Widget build(BuildContext context) {
    // 제목·값은 안쪽 [Text]가 내보낸다. 여기서 또 주면 두 번 읽힌다.
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Text(
                title,
                style: AppTypography.weight(
                  AppTypography.bodyBase,
                  AppTypography.medium,
                ).copyWith(
                  fontSize: 17,
                  height: 1.3,
                  letterSpacing: -0.2,
                  color: danger ? AppColors.destructive : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (trailing != null)
                trailing!
              else if (value != null)
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTypography.bodyBase.copyWith(
                      fontSize: 17,
                      height: 1.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                )
              else if (onTap != null)
                const AppChevron(),
            ],
          ),
        ),
      ),
    );
  }
}

/// 오른쪽 화살표 `›` — 시안은 아이콘이 아니라 글자로 그렸다 (Regular 24).
class AppChevron extends StatelessWidget {
  const AppChevron({super.key});

  @override
  Widget build(BuildContext context) => Text(
    '›',
    style: AppTypography.bodyBase.copyWith(
      fontSize: 24,
      height: 1.0,
      color: AppColors.textTertiary,
    ),
  );
}

/// 위아래로 값이 쌓인 줄 — F3의 "받는 분 / 김영희 · 010 1234 5678".
class AppSettingStackedRow extends StatelessWidget {
  const AppSettingStackedRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textTertiary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.bodyBase.copyWith(
              fontSize: 17,
              height: 27 / 17,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 토글 — 54×32, 손잡이 26 (시안 363:922).
class AppSettingSwitch extends StatelessWidget {
  const AppSettingSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          width: 54,
          height: 32,
          padding: const EdgeInsets.all(3),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? AppColors.accentSoft : AppColors.stone300,
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          ),
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

/// 설정 맨 위 프로필 카드 — 크림 채움 · 높이 84 (시안 363:903).
class AppProfileCard extends StatelessWidget {
  const AppProfileCard({
    super.key,
    required this.initial,
    required this.name,
    required this.phone,
    this.imageBytes,
    this.onTap,
  });

  final String initial;
  final String name;
  final String phone;
  final Uint8List? imageBytes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 84,
          // ⚠️ 배경을 깔지 않는다. Figma 레이어에는 크림 채움이 남아 있지만
          //    **실제 렌더(363:901)에는 카드가 보이지 않는다** — 흰 바탕에
          //    아바타·이름·화살표만 얹혀 있다. 보이는 쪽을 따랐다.
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              AppAvatar(initial: initial, size: 52, imageBytes: imageBytes),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.weight(
                        AppTypography.titleSection,
                        AppTypography.bold,
                      ).copyWith(
                        fontSize: 19,
                        height: 1.3,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textTertiary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) const AppChevron(),
            ],
          ),
        ),
      ),
    );
  }
}
