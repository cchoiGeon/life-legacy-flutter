import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'intro_controller.dart';

/// B1~B5 자기소개 — Figma 345:718 · 346:728 · 346:753 · 346:778 · 346:803.
///
/// 다섯 프레임이 **같은 화면의 다른 문항**이다. 위(뒤로 · N/5 · 진행바 ·
/// 제목 · 부제)와 아래("다음")는 고정이고 가운데만 입력칸 ↔ 선택지로 바뀐다.
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
              onBack: controller.back,
              trailing: Obx(
                () => Text(
                  controller.stepLabel,
                  style: AppTypography.stepLabel,
                ),
              ),
            ),
            // 시안 345:721 — 상단 바 바로 아래, 화면 가장자리까지 닿는 4px 바.
            Obx(
              () => AppProgressBar(
                value: controller.progress,
                height: 4,
                rounded: false,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                // 시안 345:723 — 진행바(100~104) 아래 20에서 제목이 시작한다.
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  20,
                  AppDimens.gutter,
                  AppDimens.space6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppScreenHeading(
                      title: question.text,
                      subtitle: question.subtitle,
                    ),
                    const SizedBox(height: 41),
                    switch (question.type) {
                      IntroAnswerType.choice => _Choices(question: question),
                      IntroAnswerType.text => _Field(question: question),
                    },
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.gutter,
                0,
                AppDimens.gutter,
                AppInsets.bottom(context, 22),
              ),
              child: Obx(
                () => AppButton(
                  label: controller.ctaLabel,
                  size: AppButtonSize.lg,
                  block: true,
                  enabled: controller.canGoNext,
                  onPressed: controller.next,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// B2~B5 — 선택지를 세로로 쌓는다.
///
/// 높이는 개수가 정한다: 둘이면 96, 넷이면 74. 시안이 어느 쪽이든 한 화면에
/// 들어오게 잡아 둔 값이다.
class _Choices extends GetView<IntroController> {
  const _Choices({required this.question});

  final IntroQuestion question;

  @override
  Widget build(BuildContext context) {
    final height = AppChoiceTile.heightFor(question.choices.length);

    return Obx(
      () => Column(
        children: [
          for (final (i, choice) in question.choices.indexed) ...[
            if (i > 0) const SizedBox(height: AppChoiceTile.gap),
            AppChoiceTile(
              label: choice,
              height: height,
              selected: controller.selected.value == choice,
              onTap: () => controller.choose(choice),
            ),
          ],
        ],
      ),
    );
  }
}

/// B1 — 성함 입력칸. OS 한글 키보드를 그대로 쓴다.
class _Field extends GetView<IntroController> {
  const _Field({required this.question});

  final IntroQuestion question;

  @override
  Widget build(BuildContext context) => AppField(
    controller: controller.answerController,
    hint: question.hint,
    height: AppDimens.fieldHeight,
    autofocus: true,
    textStyle: AppTypography.weight(
      AppTypography.headingXl,
      AppTypography.medium,
    ).copyWith(height: 1.3),
  );
}
