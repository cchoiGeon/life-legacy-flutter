import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/shared/tab_scaffold.dart';

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
              const Text('설정', style: AppTypography.titleScreen),
              const SizedBox(height: 14),

              AppProfileCard(
                initial: user?.initial ?? '?',
                name: user?.name ?? '',
                phone: Address.formatPhone(user?.phone ?? ''),
                onTap: controller.openProfile,
              ),

              const AppSettingSection('계정', dotColor: AppColors.warm),
              AppSettingGroup(
                children: [
                  AppSettingRow(
                    title: '인쇄본 배송지',
                    onTap: controller.openShippingAddress,
                  ),
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
                  AppSettingRow(title: '이용약관', onTap: controller.openTerms),
                  AppSettingRow(
                    title: '개인정보 처리방침',
                    onTap: controller.openPrivacy,
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
