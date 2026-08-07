import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/shared/tab_scaffold.dart';
import 'package:life_legacy/service/services.dart';

import 'settings_controller.dart';

/// F1 설정 — Figma 363:901.
///
/// ⚠️ 배경이 **흰색**이다. 예전에는 크림이었는데, 시안이 프로필 카드만
///    크림으로 두고 나머지는 흰 카드로 세웠다. 배경까지 크림이면 카드가
///    바탕에 묻힌다.
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      tab: AppTab.settings,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: AppSpinner());
          }
          final user = controller.user;
          final settings = controller.settings.value;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              14,
              AppDimens.gutter,
              AppDimens.space8,
            ),
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text('설정', style: AppTypography.titleScreen),
                  ),
                  AppMenuButton(),
                ],
              ),
              const SizedBox(height: 14),

              Obx(
                () => AppProfileCard(
                  initial: user?.initial ?? '?',
                  name: user?.name ?? '',
                  phone: Address.formatPhone(user?.phone ?? ''),
                  imageBytes: Get.find<AuthService>().avatarBytes.value,
                  onTap: controller.openProfile,
                ),
              ),

              const AppSettingSection('계정', dotColor: AppColors.warm),
              AppSettingGroup(
                children: [
                  AppSettingRow(
                    title: '인쇄본 배송지',
                    onTap: controller.openShippingAddress,
                  ),
                  if (user?.hasPassword != true)
                    AppSettingRow(
                      title: '아이디·비밀번호 만들기',
                      onTap: controller.openCreateCredentials,
                    )
                  else
                    AppSettingRow(
                      title: '로그인 아이디',
                      value: user?.loginId ?? '',
                    ),
                ],
              ),

              const AppSettingSection('화면', dotColor: AppColors.brand),
              const AppSettingGroup(
                children: [
                  _QuestionFontRow(),
                ],
              ),

              const AppSettingSection('알림', dotColor: AppColors.accentSoft),
              AppSettingGroup(
                children: [
                  AppSettingRow(
                    title: '오늘의 질문 알림',
                    trailing: AppSettingSwitch(
                      value: settings?.dailyQuestionAlarm ?? false,
                      onChanged: controller.setDailyAlarm,
                    ),
                  ),
                ],
              ),

              const AppSettingSection('기타', dotColor: AppColors.btnMuted),
              AppSettingGroup(
                children: [
                  AppSettingRow(
                    title: '플랜 구매',
                    onTap: controller.openPurchase,
                  ),
                  AppSettingRow(
                    title: '쿠폰 등록',
                    onTap: controller.openCoupon,
                  ),
                  AppSettingRow(
                    title: '소개',
                    onTap: controller.openAbout,
                  ),
                  AppSettingRow(
                    title: '사용설명서',
                    onTap: controller.openGuide,
                  ),
                  AppSettingRow(title: 'FAQ', onTap: controller.openFaq),
                  AppSettingRow(title: '문의하기', onTap: controller.openQna),
                  AppSettingRow(title: '이용약관', onTap: controller.openTerms),
                  AppSettingRow(
                    title: '개인정보 처리방침',
                    onTap: controller.openPrivacy,
                  ),
                  AppSettingRow(
                    title: '환불 정책',
                    onTap: controller.openRefund,
                  ),
                  AppSettingRow(
                    title: '로그아웃',
                    danger: true,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await AppDialog.confirm(
      context,
      title: '로그아웃할까요?',
      message: '작성하신 내용은 그대로 남아 있어요.',
      confirmLabel: '로그아웃',
      cancelLabel: '취소',
      danger: true,
    );
    if (ok) await controller.logout();
  }
}

/// 질문 글자 크기 — 미리보기와 − / + 로 조절한다.
class _QuestionFontRow extends StatelessWidget {
  const _QuestionFontRow();

  @override
  Widget build(BuildContext context) {
    final prefs = Get.find<PrefsService>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
      child: Obx(() {
        final level = prefs.questionFontLevel.value;
        final canSmaller = level > 0;
        final canLarger = level < PrefsService.levels.length - 1;
        final previewSize = prefs.questionPrimarySize;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '질문 글자 크기',
              style: AppTypography.weight(
                AppTypography.bodyBase,
                AppTypography.medium,
              ).copyWith(
                fontSize: 17,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '가족과 함께 했던 여행 중\n가장 기억에 남는 장소는 어디인가요?',
                textAlign: TextAlign.center,
                style: AppTypography.titleScreen.copyWith(
                  fontSize: previewSize,
                  height: 1.45,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _FontStepButton(
                  label: '−',
                  semanticLabel: '글자 작게',
                  enabled: canSmaller,
                  onTap: prefs.smallerQuestionFont,
                ),
                Expanded(
                  child: Text(
                    prefs.questionFontLabel,
                    textAlign: TextAlign.center,
                    style: AppTypography.weight(
                      AppTypography.bodyBase,
                      AppTypography.bold,
                    ).copyWith(fontSize: 16),
                  ),
                ),
                _FontStepButton(
                  label: '+',
                  semanticLabel: '글자 크게',
                  enabled: canLarger,
                  onTap: prefs.largerQuestionFont,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}

class _FontStepButton extends StatelessWidget {
  const _FontStepButton({
    required this.label,
    required this.semanticLabel,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? AppColors.surfaceSoft : AppColors.stone100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Text(
            label,
            style: AppTypography.weight(
              AppTypography.titlePage,
              AppTypography.bold,
            ).copyWith(
              fontSize: 22,
              height: 1,
              color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
