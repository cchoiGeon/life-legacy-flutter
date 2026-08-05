import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/service/services.dart';

import '../auth_controller.dart';

/// SMS 인증 — 로컬 문자 앱으로 보내고, 복귀·수동 확인으로 수신을 폴링한다.
///
/// 제한 시간 5분. 웹 등 문자 앱을 못 여는 환경에서는 번호·본문을 보여 수동 전송을 돕는다.
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
            subtitle: '문자 앱이 열리면 전송만 눌러 주세요. 돌아온 뒤 자동으로 확인합니다.',
          ),
          const SizedBox(height: 24),

          Obx(() {
            final expired = controller.isExpired.value;
            final label = controller.remainingLabel;
            // remainingSeconds를 Obx가 추적하도록 읽는다
            controller.remainingSeconds.value;
            return Text(
              expired ? '인증 시간이 지났어요' : '남은 시간  $label',
              textAlign: TextAlign.center,
              style: AppTypography.weight(
                AppTypography.titlePage,
                AppTypography.medium,
              ).copyWith(
                color: expired ? AppColors.destructive : AppColors.brand,
              ),
            );
          }),
          const SizedBox(height: AppDimens.space6),

          Obx(
            () => _InfoCard(
              label: '수신번호',
              value: controller.receiverNumber.value,
              onCopy: () {
                Clipboard.setData(
                  ClipboardData(text: controller.receiverNumber.value),
                );
                Get.find<ToastService>().show('수신번호를 복사했어요');
              },
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          Obx(
            () => _InfoCard(
              label: '보낼 문자',
              value: controller.verifyText.value,
              onCopy: () {
                Clipboard.setData(
                  ClipboardData(text: controller.verifyText.value),
                );
                Get.find<ToastService>().show('인증번호를 복사했어요');
              },
            ),
          ),
          const SizedBox(height: AppDimens.space4),

          Obx(() {
            if (controller.isExpired.value || !controller.isChecking.value) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.space4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppDimens.space2),
                  Text(
                    '문자 수신을 확인하고 있어요',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),

          Obx(() {
            if (controller.isExpired.value) {
              return AppButton(
                label: '다시 문자 보내기',
                size: AppButtonSize.lg,
                block: true,
                loading: controller.isLoading.value,
                onPressed: controller.retryChallenge,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: '문자 앱 열기',
                  size: AppButtonSize.lg,
                  block: true,
                  onPressed: controller.openSmsApp,
                ),
                const SizedBox(height: AppDimens.space3),
                AppButton(
                  label: '문자를 보냈어요',
                  variant: AppButtonVariant.soft,
                  size: AppButtonSize.lg,
                  block: true,
                  onPressed: controller.confirmSmsSent,
                ),
              ],
            );
          }),
          const SizedBox(height: AppDimens.space3),
          Center(
            child: Text(
              '문자 요금은 발신자 부담입니다 · 제한 시간 5분',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
                  value.isEmpty ? '—' : value,
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
