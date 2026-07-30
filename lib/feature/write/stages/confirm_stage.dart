import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';
import '../write_header.dart';

/// D4 답변 확인 · D5 저장 실패 — Figma 351:964 · 354:1035.
///
/// **한 화면의 두 상태다.** 저장에 실패해도 다른 화면으로 보내지 않는다 —
/// 정리된 글을 눈앞에 둔 채로 다시 저장하게 해야 "내 이야기가 날아갔나"라는
/// 걱정이 생기지 않는다. 바뀌는 건 제목·부제·주 버튼 문구와, 아래 안내 박스가
/// 뜨는 것뿐이다.
class ConfirmStage extends GetView<WriteController> {
  const ConfirmStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const WriteHeader(showProgressLabel: false),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              28,
              AppDimens.gutter,
              AppDimens.space6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(
                  () => AppScreenHeading(
                    title: controller.confirmTitle,
                    subtitle: controller.confirmSubtitle,
                    compact: true,
                  ),
                ),
                const SizedBox(height: 24),
                const _AnswerCard(),
                const SizedBox(height: 20),
                Obx(() {
                  if (controller.saveFailed.value) {
                    return const AppNoticeBox(
                      title: '저장하지 못했어요',
                      message: '녹음은 휴대폰에 그대로 있어요.\n인터넷이 연결되면 자동으로 저장합니다.',
                    );
                  }
                  // 실패했을 때는 글자 수 캡션을 감춘다(시안 354:1045) —
                  // 지금 알아야 할 건 분량이 아니라 저장이 안 됐다는 사실이다.
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      controller.answerCaption,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimens.gutter,
            0,
            AppDimens.gutter,
            AppInsets.bottom(context, AppDimens.space5),
          ),
          child: Column(
            children: [
              Obx(
                () => AppButton(
                  label: controller.saveLabel,
                  size: AppButtonSize.lg,
                  block: true,
                  loading: controller.isBusy.value,
                  onPressed: controller.confirmTranscript,
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => AppButton(
                  label: controller.retryLabel,
                  variant: AppButtonVariant.neutral,
                  size: AppButtonSize.secondary,
                  block: true,
                  onPressed: controller.retryAnswer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 정리된 답변 — 크림 카드에 **명조 본문** (시안 351:972).
///
/// 자서전에 실릴 글이라 미리보기(E2)와 같은 서체로 보여준다. 여기서 고딕을
/// 쓰면 저장한 뒤 책에서 다른 글처럼 보인다.
class _AnswerCard extends GetView<WriteController> {
  const _AnswerCard();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(AppDimens.radiusBubble),
        ),
        child: Text(
          controller.transcript.value,
          style: AppTypography.bookBody.copyWith(
            height: 30 / 16,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
