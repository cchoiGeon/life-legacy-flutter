import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/feature/auth/auth_controller.dart';
import 'package:life_legacy/feature/legal/legal_document_view.dart';
import 'package:life_legacy/service/services.dart';

/// 카카오 신규 가입 직후 — 이용약관 · 개인정보 · 마케팅 동의.
///
/// 전화 인증 신규는 [SignupStep]에서 같은 동의를 받는다. 카카오는 세션이
/// 이미 발급된 뒤라 이름 입력 없이 약관만 확인한다.
class ConsentsView extends GetView<ConsentsController> {
  const ConsentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppTopBar(title: '약관 동의'),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingDocs.value) {
                  return const Center(child: CircularProgressIndicator());
                }
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
                        subtitle:
                            '선생님의 소중한 기억을 안전하게 보호합니다.',
                      ),
                      const SizedBox(height: 32),
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
                      Obx(
                        () => Column(
                          children: [
                            for (var i = 0;
                                i < controller.consents.length;
                                i++)
                              _ConsentTile(
                                title: controller.consents[i].document.title,
                                subtitle: controller.consents[i].document.required
                                    ? '필수'
                                    : '선택',
                                isRequired:
                                    controller.consents[i].document.required,
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
                          enabled: controller.canSubmit,
                          loading: controller.isSubmitting.value,
                          onPressed: controller.submit,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            SizedBox(height: AppInsets.bottom(context, 24)),
          ],
        ),
      ),
    );
  }
}

class ConsentsController extends GetxController {
  ConsentsController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final RxList<ConsentItemState> consents = <ConsentItemState>[].obs;
  final RxBool isLoadingDocs = true.obs;
  final RxBool isSubmitting = false.obs;

  bool get canSubmit =>
      consents.isNotEmpty &&
      consents.where((c) => c.document.required).every((c) => c.agreed);

  bool get allAgreed =>
      consents.isNotEmpty && consents.every((c) => c.agreed);

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoadingDocs.value = true;
    try {
      final docs = await _api.consentDocuments(consentOnly: true);
      consents.value = [
        for (final d in docs) ConsentItemState(document: d),
      ];
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoadingDocs.value = false;
    }
  }

  void toggleConsent(int index) {
    if (index < 0 || index >= consents.length) return;
    consents[index] = consents[index].copyWith(
      agreed: !consents[index].agreed,
    );
    consents.refresh();
  }

  void toggleAllConsents() {
    final newValue = !allAgreed;
    consents.value = [
      for (final c in consents) c.copyWith(agreed: newValue),
    ];
  }

  Future<void> submit() async {
    if (!canSubmit || isSubmitting.value) return;
    isSubmitting.value = true;
    try {
      // 카카오는 세션이 이미 발급된 상태. 약관·마케팅 체크 UI만 거친 뒤 온보딩.
      Get.offAllNamed(AppRoutes.intro);
    } finally {
      isSubmitting.value = false;
    }
  }
}

class ConsentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => ConsentsController(Get.find<ApiClient>(), Get.find<ToastService>()),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(vertical: AppDimens.space3),
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
                        .copyWith(color: AppColors.textPrimary),
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
