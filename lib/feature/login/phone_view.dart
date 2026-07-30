import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'login_controller.dart';

/// A3·A4 전화번호 입력 — Figma 342:678 · 342:725.
/// 두 프레임은 같은 화면의 입력 전/후 상태다.
///
/// ⚠️ 입력칸은 **읽기 전용**이다. 숫자는 화면 아래 [AppNumberPad]로만 들어온다.
///    `readOnly`를 빼면 칸을 눌렀을 때 OS 키보드가 올라와 키패드와 겹친다.
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
                    subtitle: '인증 문자를 보내드려요',
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
                      label: '인증번호 받기',
                      size: AppButtonSize.lg,
                      block: true,
                      enabled: controller.canRequestCode,
                      loading: controller.isSubmitting.value,
                      onPressed: controller.requestCode,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ⚠️ SafeArea로 감싸지 않는다. 시안 342:686의 키패드는 y580에서
          //    **화면 바닥(844)까지** 꽉 찬다. 아래 인셋을 빼면 판 전체가
          //    25px쯤 떠서 그 위 CTA·입력칸까지 다 어긋난다.
          AppNumberPad(
            onDigit: controller.onPhoneDigit,
            onBackspace: controller.onPhoneBackspace,
          ),
        ],
      ),
    );
  }
}
