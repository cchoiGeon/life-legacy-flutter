import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/feature/legal/legal_document_view.dart';

import '../auth_controller.dart';

/// 4단계: 신규 사용자 — 이름 입력 + 약관·마케팅 동의.
///
/// 전화 인증이 끝난 뒤에만 도달한다. 카카오 신규는 [ConsentsView]에서
/// 같은 동의를 받는다.
class SignupStep extends GetView<AuthController> {
  const SignupStep({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        AppDimens.space6,
        AppDimens.gutter,
        AppDimens.space6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppScreenHeading(
            title: '이용약관을\n확인해 주세요',
            subtitle: '선생님의 소중한 기억을 안전하게 보호합니다.',
          ),
          const SizedBox(height: 32),

          // 이름 입력 — TextEditingController만 쓰므로 Obx 불필요
          // (Obx 안에 .obs가 없으면 GetX improper use 오류가 난다)
          AppField(
            controller: controller.nameController,
            hint: '이름을 입력해 주세요',
            height: AppDimens.fieldHeight,
            textStyle: AppTypography.weight(
              AppTypography.titlePage,
              AppTypography.medium,
            ).copyWith(fontSize: 20, height: 1.2),
            onChanged: controller.onNameChanged,
          ),
          const SizedBox(height: 32),

          // 모두 동의
          Obx(
            () => _ConsentTile(
              title: '모두 동의합니다',
              subtitle: '전체 약관에 동의합니다',
              isRequired: false,
              isAllAgree: true,
              agreed: controller.allAgreed,
              onTap: controller.toggleAllConsents,
            ),
          ),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: AppDimens.space2),

          // 개별 약관 목록
          Obx(
            () => Column(
              children: [
                for (var i = 0; i < controller.consents.length; i++)
                  _ConsentTile(
                    title: controller.consents[i].document.title,
                    subtitle: controller.consents[i].document.required
                        ? '필수'
                        : '선택',
                    isRequired: controller.consents[i].document.required,
                    agreed: controller.consents[i].agreed,
                    onTap: () => controller.toggleConsent(i),
                    document: controller.consents[i].document,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Obx(
            () => AppButton(
              label: '동의하고 시작하기',
              size: AppButtonSize.lg,
              block: true,
              enabled: controller.canSignup,
              loading: controller.isLoading.value,
              onPressed: controller.submitSignup,
            ),
          ),
        ],
      ),
    );
  }
}

/// 약관 동의 항목 타일.
class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.title,
    required this.subtitle,
    required this.isRequired,
    this.isAllAgree = false,
    required this.agreed,
    required this.onTap,
    this.document,
  });

  final String title;
  final String subtitle;
  final bool isRequired;
  final bool isAllAgree;
  final bool agreed;
  final VoidCallback onTap;
  final ConsentDocument? document;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimens.space3,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: agreed ? AppColors.brand : AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: agreed ? AppColors.brand : AppColors.borderSoft,
                  width: AppDimens.borderWidthStrong,
                ),
              ),
              child: agreed
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: AppDimens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: (isAllAgree
                            ? AppTypography.weight(
                                AppTypography.bodyBase,
                                AppTypography.medium,
                              )
                            : AppTypography.bodyBase)
                        .copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: AppTypography.label.copyWith(
                        color: isRequired
                            ? AppColors.brand
                            : AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            if (document != null && document!.hasBody)
              GestureDetector(
                onTap: () => LegalDocumentView.open(
                  document!.key,
                  initial: document,
                ),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}