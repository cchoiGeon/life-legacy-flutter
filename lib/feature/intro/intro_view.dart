import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';

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
          AppButton(
            label: '키보드로 입력할게요',
            variant: AppButtonVariant.neutral,
            size: AppButtonSize.sm,
            onPressed: controller.useKeyboard,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

/// 08 — 입력칸 + 다음 버튼.
class _KeyboardBody extends GetView<IntroController> {
  const _KeyboardBody({required this.question});

  final IntroQuestion question;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              AppDimens.space6,
              AppDimens.gutter,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.text.replaceAll('\n', ' '),
                  style: AppTypography.weight(
                    AppTypography.headingXl,
                    AppTypography.bold,
                  ),
                ),
                const SizedBox(height: AppDimens.space4),
                AppField(
                  controller: controller.answerController,
                  hint: question.hint,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 4,
                  suffix: Obx(
                    () => AppCircleButton(
                      size: 32,
                      semanticLabel: '음성으로 바꾸기',
                      onTap: controller.toggleRecording,
                      child: Icon(
                        Icons.mic_none_rounded,
                        size: 20,
                        color: controller.isRecording.value
                            ? AppColors.accentSoft
                            : AppColors.brand,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.space2),
                Text(
                  '음성으로 바꾸려면 마이크를 누르세요',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.gutter,
            AppDimens.space3,
            AppDimens.gutter,
            AppDimens.space5,
          ),
          child: Obx(
            () => AppButton(
              label: controller.step == controller.total ? '목차 만들기' : '다음',
              size: AppButtonSize.lg,
              block: true,
              enabled: controller.canGoNext,
              onPressed: controller.next,
            ),
          ),
        ),
      ],
    );
  }
}
