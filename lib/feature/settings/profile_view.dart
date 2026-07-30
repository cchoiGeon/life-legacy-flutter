import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'profile_controller.dart';

/// F3 내 정보 (보기 전용) — Figma 368:901.
///
/// 자기소개 답변까지 같이 보여준다. 그 답에 따라 물어볼 질문이 정해졌다는
/// 걸 알려 줘야 "왜 이런 걸 물었지"가 풀린다.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(title: '내 정보'),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: AppSpinner());
              }
              final user = controller.user;

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  AppDimens.space4,
                  AppDimens.gutter,
                  AppDimens.space8,
                ),
                children: [
                  Center(
                    child: AppAvatar(initial: user?.initial ?? '?', size: 72),
                  ),
                  const AppSettingSection('기본 정보'),
                  AppSettingGroup(
                    children: [
                      AppSettingRow(title: '이름', value: user?.name ?? ''),
                      AppSettingRow(
                        title: '전화번호',
                        value: Address.formatPhone(user?.phone ?? ''),
                      ),
                    ],
                  ),

                  const AppSettingSection('인쇄본 배송지'),
                  AppSettingGroup(
                    children: [
                      AppSettingStackedRow(
                        label: '받는 분',
                        value: controller.recipientLine,
                      ),
                      AppSettingStackedRow(
                        label: '주소',
                        value: controller.addressLine,
                      ),
                    ],
                  ),

                  const AppSettingSection('자기소개'),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 10),
                    child: Text(
                      '이 답변에 따라 여쭤보는 질문이 정해졌어요',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  AppSettingGroup(
                    children: [
                      for (final e
                          in controller.introProfile.value?.entries ??
                              const <IntroProfileEntry>[])
                        AppSettingRow(title: e.label, value: e.value),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
