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
/// 나뉜다. 질문판은 남은 높이를 채우고 긴 글은 판 안에서만 스크롤한다.
/// 하단 보조 동작은 큰 버튼 대신 작은 텍스트 링크로 둔다.
class AskStage extends GetView<WriteController> {
  const AskStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WriteHeader(),
        const SizedBox(height: 14),
        Expanded(
          child: Obx(
            () => KeyedSubtree(
              key: controller.tutorialQuestionKey,
              child: QuestionPanel(
                question: controller.revealedQuestion.value,
                isFollowup: controller.isFollowup.value,
                onReplay: controller.replayQuestion,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppMicButton.bloom),
        KeyedSubtree(
          key: controller.tutorialMicKey,
          child: AppMicButton(
            recording: false,
            onTap: controller.startRecording,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          '눌러서 시작하세요',
          style: AppTypography.weight(
            AppTypography.titleSection,
            AppTypography.bold,
          ).copyWith(color: AppColors.textSecondary, letterSpacing: -0.1),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (!controller.isFollowup.value) {
            return KeyedSubtree(
              key: controller.tutorialTypingKey,
              child: _WriteLink(
                label: '글로 답하기',
                onTap: controller.useKeyboard,
              ),
            );
          }
          return Column(
            children: [
              _WriteLink(
                label: '다시 답하기',
                onTap: controller.redoFirstAnswer,
              ),
              const SizedBox(height: 4),
              _WriteLink(
                label: '기존 답에 추가하기',
                onTap: controller.appendToFirstAnswer,
              ),
              const SizedBox(height: 4),
              KeyedSubtree(
                key: controller.tutorialTypingKey,
                child: _WriteLink(
                  label: '글로 답하기',
                  onTap: controller.useKeyboard,
                ),
              ),
            ],
          );
        }),
        SizedBox(height: AppInsets.bottom(context, 28)),
      ],
    );
  }
}

/// 보조 동작용 작은 텍스트 링크.
class _WriteLink extends StatelessWidget {
  const _WriteLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: AppTypography.bodyBase.copyWith(
          fontSize: 15,
          color: AppColors.brand,
          letterSpacing: -0.1,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.brand.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
