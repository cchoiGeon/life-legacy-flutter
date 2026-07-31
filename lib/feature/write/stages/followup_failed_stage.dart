import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';
import '../write_header.dart';

/// D8 꼬리질문을 만들지 못했다.
///
/// **저장 실패(D5)와 결과가 다르다.** D5는 글이 살아 있어 버튼만 다시 누르면
/// 되지만, 여기서는 서버가 1차 답변을 버렸으므로 질문부터 다시 답해야 한다.
/// 그래서 화면을 따로 뒀다 — 같은 안내로 묶으면 "다시 저장"인 줄 알고
/// 기다리게 된다.
///
/// 문구에서 지키는 것 두 가지:
///   · 사용자 탓으로 들리지 않게 한다. 말은 잘 하셨고 우리 쪽이 못 받았다.
///   · 다시 말해야 한다는 걸 **감추지 않는다.** 알고 시작해야 덜 당황한다.
class FollowupFailedStage extends GetView<WriteController> {
  const FollowupFailedStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WriteHeader(showProgressLabel: false),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  size: 56,
                  color: AppColors.warm,
                ),
                const SizedBox(height: AppDimens.space6),
                const Text(
                  '잠시 말을 잇지 못했어요',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleSerifSm,
                ),
                const SizedBox(height: AppDimens.space3),
                Text(
                  '이어서 여쭤볼 말을 만들지 못했어요.\n번거로우시겠지만 이 질문을 다시 들려주시겠어요?',
                  textAlign: TextAlign.center,
                  style: AppTypography.subtitle,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
          child: AppButton(
            label: '다시 답해볼게요',
            onPressed: controller.restartQuestion,
          ),
        ),
        const SizedBox(height: AppDimens.space4),
        AppButton(
          label: '이 질문 건너뛰기',
          variant: AppButtonVariant.neutral,
          size: AppButtonSize.assist,
          onPressed: controller.skip,
        ),
        SizedBox(height: AppInsets.bottom(context, 40)),
      ],
    );
  }
}
