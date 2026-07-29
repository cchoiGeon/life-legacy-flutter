import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';

/// 13 음성 모드 · 기본 — Figma 148:170.
class AskStage extends GetView<WriteController> {
  const AskStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTopBar(
          title: controller.headerTitle,
          showBack: false,
          trailing: const Icon(
            Icons.more_vert_rounded,
            size: 22,
            color: AppColors.stone500,
          ),
        ),
        // ⚠️ `width: double.infinity`가 필요하다. 바깥 Column이 center 정렬이라
        //    이 블록이 자식 폭에 맞춰 줄어들면서 라벨과 진행률 바가 가운데로
        //    몰린다(왼쪽 정렬로 보이지 않는다).
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.progressLabel,
                  style: AppTypography.label.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppDimens.space2),
                AppProgressBar(value: controller.chapterProgress, height: 4),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text(
                  controller.question.value?.text ?? '',
                  textAlign: TextAlign.center,
                  style: AppTypography.titlePage,
                ),
                const SizedBox(height: AppDimens.space4),
                AppPill(label: '🔊 다시 들려줘', onTap: controller.replayQuestion),
                const Spacer(),
                AppMicButton(
                  recording: false,
                  onTap: controller.startRecording,
                ),
                Text(
                  '누르고 말씀하세요',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimens.space5),
                // 자기소개(07)와 **같은 버튼 컴포넌트**다 (Figma 158:370).
                AppKeyboardButton(onPressed: controller.useKeyboard),
                const SizedBox(height: AppDimens.space3),
                _Link(label: '이 질문 건너뛰기', onTap: controller.skip, subtle: true),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onTap, this.subtle = false});

  final String label;
  final VoidCallback onTap;

  /// 더 약하게 — "건너뛰기"처럼 권하지 않는 액션
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space4,
            vertical: AppDimens.space2,
          ),
          child: Text(
            label,
            style: (subtle ? AppTypography.label : AppTypography.bodySm)
                .copyWith(
                  color: subtle
                      ? AppColors.textTertiary
                      : AppColors.textSecondary,
                  decoration: subtle ? null : TextDecoration.underline,
                  decorationColor: AppColors.textSecondary,
                ),
          ),
        ),
      ),
    );
  }
}
