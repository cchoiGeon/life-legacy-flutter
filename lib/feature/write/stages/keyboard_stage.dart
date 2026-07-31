import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';
import '../write_header.dart';
import 'question_panel.dart';

/// D3 작성 · 글자 입력 — Figma 351:874.
///
/// 질문판이 D1·D2보다 낮고 왼쪽 정렬이다 — OS 키보드가 화면 절반을 먹으므로
/// 질문이 자리를 양보한다. 대신 [QuestionPanel]을 그대로 써서 "크림 띠 =
/// 읽는 영역"이라는 성격은 유지한다.
///
/// ⚠️ 예전에는 자기소개와 입력 컴포넌트를 공유했다. 시안이 두 화면을
///    갈라놓으면서(자기소개는 한 줄 입력칸, 작성은 여러 줄 판) 공유를 풀었고
///    `AnswerKeyboardBody`·`AppKeyboardButton`은 쓰는 곳이 없어져 지웠다.
class KeyboardStage extends GetView<WriteController> {
  const KeyboardStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WriteHeader(),
        const SizedBox(height: 14), // 시안: 질문 영역이 y148에서 시작
        Obx(
          () => QuestionPanel(
            question: controller.displayQuestion,
            badge: controller.followupBadge,
            tall: false,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              26,
              AppDimens.gutter,
              AppDimens.space6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Textarea(),
                const SizedBox(height: AppDimens.space6),
                Obx(
                  () => AppButton(
                    label: '저장하기',
                    size: AppButtonSize.lg,
                    block: true,
                    enabled: controller.canSubmitTyped,
                    onPressed: controller.submitTyped,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 시안 351:883 — 높이 176 · 반경 16 · **테두리 2 브랜드**.
///
/// 테두리가 늘 브랜드색인 건 이 화면에서 누를 곳이 여기 하나뿐이기 때문이다.
/// 회색이면 어디에 적으라는 건지 한 번 더 찾게 된다.
class _Textarea extends GetView<WriteController> {
  const _Textarea();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: AppColors.brand,
          width: AppDimens.borderWidthSelected,
        ),
      ),
      child: TextField(
        controller: controller.answerController,
        autofocus: true,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        cursorColor: AppColors.brand,
        style: AppTypography.bodyBase.copyWith(
          fontSize: 17,
          height: 29 / 17,
          letterSpacing: -0.1,
        ),
        decoration: InputDecoration.collapsed(
          hintText: '들려주고 싶은 이야기를 적어 주세요',
          hintStyle: AppTypography.bodyBase.copyWith(
            fontSize: 17,
            height: 29 / 17,
            color: AppColors.stone400,
          ),
        ),
      ),
    );
  }
}
