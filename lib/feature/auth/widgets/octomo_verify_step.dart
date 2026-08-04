import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../auth_controller.dart';

/// 3단계: OCTOMO 문자 확인 폴링.
///
/// 서버가 OCTOMO에 문자 수신 여부를 확인하는 동안 로딩 화면을 보여준다.
/// 만료 시 다시 문자 보내기로 안내한다.
class OctomoVerifyStep extends GetView<AuthController> {
  const OctomoVerifyStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
        child: Obx(() {
          if (controller.isExpired.value) {
            return _ExpiredView(onRetry: controller.retryChallenge);
          }
          return _PollingView(
            onManualVerify: controller.manualVerify,
          );
        }),
      ),
    );
  }
}

/// 폴링 중 화면.
class _PollingView extends StatelessWidget {
  const _PollingView({required this.onManualVerify});

  final VoidCallback onManualVerify;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        const AppWaitingRing(size: 64),
        const SizedBox(height: 32),
        const Text(
          '문자 수신을\n확인하고 있어요',
          textAlign: TextAlign.center,
          style: AppTypography.titleScreen,
        ),
        const SizedBox(height: AppDimens.space3),
        Text(
          '문자를 보내신 후 잠시만 기다려 주세요\n'
          '확인에 시간이 걸릴 수 있습니다',
          textAlign: TextAlign.center,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 48),
        AppButton(
          label: '다시 확인하기',
          variant: AppButtonVariant.soft,
          size: AppButtonSize.assist,
          onPressed: onManualVerify,
        ),
      ],
    );
  }
}

/// 만료 화면.
class _ExpiredView extends StatelessWidget {
  const _ExpiredView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 60),
        const Icon(
          Icons.access_time_rounded,
          size: 64,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 32),
        const Text(
          '인증 시간이\n지났어요',
          textAlign: TextAlign.center,
          style: AppTypography.titleScreen,
        ),
        const SizedBox(height: AppDimens.space3),
        Text(
          '문자를 보내고 다시 확인해 주세요',
          textAlign: TextAlign.center,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 48),
        AppButton(
          label: '다시 문자 보내기',
          size: AppButtonSize.lg,
          block: true,
          onPressed: onRetry,
        ),
      ],
    );
  }
}