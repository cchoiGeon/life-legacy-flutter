import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'write_controller.dart';

/// 작성 진입마다 보이는 소리·마이크 점검.
///
/// 1) 샘플 TTS로 스피커·볼륨 확인
/// 2) 로컬 STT로 마이크 권한·인식 확인
/// 실패해도 막지 않는다 — 타이핑으로 이어갈 수 있다.
class VoiceCheckOverlay extends GetView<WriteController> {
  const VoiceCheckOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.overlayScrim,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.gutter),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(AppDimens.space5),
                decoration: BoxDecoration(
                  color: AppColors.brandFg,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSheet),
                  boxShadow: AppShadows.lg,
                ),
                child: Obx(() {
                  final playing = controller.isPlayingSample.value;
                  final micTesting = controller.isMicTesting.value;
                  final micLive = controller.micTestLive.trim();
                  final micOk = controller.micTestResult.value?.isNotEmpty == true;
                  final voiceOk = controller.voiceHeardOk.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '소리와 마이크 확인',
                        style: AppTypography.weight(
                          AppTypography.titleSection,
                          AppTypography.bold,
                        ).copyWith(color: AppColors.textStrong),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '작성하기 전에 스피커와 마이크가 잘 되는지 확인해요.',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── 1. 스피커 ──────────────────────────
                      const _SectionTitle('1. 스피커 소리'),
                      const SizedBox(height: 10),
                      AppButton(
                        label: playing ? '재생 중…' : '소리 들어보기',
                        size: AppButtonSize.md,
                        block: true,
                        onPressed: playing
                            ? null
                            : controller.playVoiceSample,
                      ),
                      if (controller.voiceSampleError.value != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          controller.voiceSampleError.value!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.destructive,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (voiceOk) ...[
                        const SizedBox(height: 8),
                        Text(
                          '소리가 들렸어요. 볼륨을 맞춰 보세요.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        '볼륨',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.brand,
                          inactiveTrackColor: AppColors.surfaceSoft,
                          thumbColor: AppColors.brand,
                          overlayColor: AppColors.brand.withValues(alpha: 0.12),
                        ),
                        child: Slider(
                          value: controller.voiceVolume.value,
                          onChanged: controller.setVoiceVolume,
                          min: 0,
                          max: 1,
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),

                      // ── 2. 마이크 ──────────────────────────
                      const _SectionTitle('2. 마이크'),
                      const SizedBox(height: 10),
                      AppButton(
                        label: micTesting ? '말하는 중 · 눌러서 멈춤' : '마이크 테스트',
                        size: AppButtonSize.md,
                        variant: micTesting
                            ? AppButtonVariant.outline
                            : AppButtonVariant.neutral,
                        block: true,
                        onPressed: micTesting
                            ? controller.stopMicTest
                            : controller.startMicTest,
                      ),
                      if (micTesting || micLive.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppDimens.space4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(
                              AppDimens.radiusBubble,
                            ),
                          ),
                          child: Text(
                            micLive.isEmpty
                                ? '짧게 말씀해 보세요…'
                                : micLive,
                            style: AppTypography.bodyChat.copyWith(
                              color: AppColors.textStrong,
                            ),
                          ),
                        ),
                      ],
                      if (controller.micTestError.value != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          controller.micTestError.value!,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.destructive,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (micOk) ...[
                        const SizedBox(height: 8),
                        Text(
                          '마이크가 잘 들려요.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (controller.micPermissionOk.value == false) ...[
                        const SizedBox(height: 8),
                        Text(
                          '마이크를 쓸 수 없으면 글로 답하셔도 돼요.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      AppButton(
                        label: '확인했어요',
                        size: AppButtonSize.lg,
                        block: true,
                        onPressed: () => controller.dismissVoiceCheck(),
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: '글로 답할게요',
                        size: AppButtonSize.assist,
                        variant: AppButtonVariant.neutral,
                        block: true,
                        onPressed: () =>
                            controller.dismissVoiceCheck(preferTyping: true),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.weight(
        AppTypography.bodyBase,
        AppTypography.bold,
      ).copyWith(color: AppColors.textStrong),
    );
  }
}
