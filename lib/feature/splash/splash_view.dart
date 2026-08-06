import 'package:flutter/material.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

/// A1 스플래시 — Figma 341:721.
///
/// ⚠️ 버튼이 없다. 예전 시안은 "시작하기"가 있는 랜딩이었지만 새 시안은
///    브랜드만 보여주고 [SplashController]가 알아서 다음 화면으로 넘긴다.
///    시니어 사용자에게 "아무것도 안 했는데 뭘 눌러야 하는" 첫 화면을 주지
///    않으려는 것이다.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBrandMark(),
            SizedBox(height: 28),
            AppWordmark(fontSize: 28, letterSpacing: 0.4),
            SizedBox(height: 14),
            Text(
              '말로 작성하는 AI 자서전 기록 플랫폼',
              textAlign: TextAlign.center,
              style: AppTypography.brandTagline,
            ),
          ],
        ),
      ),
    );
  }
}
