import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';

/// 13 음성 모드 · 기본 — Figma 148:170.
///
/// ⚠️ 이 화면은 **시안 실측값을 그대로** 옮겼다. 공용 토큰(AppDimens)이
///    아니라 숫자를 직접 쓴 곳이 있는데, 시안의 간격이 4px 그리드에 딱
///    떨어지지 않기 때문이다(예: 헤더 py 6, 진행률 pt 2). 토큰으로 반올림하면
///    시안과 어긋난다.
class AskStage extends GetView<WriteController> {
  const AskStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(),
        _Progress(),
        Expanded(child: _Body()),
      ],
    );
  }
}

/// 148:182 — 뒤로가기 28 · 제목 12px Medium · 더보기 24, `pl12 pr16 py6`
class _Header extends GetView<WriteController> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 16, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              button: true,
              label: '뒤로',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: Get.back,
                child: const AppIcon(AppIcons.chevronLeft, size: 28),
              ),
            ),
            Text(
              controller.headerTitle,
              style: AppTypography.weight(
                AppTypography.label,
                AppTypography.medium,
              ).copyWith(color: AppColors.textSecondary, letterSpacing: -0.12),
            ),
            const AppIcon(AppIcons.moreVertical, size: 24),
          ],
        ),
      ),
    );
  }
}

/// 148:190 — 진행률 바가 **위**, "질문 3 / 6"이 아래. `px20 pt2 pb6`, gap 6.
/// 트랙 `#f0ebe3` · 채움 `warm #c4a77d` · 높이 6 · 반경 3.
class _Progress extends GetView<WriteController> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
      child: Column(
        // ⚠️ stretch가 필요하다. 바깥 Column이 center 정렬이라 그냥 두면
        //    이 블록이 자식(라벨) 폭으로 줄어들어 진행률 바가 가운데
        //    짧게 뜬다. 시안은 좌우 여백 20을 뺀 **가로 전체**다.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Container(
              height: 6,
              color: AppColors.bubbleSys,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: controller.chapterProgress.clamp(0.0, 1.0),
                child: Container(color: AppColors.warm),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              controller.progressLabel,
              style: AppTypography.caption.copyWith(
                color: AppColors.stone500,
                letterSpacing: -0.13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 148:194 — 세로 가운데 정렬, gap 24, `px28`
class _Body extends GetView<WriteController> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 148:195 — 26px Bold, 행간 34
          Text(
            controller.question.value?.text ?? '',
            textAlign: TextAlign.center,
            style: AppTypography.weight(
              AppTypography.headingXl,
              AppTypography.bold,
            ).copyWith(fontSize: 26, height: 34 / 26, letterSpacing: -0.26),
          ),
          const SizedBox(height: 24),
          _ReplayChip(onTap: controller.replayQuestion),
          const SizedBox(height: 24),
          // 148:201 — 원 112 + 아이콘 40, 아래 라벨까지 gap 14
          AppMicButton(
            recording: false,
            size: 112,
            onTap: controller.startRecording,
          ),
          const SizedBox(height: 14),
          Text(
            '누르고 말씀하세요',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: -0.16,
            ),
          ),
          const SizedBox(height: 24),
          AppKeyboardButton(onPressed: controller.useKeyboard),
          const SizedBox(height: 24),
          // 148:208 — 14px Regular, 밑줄 없음
          Semantics(
            button: true,
            label: '이 질문 건너뛰기',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.skip,
              child: Text(
                '이 질문 건너뛰기',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.stone500,
                  letterSpacing: -0.14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 148:196 — 크림 알약, `px14 py8`, gap 6, 스피커 16px + 14px 글자
class _ReplayChip extends StatelessWidget {
  const _ReplayChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '다시 들려줘',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bubbleSys,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon(AppIcons.speaker, size: 16),
              const SizedBox(width: 6),
              Text(
                '다시 들려줘',
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: -0.14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
