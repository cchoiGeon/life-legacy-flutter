import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';
import '../write_header.dart';
import 'question_panel.dart';

/// D1 작성 · 음성 모드 (기본) — Figma 341:646.
///
/// 화면이 **읽는 영역**(크림 질문판)과 **누르는 영역**(마이크)으로 위아래
/// 나뉜다. 시안의 핵심 원칙이라 두 덩어리 사이를 비워 둔다 — 질문을 읽는
/// 동안 손이 버튼에 닿지 않게 한 것이다.
///
/// ⚠️ 마이크부터 아래는 **자리가 고정이다.** D2(녹음 중)와 높이가 같아야
///    녹음을 시작해도 버튼이 손 밑에서 움직이지 않는다 — 아래 여백 62도
///    두 화면이 같은 값을 쓴다.
class AskStage extends GetView<WriteController> {
  const AskStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WriteHeader(),
        const SizedBox(height: 14), // 시안: 질문 영역이 y148에서 시작
        // 질문판은 **남은 자리 안에서만** 큰다. 글이 그보다 길면 판 안에서
        // 스크롤한다 — 아래 마이크 블록을 밀어내지 않는다.
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: Obx(
              () => QuestionPanel(
                question: controller.displayQuestion,
                isFollowup: controller.isFollowup.value,
                onReplay: controller.replayQuestion,
              ),
            ),
          ),
        ),
        // 파문은 자리를 차지하지 않으므로 닿는 만큼 비워 준다.
        const SizedBox(height: AppMicButton.bloom),
        AppMicButton(recording: false, onTap: controller.startRecording),
        const SizedBox(height: 22),
        Text(
          '눌러서 시작하세요',
          style: AppTypography.weight(
            AppTypography.titleSection,
            AppTypography.bold,
          ).copyWith(color: AppColors.textSecondary, letterSpacing: -0.1),
        ),
        const SizedBox(height: 28),
        AppButton(
          label: '글로 답하기',
          variant: AppButtonVariant.neutral,
          size: AppButtonSize.assist,
          onPressed: controller.useKeyboard,
        ),
        SizedBox(height: AppInsets.bottom(context, 62)),
      ],
    );
  }
}
