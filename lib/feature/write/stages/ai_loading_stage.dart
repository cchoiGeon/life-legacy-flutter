import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';

/// D6 꼬리질문 준비 중 · D7 이야기 정리 중.
///
/// 서버가 AI를 부르는 동안 뜬다. 꼬리질문은 30초, 윤문은 60초까지 걸린다 —
/// 시니어 사용자에게 1분 무반응은 "앱이 멈췄다"로 읽히므로, 지금 무슨 일이
/// 일어나는지를 **문장으로** 알린다. 스피너만 도는 화면은 이유를 설명하지
/// 못한다.
///
/// ⚠️ 되돌아가는 길을 두지 않았다. 서버가 이미 이야기를 받아 처리 중인데
///    화면만 빠져나오면 답이 어디로 갔는지 알 수 없는 상태가 된다.
///    목차 준비 중(B6)과 같은 규칙이다.
class AiLoadingStage extends GetView<WriteController> {
  const AiLoadingStage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppSpinner(),
            const SizedBox(height: AppDimens.space8),
            Obx(
              () => Text(
                controller.loadingTitle,
                textAlign: TextAlign.center,
                style: AppTypography.titleSerifSm,
              ),
            ),
            const SizedBox(height: AppDimens.space3),
            Obx(
              () => Text(
                controller.loadingSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.subtitle,
              ),
            ),
            const SizedBox(height: AppDimens.space10),
            // 말한 내용이 사라지지 않았다는 걸 대기 중에 알려 둔다.
            // 기다리는 동안 가장 큰 걱정이 그것이다.
            Text(
              '말씀해 주신 이야기는 잘 담아 두었어요',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
