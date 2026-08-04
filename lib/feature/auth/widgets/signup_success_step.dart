import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../auth_controller.dart';

/// 5단계: 회원가입 성공.
///
/// "회원가입 성공!" 메시지와 "자서전 작성하러 가기" CTA를 표시한다.
class SignupSuccessStep extends GetView<AuthController> {
  const SignupSuccessStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 성공 아이콘
            Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 44,
                color: AppColors.onPrimary,
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              '회원가입 성공!',
              textAlign: TextAlign.center,
              style: AppTypography.titleScreen,
            ),
            const SizedBox(height: AppDimens.space3),

            Text(
              '지금부터 선생님만의\n자서전을 만들어 볼게요',
              textAlign: TextAlign.center,
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 48),

            AppButton(
              label: '자서전 작성하러 가기',
              size: AppButtonSize.lg,
              block: true,
              onPressed: controller.goToIntro,
            ),
          ],
        ),
      ),
    );
  }
}