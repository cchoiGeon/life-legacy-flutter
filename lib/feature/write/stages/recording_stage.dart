import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';
import '../write_header.dart';
import 'question_panel.dart';

/// D2 작성 · 녹음 중 — Figma 350:875.
///
/// D1과 **같은 자리에 같은 것들이 있다.** 바뀌는 건 셋뿐이다:
/// 마이크 글리프(마이크 → 정지), 파형이 뜬다, 라벨이 "듣고 있어요 · 0:23"이
/// 된다. 화면이 통째로 갈아엎히면 지금 무슨 일이 벌어지는지 알기 어렵다.
class RecordingStage extends GetView<WriteController> {
  const RecordingStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WriteHeader(),
        const SizedBox(height: 14), // 시안: 질문 영역이 y148에서 시작
        Obx(
          () => QuestionPanel(
            question: controller.question.value?.text ?? '',
            onReplay: controller.replayQuestion,
          ),
        ),
        const Spacer(),
        // 인식된 글자를 실시간으로 보여준다. 시니어 사용자가 "제대로
        // 알아듣고 있다"를 눈으로 확인할 수 있어야 한다.
        Obx(() {
          final heard = controller.liveTranscript;
          if (heard.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              0,
              AppDimens.gutter,
              AppDimens.space5,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.space4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppDimens.radiusBubble),
              ),
              child: Text(
                heard,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyChat.copyWith(
                  color: AppColors.textStrong,
                ),
              ),
            ),
          );
        }),
        const AppWaveform(),
        const SizedBox(height: 16),
        AppMicButton(recording: true, onTap: controller.stopRecording),
        const SizedBox(height: 22),
        Obx(
          () => Text(
            '듣고 있어요 · ${_mmss(controller.elapsed.value)}',
            style: AppTypography.weight(
              AppTypography.bodyBase,
              AppTypography.bold,
            ).copyWith(color: AppColors.brand, letterSpacing: -0.1),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '눌러서 끝내기',
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
        SizedBox(height: AppInsets.bottom(context, 30)),
      ],
    );
  }

  /// 23 → "0:23"
  static String _mmss(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
