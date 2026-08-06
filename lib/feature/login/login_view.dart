import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'login_controller.dart';

/// A2 로그인 — Figma 341:741.
///
/// 뒤로가기가 없다. 스플래시가 `offAllNamed`로 들어오는 첫 화면이라 돌아갈
/// 곳이 없다.
///
/// 약관·마케팅 동의 체크는 여기가 아니다. 카카오 가입 직후 또는 전화 인증
/// 직후([ConsentsView] · [SignupStep])에서 받는다. 여기 링크는 열람용이다.
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // ⚠️ `bottom: false` — 시안의 844 캔버스를 화면 전체로 보고 아래 여백
      //    64를 **화면 바닥 기준**으로 잡는다. SafeArea가 제스처 바 인셋을
      //    먹으면 그 위에 64가 더해져 블록 전체가 20px쯤 위로 뜬다.
      //    64면 제스처 바를 충분히 비켜 간다.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 시안 341:742 — 상태바 아래 156. 브랜드는 위쪽 1/3에 놓인다.
            const SizedBox(height: 156),
            const AppWordmark(),
            const SizedBox(height: 14),
            const Text(
              '당신의 이야기를\n책으로 남겨드릴게요',
              textAlign: TextAlign.center,
              style: AppTypography.brandTagline,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.gutter,
              ),
              child: Column(
                children: [
                  Obx(
                    () => _KakaoButton(
                      onTap: controller.loginWithKakao,
                      loading: controller.isSubmitting.value,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space3),
                  AppButton(
                    label: '전화번호로 시작하기',
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.lg,
                    block: true,
                    // 시안 341:751 — 이 화면의 두 버튼만 17이다(다른 CTA는 18).
                    // 두 줄이 나란히 서 있어 한 단계 낮춘 것으로 보인다.
                    labelStyle: AppTypography.ctaLabel.copyWith(fontSize: 17),
                    onPressed: controller.goAuth,
                  ),
                  const SizedBox(height: 22),
                  _ConsentNotice(
                    onTerms: controller.openTerms,
                    onPrivacy: controller.openPrivacy,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '아이디 회원가입은 웹에서 가능합니다',
                    textAlign: TextAlign.center,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: controller.goPasswordLogin,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '아이디로 로그인',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.textTertiary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppInsets.bottom(context, 64)),
          ],
        ),
      ),
    );
  }
}

/// "시작하면 이용약관과 개인정보 동의" — 약관·개인정보만 밑줄 링크.
class _ConsentNotice extends StatelessWidget {
  const _ConsentNotice({required this.onTerms, required this.onPrivacy});

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  TextStyle get _base => AppTypography.label.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 0,
        height: 1.4,
      );

  TextStyle get _link => _base.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: AppColors.textTertiary,
      );

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: _base,
        children: [
          const TextSpan(text: '시작하면 '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onTerms,
              child: Text('이용약관', style: _link),
            ),
          ),
          const TextSpan(text: '과 '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onPrivacy,
              child: Text('개인정보', style: _link),
            ),
          ),
          const TextSpan(text: ' 동의'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// 카카오 로그인 버튼.
///
/// ⚠️ 카카오 디자인 가이드가 색을 정해 둔 컴포넌트다. 노란색 #FEE500과
///    라벨 검정은 **바꾸지 않는다.** 시안(341:747)은 여기에 앱의 알약 모양
///    (높이 62 · 반경 31)만 입혔다.
class _KakaoButton extends StatelessWidget {
  const _KakaoButton({required this.onTap, required this.loading});

  final VoidCallback onTap;
  final bool loading;

  static const _kakaoYellow = Color(0xFFFEE500);
  static const _kakaoLabel = Color(0xFF191600);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '카카오로 3초 만에 시작하기',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: loading ? null : onTap,
        child: Opacity(
          opacity: loading ? 0.6 : 1,
          child: Container(
            height: AppDimens.buttonCta,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kakaoYellow,
              borderRadius: BorderRadius.circular(AppDimens.buttonCta / 2),
            ),
            child: Text(
              '카카오로 3초 만에 시작하기',
              style: AppTypography.ctaLabel.copyWith(
                fontSize: 17,
                height: 1.2,
                color: _kakaoLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
