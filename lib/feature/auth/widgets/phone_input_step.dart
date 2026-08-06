import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../auth_controller.dart';

/// 1단계: 전화번호 입력 — Figma A3/A4 대응.
///
/// OS 숫자 키보드로 입력한다. (커스텀 [AppNumberPad] 없음)
class PhoneInputStep extends GetView<AuthController> {
  const PhoneInputStep({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
            title: '전화번호를\n입력해주세요',
            subtitle:
                '기로기는 문자 인증으로 로그인 및 회원가입을 진행합니다. 가입된 번호면 로그인, 없으면 회원가입으로 이어집니다.',
          ),
          const SizedBox(height: 33),
          AppField(
            controller: controller.phoneController,
            hint: '010 - 0000 - 0000',
            height: AppDimens.fieldHeight,
            keyboardType: TextInputType.phone,
            autofocus: true,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\- ]')),
              LengthLimitingTextInputFormatter(17), // "010 - 0000 - 0000"
            ],
            textStyle: AppTypography.weight(
              AppTypography.titlePage,
              AppTypography.medium,
            ).copyWith(fontSize: 24, height: 1.2),
            onChanged: controller.onPhoneChanged,
          ),
          const SizedBox(height: AppDimens.space3),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.tryPrefillPhone(forceDevice: true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '내 번호 불러오기',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space6),
          Obx(() {
            final ready = controller.phoneDigits.value.length == 11;
            final loading = controller.isLoading.value;
            return AppButton(
              label: '다음',
              size: AppButtonSize.lg,
              block: true,
              enabled: ready,
              loading: loading,
              onPressed: controller.submitPhone,
            );
          }),
        ],
      ),
    );
  }
}