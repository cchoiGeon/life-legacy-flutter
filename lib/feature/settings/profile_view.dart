import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'profile_controller.dart';

/// F3 내 정보 — 프로필 사진 업로드 가능.
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
                    child: GestureDetector(
                      onTap: controller.isUploadingAvatar.value
                          ? null
                          : controller.pickAndUploadAvatar,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          AppAvatar(
                            initial: user?.initial ?? '?',
                            size: 88,
                            imageBytes: controller.avatarBytes,
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.brand,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 2,
                              ),
                            ),
                            child: controller.isUploadingAvatar.value
                                ? const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '사진을 눌러 변경',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const AppSettingSection('기본 정보'),
                  AppSettingGroup(
                    children: [
                      AppSettingRow(title: '이름', value: user?.name ?? ''),
                      AppSettingRow(
                        title: '전화번호',
                        value: Address.formatPhone(user?.phone ?? ''),
                      ),
                      if (user?.loginId != null)
                        AppSettingRow(
                          title: '로그인 아이디',
                          value: user!.loginId!,
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
                        AppSettingRow(
                          title: e.label,
                          value: e.skipped ? '건너뜀' : (e.value ?? '-'),
                        ),
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
