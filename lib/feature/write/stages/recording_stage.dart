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
/// D1과 **같은 자리에 같은 것들이 있다.** 바뀌는 건 마이크 글리프(마이크 →
/// 정지)와 버튼 둘레를 도는 원형 파형, 그리고 아래 라벨뿐이다. 화면이 통째로
/// 갈아엎히면 지금 무슨 일이 벌어지는지 알기 어렵다.
///
/// ⚠️ 마이크부터 아래는 **자리가 고정이다.** 받아쓴 글이 길어져도, 질문이
///    길어져도 버튼이 움직이지 않는다 — 방금 누른 버튼이 손 밑에서 밀려나면
///    다시 누르려다 엉뚱한 곳을 누른다.
class RecordingStage extends GetView<WriteController> {
  const RecordingStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WriteHeader(),
        const SizedBox(height: 14), // 시안: 질문 영역이 y148에서 시작
        Expanded(
          child: Stack(
            children: [
              // 질문판은 남은 높이를 채운다. 말하는 동안에도 질문을 보며
              // 답해야 하므로, 받아쓴 글에 자리를 내주고 줄어들면 안 된다.
              Positioned.fill(
                child: Obx(
                  () => QuestionPanel(
                    question: controller.revealedQuestion.value,
                    isFollowup: controller.isFollowup.value,
                    onReplay: controller.replayQuestion,
                  ),
                ),
              ),
              // 인식된 글자를 실시간으로 보여준다. 시니어 사용자가 "제대로
              // 알아듣고 있다"를 눈으로 확인할 수 있어야 한다.
              //
              // ⚠️ [Stack]으로 **겹쳐** 띄운다. 세로로 자리를 잡으면 글이 뜨는
              //    순간 질문판이 줄거나 마이크가 밀려 내려간다.
              Align(
                alignment: Alignment.bottomCenter,
                child: Obx(() {
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
                      padding: const EdgeInsets.all(AppDimens.space4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusBubble,
                        ),
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
              ),
            ],
          ),
        ),
        // 파문은 자리를 차지하지 않으므로 닿는 만큼 비워 준다.
        const SizedBox(height: AppMicButton.bloom),
        Obx(
          () => AppMicButton(
            recording: true,
            paused: controller.isPaused.value,
            level: controller.micLevel.value,
            onTap: controller.stopRecording,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          '눌러서 끝내기',
          style: AppTypography.weight(
            AppTypography.titleSection,
            AppTypography.bold,
          ).copyWith(color: AppColors.textSecondary, letterSpacing: -0.1),
        ),
        const SizedBox(height: 12),
        Obx(
          () => TextButton(
            onPressed: controller.isPaused.value
                ? controller.resumeRecording
                : controller.pauseRecording,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brand,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              controller.isPaused.value ? '이어하기' : '일시정지',
              style: AppTypography.bodyBase.copyWith(
                fontSize: 15,
                color: AppColors.brand,
                letterSpacing: -0.1,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.brand.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: controller.useKeyboard,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brand,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '글로 답하기',
            style: AppTypography.bodyBase.copyWith(
              fontSize: 15,
              color: AppColors.brand,
              letterSpacing: -0.1,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.brand.withValues(alpha: 0.45),
            ),
          ),
        ),
        SizedBox(height: AppInsets.bottom(context, 28)),
      ],
    );
  }
}
