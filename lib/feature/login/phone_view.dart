import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'login_controller.dart';

/// 03·04 전화번호 입력 — Figma 142:24 · 142:49.
/// 두 프레임은 같은 화면의 입력 전/후 상태다.
class PhoneView extends GetView<LoginController> {
  const PhoneView({super.key});

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
                  Text('전화번호로\n간단히 시작해요', style: AppTypography.titlePage),
                  const SizedBox(height: AppDimens.space3),
                  Text(
                    '비밀번호는 필요 없어요.\n문자로 숫자만 입력하시면 돼요.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space8),
                  AppField(
                    controller: controller.phoneController,
                    hint: '010 - 0000 - 0000',
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      _PhoneFormatter(),
                    ],
                    textStyle: AppTypography.weight(
                      AppTypography.headingXl,
                      AppTypography.medium,
                    ),
                    onChanged: controller.onPhoneChanged,
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
            child: Column(
              children: [
                Obx(
                  // phone을 읽어야 입력할 때마다 버튼 활성 상태가 갱신된다.
                  () => AppButton(
                    label: '인증번호 받기',
                    size: AppButtonSize.lg,
                    block: true,
                    enabled:
                        controller.phone.value.isNotEmpty &&
                        controller.canRequestCode,
                    loading: controller.isSubmitting.value,
                    onPressed: controller.requestCode,
                  ),
                ),
                const SizedBox(height: AppDimens.space3),
                Text(
                  '자녀 대신 가입했다면 도움받을 수 있어요',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 입력하는 동안 "010 1234 5678"로 띄어 준다.
///
/// 하이픈이 아니라 공백을 쓰는 건 시안(04번)이 그렇게 보여주기 때문이다.
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 7) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      // 커서는 항상 끝으로 보낸다. 중간 수정은 드물고, 공백이 끼면서
      // 오프셋을 정확히 계산하기가 번거롭다.
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
