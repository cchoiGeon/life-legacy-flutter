import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/feature/shared/answer_keyboard_body.dart';

import '../write_controller.dart';

/// 글자로 답을 적는 단계.
///
/// 자기소개(08)와 **같은 컴포넌트**([AnswerKeyboardBody])를 쓴다.
/// 예전에는 채팅 말풍선 화면이었지만, 두 곳의 입력 경험을 하나로 합쳤다.
class KeyboardStage extends GetView<WriteController> {
  const KeyboardStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTopBar(
          title: controller.headerTitle,
          onBack: () => controller.stage.value = WriteStage.ask,
          background: AppColors.background,
        ),
        Expanded(
          child: Obx(
            () => AnswerKeyboardBody(
              question: controller.question.value?.text ?? '',
              controller: controller.answerController,
              hint: '답변을 입력하세요.',
              canSubmit: controller.canSubmitTyped && !controller.isBusy.value,
              onSubmit: controller.submitTyped,
              ctaLabel: '저장하고 다음 질문',
              isRecording: false,
              onMic: controller.micFromKeyboard,
            ),
          ),
        ),
      ],
    );
  }
}
