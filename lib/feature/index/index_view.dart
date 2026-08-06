import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'index_controller.dart';

/// 01 랜딩 — Figma 미대응 (신규).
///
/// 세션이 없는 신규 사용자에게 브랜드 + 소개 + "시작하기" CTA를 보여준다.
/// 스플래시를 거친 후에야 도달하므로 버튼이 있어도 된다 — 재방문자는
/// 스플래시에서 세션 복원 후 곧바로 홈/자기소개로 가므로 이 화면을 보지 않는다.
class IndexView extends GetView<IndexController> {
  const IndexView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 브랜드 영역
            const Spacer(flex: 3),
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBrandMark(),
                SizedBox(height: 30),
                AppWordmark(fontSize: 34, letterSpacing: 0.4),
                SizedBox(height: 14),
                Text(
                  '말로 작성하는 AI 자서전 기록 플랫폼',
                  textAlign: TextAlign.center,
                  style: AppTypography.brandTagline,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 핵심 가치 — 음성 · 무료 · 제작 형태
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                children: [
                  _BenefitLine('타자 없이, 말로 대답하면 알아서 써드려요'),
                  SizedBox(height: 12),
                  _BenefitLine('무료로 바로 시작할 수 있어요'),
                  SizedBox(height: 12),
                  _BenefitLine('전자책 · 오디오북 · 인쇄본까지 제작할 수 있어요'),
                ],
              ),
            ),
            const Spacer(flex: 2),

            // 시작하기 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppButton(
                label: '무료로 시작하기',
                onPressed: controller.goToLogin,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.lg,
                block: true,
              ),
            ),
            const SizedBox(height: 16),

            // 소개 · 사용설명서
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TextLink(
                  label: '소개',
                  onTap: controller.goToAbout,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '·',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                _TextLink(
                  label: '사용설명서',
                  onTap: controller.goToGuide,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 개인정보보호 문구
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '입력한 내용은 안전하게 암호화되어 보관되며,\n오직 회원님의 자서전 제작에만 사용됩니다.',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                  height: 1.5,
                ),
              ),
            ),

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}

class _BenefitLine extends StatelessWidget {
  const _BenefitLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.warm,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.textTertiary,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
