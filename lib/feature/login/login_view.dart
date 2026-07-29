import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'login_controller.dart';

/// 02 로그인 — Figma 141:13.
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const AppWordmark(fontSize: 24),
                  const SizedBox(height: AppDimens.space3),
                  Text(
                    '쓰시던 계정으로 이어 쓸 수 있어요',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(flex: 5),
                  Obx(
                    () => _KakaoButton(
                      onTap: controller.loginWithKakao,
                      loading: controller.isSubmitting.value,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space3),
                  AppButton(
                    label: '전화번호로 시작하기',
                    variant: AppButtonVariant.neutral,
                    size: AppButtonSize.lg,
                    block: true,
                    onPressed: controller.goPhone,
                  ),
                  const SizedBox(height: AppDimens.space4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: controller.childAccount,
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.space2),
                      child: Text(
                        '자녀 계정으로 함께 쓰기',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.space8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 카카오 로그인 버튼.
///
/// ⚠️ 카카오 디자인 가이드가 색·비율을 정해 둔 컴포넌트다.
///    노란색 #FEE500 · 라벨 불투명도 85% 검정은 **바꾸지 않는다.**
///    (모서리 반경만 시안의 12px을 따랐다.)
class _KakaoButton extends StatelessWidget {
  const _KakaoButton({required this.onTap, required this.loading});

  final VoidCallback onTap;
  final bool loading;

  static const _kakaoYellow = Color(0xFFFEE500);
  static const _kakaoLabel = Color(0xD9000000);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '카카오톡으로 시작하기',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: loading ? null : onTap,
        child: Opacity(
          opacity: loading ? 0.6 : 1,
          child: Container(
            height: AppDimens.buttonLg,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kakaoYellow,
              borderRadius: BorderRadius.circular(AppDimens.radiusBase),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomPaint(
                  size: const Size(20, 20),
                  painter: _KakaoBubblePainter(),
                ),
                const SizedBox(width: AppDimens.space2),
                Text(
                  '카카오톡으로 시작하기',
                  style: AppTypography.weight(
                    AppTypography.bodyBase,
                    AppTypography.medium,
                  ).copyWith(color: _kakaoLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 카카오 말풍선 심볼 — 타원 + 꼬리.
class _KakaoBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xD9000000);
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromLTRB(w * 0.04, h * 0.12, w * 0.96, h * 0.76),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.3, h * 0.66)
        ..lineTo(w * 0.22, h * 0.96)
        ..lineTo(w * 0.52, h * 0.72)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(_KakaoBubblePainter oldDelegate) => false;
}
