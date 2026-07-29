import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';

/// 15 채팅 모드 (글자 입력) — Figma 150:211.
class ChatStage extends GetView<WriteController> {
  const ChatStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTopBar(
          title: controller.headerTitle,
          onBack: controller.backToAsk,
          background: AppColors.brandFg,
          trailing: const Icon(
            Icons.more_vert_rounded,
            size: 22,
            color: AppColors.stone500,
          ),
        ),
        Expanded(
          child: Obx(
            () => ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.space4,
                AppDimens.space4,
                AppDimens.space4,
                AppDimens.space3,
              ),
              itemCount: controller.messages.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDimens.space2),
              itemBuilder: (_, i) {
                final m = controller.messages[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppChatBubble(role: m.role, text: m.text),
                    if (m.speakable) ...[
                      const SizedBox(height: AppDimens.space2),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: AppPill(
                          label: '🔊 다시 들려줘',
                          compact: true,
                          onTap: controller.replayQuestion,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        Obx(
          () => AppChatComposer(
            controller: controller.chatController,
            sending: controller.isBusy.value,
            onSend: controller.sendChat,
            onMic: controller.micFromChat,
          ),
        ),
      ],
    );
  }
}

/// 채팅 말풍선 위에 붙는 "AI가 다듬었어요" 배지 — 17번에서도 쓴다.
class AiBadge extends StatelessWidget {
  const AiBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('✦', style: AppTypography.label.copyWith(color: AppColors.warm)),
        const SizedBox(width: 6),
        Text(
          'AI가 다듬었어요',
          style: AppTypography.label.copyWith(color: AppColors.warm),
        ),
      ],
    );
  }
}
