import 'package:flutter/material.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 크림 바탕의 질문판 — Figma 341:654 (D1·D2) · 351:881 (D3).
///
/// 시안의 "읽는 영역". 화면 가장자리까지 닿는 크림 띠라 아래 흰 바탕과
/// 확실히 갈린다.
///
/// 음성 화면([tall])은 질문을 가운데 크게(명조 28) 놓고 "다시 들려주기"를
/// 붙이지만, 글자 입력 화면은 입력칸에 자리를 내주려고 작게(명조 20) 왼쪽
/// 정렬로 줄인다.
class QuestionPanel extends StatelessWidget {
  const QuestionPanel({
    super.key,
    required this.question,
    this.onReplay,
    this.tall = true,
  });

  final String question;

  /// null이면 "다시 들려주기"가 빠진다.
  final VoidCallback? onReplay;

  final bool tall;

  @override
  Widget build(BuildContext context) {
    if (!tall) {
      return Container(
        width: double.infinity,
        color: AppColors.cream,
        padding: const EdgeInsets.fromLTRB(26, 20, 26, 22),
        child: Text(
          question,
          style: AppTypography.titleScreen.copyWith(
            fontSize: 20,
            height: 31 / 20,
            letterSpacing: -0.3,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 244,
      color: AppColors.cream,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            question,
            textAlign: TextAlign.center,
            style: AppTypography.titleScreen.copyWith(letterSpacing: -0.5),
          ),
          if (onReplay != null) ...[
            const SizedBox(height: 18),
            Semantics(
              button: true,
              label: '다시 들려주기',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onReplay,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '다시 들려주기',
                    style: AppTypography.weight(
                      AppTypography.bodyBase,
                      AppTypography.bold,
                    ).copyWith(
                      color: AppColors.brand,
                      letterSpacing: -0.1,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
