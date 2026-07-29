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
            AppTopBar(title: '자기소개', onBack: controller.back),
            // 작성 탭(13)과 **완전히 같은 진행률 블록** —
            // 바가 위, "질문 N / M"이 아래. 여백·높이·색 모두 동일하다.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
              child: Column(
                // 바깥 Column이 center 정렬이라 stretch가 없으면
                // 바가 라벨 폭으로 줄어든다 (작성 탭과 같은 이유).
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppProgressBar(
                    value: controller.total == 0
                        ? 0
                        : controller.step / controller.total,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      controller.progressLabel,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.stone500,
                        letterSpacing: -0.13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (question.type) {
                IntroAnswerType.choice => _ChoiceBody(question: question),
                // 자기소개는 **키보드 전용**이다 — 성함처럼 짧은 답은
                // 받아쓰기보다 직접 치는 편이 빠르다.
                IntroAnswerType.text => _KeyboardBody(question: question),
              },
            ),
          ],
        );
      }),
    );
  }
}

/// 고르기 문항 — 질문 + 선택지 두 개.
///
/// 누르는 즉시 다음 문항으로 넘어간다. 시니어 사용자가 "고르고 → 다음 누르고"
/// 두 번 조작하지 않게 한 것이다.
///
/// 질문은 위, 버튼은 아래에 둔다. 가운데로 모으면 두 덩어리가 붙어 버린다.
class _ChoiceBody extends GetView<IntroController> {
  const _ChoiceBody({required this.question});

  final IntroQuestion question;

  /// 이 화면의 **유일한 조작**이라 시안 CTA(56)보다 크게 잡는다.
  static const _buttonHeight = 96.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
      child: Column(
        // stretch가 없으면 Column이 라벨 폭으로 줄어들어 버튼 Row도 같이 좁아진다.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimens.space16),
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
          const Spacer(flex: 3),
          Row(
            children: [
              for (final (i, choice) in question.choices.indexed) ...[
                if (i > 0) const SizedBox(width: AppDimens.space3),
                Expanded(
                  child: AppButton(
                    label: choice,
                    // ⚠️ 두 버튼은 **항상 같은 모양**이다. 고른 쪽을 채워서
                    //    표시하면 한쪽만 색이 진해져 기본값처럼 보인다.
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.lg,
                    block: true,
                    minHeight: _buttonHeight,
                    labelStyle: AppTypography.headingXl,
                    onPressed: () => controller.choose(choice),
                  ),
                ),
              ],
            ],
          ),
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
      // onMic을 주지 않아 마이크 버튼과 "음성으로 바꾸려면…" 안내가 빠진다.
    ),
  );
}
