import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_env.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';

import 'login_controller.dart';

/// A5·A6 인증번호 입력 — Figma 343:698 · 343:757.
/// 두 프레임은 정상/에러 상태다.
///
/// 6자리를 다 채워도 **자동으로 확인하지 않는다.** 시안에 "확인" 버튼이 따로
/// 있고, 시니어 사용자에게는 마지막 숫자를 누르자마자 화면이 넘어가는 것보다
/// 한 번 더 확인하고 누르는 편이 안전하다.
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
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutter,
                AppDimens.space6,
                AppDimens.gutter,
                AppDimens.space6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(
                    () => AppScreenHeading(
                      title: '인증번호를\n입력해주세요',
                      subtitle: '${controller.phoneCompact} 로 보냈어요',
                    ),
                  ),
                  const SizedBox(height: 37),
                  Obx(
                    () => AppCodeBoxes(
                      value: controller.code.value,
                      hasError: controller.codeError.value != null,
                    ),
                  ),
                  // 에러 문구는 칸과 타이머 **사이**에 끼어든다(시안 343:819).
                  // 아래로 밀려나는 만큼 타이머 줄이 내려간다.
                  Obx(() {
                    final error = controller.codeError.value;
                    if (error == null) return const SizedBox(height: 16);
                    return Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 10),
                      child: Text(
                        error,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.destructive,
                        ),
                      ),
                    );
                  }),
                  const _TimerRow(),
                  const SizedBox(height: 22),
                  Obx(
                    () => AppButton(
                      label: '확인',
                      size: AppButtonSize.lg,
                      block: true,
                      enabled: controller.canVerify,
                      loading: controller.isSubmitting.value,
                      onPressed: controller.verify,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space6),
                  // 목업이라 문자가 오지 않는다. 정답을 화면에 적어 둔다.
                  //
                  // ⚠️ **목업일 때만** 띄운다. 실제 서버에 붙은 채로 이게 뜨면
                  //    화면에 인증번호를 적어 놓고 문자를 기다리게 만든다.
                  if (ApiEnv.useMock)
                    Container(
                      padding: const EdgeInsets.all(AppDimens.space3),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusBase,
                        ),
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
          // 시안 343:718 — 키패드는 화면 바닥까지 닿는다(A3와 같은 이유).
          AppNumberPad(
            onDigit: controller.onCodeDigit,
            onBackspace: controller.onCodeBackspace,
          ),
        ],
      ),
    );
  }
}

/// "2분 47초 남음" ↔ "다시 받기" (시안 343:712).
class _TimerRow extends GetView<LoginController> {
  const _TimerRow();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Text(controller.timerLabel, style: AppTypography.stepLabel),
          const Spacer(),
          Semantics(
            button: true,
            enabled: controller.canResend,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.canResend ? controller.resendCode : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '다시 받기',
                  style:
                      AppTypography.weight(
                        AppTypography.bodyChat,
                        AppTypography.bold,
                      ).copyWith(
                        // 시간이 남아 있는 동안에는 눌리지 않는다 — 색으로 알린다.
                        color: controller.canResend
                            ? AppColors.brand
                            : AppColors.textDisabled,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
