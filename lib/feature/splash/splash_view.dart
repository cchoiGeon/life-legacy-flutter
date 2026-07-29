import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'splash_controller.dart';

/// 01 스플래시 — Figma 140:4.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const _Logo(),
              const SizedBox(height: AppDimens.space4),
              const AppWordmark(fontSize: 22),
              const SizedBox(height: AppDimens.space6),
              Text(
                '당신의 이야기가\n책이 됩니다',
                textAlign: TextAlign.center,
                style: AppTypography.display3xl,
              ),
              const SizedBox(height: AppDimens.space4),
              Text(
                '말씀만 하시면 AI가\n한 권의 자서전으로 써 드려요',
                textAlign: TextAlign.center,
                style: AppTypography.bodyBase.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 4),
              Obx(
                () => AppButton(
                  label: '시작하기',
                  size: AppButtonSize.lg,
                  block: true,
                  enabled: !controller.isChecking.value,
                  onPressed: controller.start,
                ),
              ),
              const SizedBox(height: AppDimens.space4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: controller.alreadyUsing,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.space2),
                  child: Text(
                    '이미 쓰고 있어요',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space6),
            ],
          ),
        ),
      ),
    );
  }
}

/// 브랜드 원 + 나뭇잎(깃펜) 심볼.
///
/// 시안의 심볼은 벡터 에셋으로 내보낼 수 있지만, 곡선 두 개짜리 도형이라
/// 직접 그렸다. 로고가 확정되면 SVG 에셋으로 바꾸는 게 맞다.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
      ),
      child: CustomPaint(size: const Size(48, 48), painter: _LeafPainter()),
    );
  }
}

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 잎 모양 — 좌우로 마주 보는 두 곡선.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.08)
        ..quadraticBezierTo(w * 0.95, h * 0.42, w * 0.5, h * 0.92)
        ..quadraticBezierTo(w * 0.05, h * 0.42, w * 0.5, h * 0.08)
        ..close(),
      Paint()..color = AppColors.brandFg,
    );

    // 잎맥
    canvas.drawLine(
      Offset(w * 0.5, h * 0.2),
      Offset(w * 0.5, h * 0.82),
      Paint()
        ..color = AppColors.brand
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LeafPainter oldDelegate) => false;
}
