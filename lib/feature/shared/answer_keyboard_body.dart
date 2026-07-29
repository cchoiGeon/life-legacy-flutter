import 'package:flutter/material.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

/// 키보드로 답을 적는 화면 몸통 — 질문 + 입력칸 + 하단 CTA.
///
/// 자기소개(08)와 작성 탭의 글자 입력이 **같은 컴포넌트를 쓴다.**
/// 두 곳의 동작이 같은데 화면만 따로 두면 한쪽만 고쳐지는 일이 생긴다.
class AnswerKeyboardBody extends StatelessWidget {
  const AnswerKeyboardBody({
    super.key,
    required this.question,
    required this.controller,
    required this.canSubmit,
    required this.onSubmit,
    required this.ctaLabel,
    this.hint,
    this.isRecording = false,
    this.onMic,
  });

  /// 화면 위에 굵게 뜨는 질문. 줄바꿈은 여기서 공백으로 편다 —
  /// 음성 화면은 가운데 두 줄로 보여주지만 여기서는 왼쪽 정렬 한 덩어리다.
  final String question;

  final TextEditingController controller;

  /// 입력이 비어 있으면 CTA를 잠근다.
  final bool canSubmit;

  final VoidCallback onSubmit;
  final String ctaLabel;
  final String? hint;

  /// 입력칸 오른쪽 마이크 버튼 상태. [onMic]이 null이면 마이크를 그리지 않는다.
  final bool isRecording;
  final VoidCallback? onMic;

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
                  question.replaceAll('\n', ' '),
                  style: AppTypography.weight(
                    AppTypography.headingXl,
                    AppTypography.bold,
                  ),
                ),
                const SizedBox(height: AppDimens.space4),
                AppField(
                  controller: controller,
                  hint: hint,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 6,
                  suffix: onMic == null
                      ? null
                      : AppCircleButton(
                          size: 32,
                          semanticLabel: '음성으로 바꾸기',
                          onTap: onMic,
                          child: Icon(
                            Icons.mic_none_rounded,
                            size: 20,
                            color: isRecording
                                ? AppColors.accentSoft
                                : AppColors.brand,
                          ),
                        ),
                ),
                if (onMic != null) ...[
                  const SizedBox(height: AppDimens.space2),
                  Text(
                    '음성으로 바꾸려면 마이크를 누르세요',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
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
          child: AppButton(
            label: ctaLabel,
            size: AppButtonSize.lg,
            block: true,
            enabled: canSubmit,
            onPressed: onSubmit,
          ),
        ),
      ],
    );
  }
}
