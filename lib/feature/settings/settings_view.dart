import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/feature/shared/tab_scaffold.dart';

import 'settings_controller.dart';

/// 22 설정 — Figma 155:318.
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      tab: AppTab.settings,
      backgroundColor: AppColors.cream,
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
              AppDimens.space4,
              AppDimens.gutter,
              AppDimens.space8,
            ),
            children: [
              Text('설정', style: AppTypography.titlePage),
              const SizedBox(height: AppDimens.space5),

              // 프로필
              _Group(
                children: [
                  _Row(
                    onTap: controller.openProfile,
                    leading: AppAvatar(initial: user?.initial ?? '?', size: 44),
                    title: user?.name ?? '',
                    subtitle: _formatPhone(user?.phone ?? ''),
                  ),
                ],
              ),

              const _SectionLabel('계정'),
              _Group(
                children: [
                  _Row(title: '인쇄본 배송지', onTap: controller.openShippingAddress),
                ],
              ),

              const _SectionLabel('알림'),
              _Group(
                children: [
                  _Row(
                    title: '오늘의 질문 알림',
                    trailing: _Switch(
                      value: settings?.dailyQuestionAlarm ?? false,
                      onChanged: controller.setDailyAlarm,
                    ),
                  ),
                ],
              ),

              const _SectionLabel('기타'),
              _Group(
                children: [
                  _Row(title: '이용약관', onTap: controller.openTerms),
                  _Row(title: '개인정보 처리방침', onTap: controller.openPrivacy),
                  _Row(
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

  /// 01012345678 → "010 1234 5678"
  static String _formatPhone(String digits) {
    if (digits.length != 11) return digits;
    return '${digits.substring(0, 3)} ${digits.substring(3, 7)} '
        '${digits.substring(7)}';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppDimens.space1,
      AppDimens.space5,
      0,
      AppDimens.space2,
    ),
    child: Text(
      text,
      style: AppTypography.label.copyWith(color: AppColors.textTertiary),
    ),
  );
}

/// 항목 묶음 — 흰 카드 안에 구분선으로 나눈다.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.stone200),
      ),
      child: Column(
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.stone100),
            child,
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space4,
            vertical: AppDimens.space4,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppDimens.space3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyBase.copyWith(
                        color: danger
                            ? AppColors.destructive
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  (onTap == null
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: AppColors.stone400,
                        )),
            ],
          ),
        ),
      ),
    );
  }
}

/// 토글 — 시안의 초록빛 스위치.
class _Switch extends StatelessWidget {
  const _Switch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? AppColors.accentSoft : AppColors.stone300,
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          ),
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
