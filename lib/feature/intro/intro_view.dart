import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/shared/answer_keyboard_body.dart';

import 'intro_controller.dart';

/// 07·08 자기소개 — Figma 158:338 · 159:348.
class IntroView extends GetView<IntroController> {
  const IntroView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // 키보드가 올라올 때 본문이 줄어들도록 둔다(입력칸이 가려지면 안 된다).
      resizeToAvoidBottomInset: true,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppSpinner());
        }
        final question = controller.current;
        if (question == null) {
          return const Center(child: Text('질문을 불러오지 못했어요'));
        }
        return Column(
          children: [
            AppTopBar(
              title: '자기소개',
              onBack: controller.back,
              trailing: Text(
                '${controller.step} / ${controller.total}',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
              child: AppStepBar(
                total: controller.total,
                current: controller.step,
              ),
            ),
            Expanded(
              child: controller.mode.value == ComposeMode.voice
                  ? _VoiceBody(question: question)
                  : _KeyboardBody(question: question),
            ),
          ],
        );
      }),
    );
  }
}

/// 07 — 큰 마이크 버튼이 중심.
class _VoiceBody extends GetView<IntroController> {
  const _VoiceBody({required this.question});

  final IntroQuestion question;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            '몇 가지만 여쭤보고 목차를 만들어 드릴게요',
            textAlign: TextAlign.center,
            style: AppTypography.bodySm.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppDimens.space3),
          Text(
            question.text,
            textAlign: TextAlign.center,
            style: AppTypography.titlePage,
          ),
          const Spacer(),
          Obx(
            () => AppMicButton(
              recording: controller.isRecording.value,
              onTap: controller.toggleRecording,
            ),
          ),
          Obx(
            () => Text(
              controller.isRecording.value ? '듣고 있어요…' : '누르고 말씀하세요',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space5),
          // 작성 탭(13)과 **같은 버튼 컴포넌트**다 (Figma 158:370).
          AppKeyboardButton(onPressed: controller.useKeyboard),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

/// 08 — 입력칸 + 다음 버튼.
///
/// 작성 탭의 글자 입력과 **같은 컴포넌트**([AnswerKeyboardBody])를 쓴다.
class _KeyboardBody extends GetView<IntroController> {
  const _KeyboardBody({required this.question});

  final IntroQuestion question;

  @override
  Widget build(BuildContext context) => Obx(
    () => AnswerKeyboardBody(
      question: question.text,
      controller: controller.answerController,
      hint: question.hint,
      canSubmit: controller.canGoNext,
      onSubmit: controller.next,
      ctaLabel: controller.step == controller.total ? '목차 만들기' : '다음',
      isRecording: controller.isRecording.value,
      onMic: controller.toggleRecording,
    ),
  );
}
