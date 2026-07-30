import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 화면 안에 남는 경고 안내 — Figma 354:1051 (`저장 실패 안내`).
///
/// 토스트와 쓰임이 다르다. 토스트는 몇 초 뒤 사라지지만 이 박스는 **사용자가
/// 뭔가를 할 때까지 남아 있어야 하는** 상태를 알린다(저장 실패 → 다시 저장).
///
/// ⚠️ 배경은 흰색이다. 빨간 배경을 깔면 아래 CTA까지 위험해 보인다 —
///    시안은 테두리와 제목 색으로만 경고를 준다.
class AppNoticeBox extends StatelessWidget {
  const AppNoticeBox({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: AppColors.destructive,
          width: AppDimens.borderWidthStrong,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.ctaLabelSecondary.copyWith(
              color: AppColors.destructive,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppDimens.space2),
          Text(
            message,
            style: AppTypography.bodyChat.copyWith(
              color: AppColors.textSecondary,
              height: 26 / 15,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
