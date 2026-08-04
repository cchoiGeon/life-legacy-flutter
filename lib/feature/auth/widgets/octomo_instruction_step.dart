import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../auth_controller.dart';

/// 2단계: OCTOMO 문자 전송 안내.
///
/// 사용자에게 수신번호와 보낼 문자를 보여주고, 복사 버튼과 메시지 앱 열기
/// 안내를 제공한다. "문자를 보냈어요" 버튼을 누르면 폴링 단계로 넘어간다.
class OctomoInstructionStep extends GetView<AuthController> {
  const OctomoInstructionStep({super.key});

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
            title: 'SMS 인증을\n진행해 주세요',
            subtitle: '문자 앱에서 아래 번호로 인증번호를 보내주세요',
          ),
          const SizedBox(height: 32),

          // 수신번호
          _InfoCard(
            label: '수신번호',
            value: controller.receiverNumber.value,
            onCopy: () {
              Clipboard.setData(
                ClipboardData(text: controller.receiverNumber.value),
              );
              controller.copyReceiverNumber();
            },
          ),
          const SizedBox(height: AppDimens.space4),

          // 보낼 문자
          _InfoCard(
            label: '보낼 문자',
            value: controller.verifyText.value,
            onCopy: () {
              Clipboard.setData(
                ClipboardData(text: controller.verifyText.value),
              );
              controller.copyVerifyText();
            },
          ),
          const SizedBox(height: AppDimens.space6),

          // 안내 문구
          Container(
            padding: const EdgeInsets.all(AppDimens.space4),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(AppDimens.radiusBase),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stepNumber('1', '수신번호를 누르거나 복사하세요'),
                const SizedBox(height: AppDimens.space3),
                _stepNumber('2', '문자 앱을 열어 수신번호를 붙여넣으세요'),
                const SizedBox(height: AppDimens.space3),
                _stepNumber('3', '보낼 문자를 입력하고 전송하세요'),
                const SizedBox(height: AppDimens.space3),
                _stepNumber('4', '전송 후 아래 "문자를 보냈어요"를 누르세요'),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.space6),

          Obx(
            () => AppButton(
              label: '문자를 보냈어요',
              size: AppButtonSize.lg,
              block: true,
              loading: controller.isChecking.value,
              onPressed: controller.startVerification,
            ),
          ),
          const SizedBox(height: AppDimens.space3),

          // 재확인
          Center(
            child: Text(
              '문자 요금은 발신자 부담입니다',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepNumber(String number, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            number,
            style: AppTypography.label.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppDimens.space2),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 수신번호나 문자를 보여주는 카드.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppDimens.radiusBase),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppDimens.space1),
                Text(
                  value,
                  style: AppTypography.titlePage.copyWith(
                    color: AppColors.textPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                border: Border.all(
                  color: AppColors.borderSoft,
                  width: AppDimens.borderWidth,
                ),
              ),
              child: Text(
                '복사',
                style: AppTypography.weight(
                  AppTypography.caption,
                  AppTypography.medium,
                ).copyWith(color: AppColors.brand),
              ),
            ),
          ),
        ],
      ),
    );
  }
}