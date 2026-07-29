import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';

import 'login_controller.dart';

/// 05·06 인증번호 입력 — Figma 143:46 · 143:79.
/// 두 프레임은 정상/에러 상태다.
class CodeView extends GetView<LoginController> {
  const CodeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimens.space5),
                  Text('인증번호를\n입력해 주세요', style: AppTypography.titlePage),
                  const SizedBox(height: AppDimens.space3),
                  Obx(
                    () => Text(
                      '${controller.phone.value}로 보낸\n6자리 숫자를 입력해 주세요',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Obx(
                    () => AppCodeInput(
                      controller: controller.codeController,
                      hasError: controller.codeError.value != null,
                      onCompleted: (_) => controller.verify(),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space3),
                  Obx(() {
                    final error = controller.codeError.value;
                    if (error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimens.space2),
                      child: Text(
                        error,
                        style: AppTypography.label.copyWith(
                          color: AppColors.destructive,
                        ),
                      ),
                    );
                  }),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: controller.resendCode,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '인증번호 다시 받기',
                        style: AppTypography.label.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space6),
                  // 목업이라 문자가 오지 않는다. 정답을 화면에 적어 둔다.
                  // 실제 API가 붙으면 이 블록은 지운다.
                  Container(
                    padding: const EdgeInsets.all(AppDimens.space3),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(AppDimens.radiusBase),
                    ),
                    child: Text(
                      '목업 안내 · 인증번호는 ${MockApiClient.demoCode} 입니다',
                      style: AppTypography.label.copyWith(
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              0,
              AppDimens.gutter,
              AppDimens.space5,
            ),
            child: Obx(
              () => AppButton(
                label: '확인',
                size: AppButtonSize.lg,
                block: true,
                enabled: controller.canVerify,
                loading: controller.isSubmitting.value,
                onPressed: controller.verify,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
