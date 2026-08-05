import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'auth_controller.dart';
import 'widgets/phone_input_step.dart';
import 'widgets/octomo_instruction_step.dart';
import 'widgets/signup_step.dart';
import 'widgets/signup_success_step.dart';

/// 메인 인증 화면 — 단계를 PageView로 표시한다.
class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppTopBar(showBack: true),
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: AuthStep.values.length,
                itemBuilder: (context, index) {
                  final s = AuthStep.values[index];
                  return _stepWidget(s);
                },
              ),
            ),
            Obx(() {
              final step = controller.currentStep.value;
              if (step == AuthStep.success) return const SizedBox.shrink();
              return _StepIndicator(
                current: AuthStep.values.indexOf(step),
                total: AuthStep.values.length - 1, // success 제외
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _stepWidget(AuthStep step) => switch (step) {
    AuthStep.phone => const PhoneInputStep(),
    AuthStep.octomoSms => const OctomoInstructionStep(),
    AuthStep.signup => const SignupStep(),
    AuthStep.success => const SignupSuccessStep(),
  };
}

/// 하단 단계 표시기.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.space4,
        AppDimens.gutter,
        AppDimens.space4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: AppDimens.space2),
            Container(
              width: i == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i <= current
                    ? AppColors.brand
                    : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
