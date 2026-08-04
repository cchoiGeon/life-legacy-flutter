import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../auth_controller.dart';

/// 1단계: 전화번호 입력 — Figma A3/A4 대응.
///
/// 앱 자체 숫자 키패드로만 입력받는다. OS 키보드는 뜨지 않는다.
class PhoneInputStep extends GetView<AuthController> {
  const PhoneInputStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              AppDimens.space6,
              AppDimens.gutter,
              AppDimens.space6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppScreenHeading(
                  title: '전화번호를\n알려주세요',
                  subtitle: 'OCTOMO 인증을 위해 전화번호가 필요해요',
                ),
                const SizedBox(height: 33),
                AppField(
                  controller: controller.phoneController,
                  hint: '010 - 0000 - 0000',
                  height: AppDimens.fieldHeight,
                  readOnly: true,
                  showCursor: false,
                  textStyle: AppTypography.weight(
                    AppTypography.titlePage,
                    AppTypography.medium,
                  ).copyWith(fontSize: 24, height: 1.2),
                ),
                const SizedBox(height: AppDimens.space6),
                Obx(
                  () => AppButton(
                    label: '다음',
                    size: AppButtonSize.lg,
                    block: true,
                    enabled: controller.canProceedPhone,
                    loading: controller.isLoading.value,
                    onPressed: controller.submitPhone,
                  ),
                ),
              ],
            ),
          ),
        ),
        AppNumberPad(
          onDigit: controller.onPhoneDigit,
          onBackspace: controller.onPhoneBackspace,
        ),
      ],
    );
  }
}