import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/service/services.dart';

/// 아이디·비밀번호 로그인 화면.
class PasswordLoginController extends GetxController {
  PasswordLoginController(this._api, this._auth);

  final ApiClient _api;
  final AuthService _auth;

  final loginIdController = TextEditingController();
  final passwordController = TextEditingController();
  final RxnString errorText = RxnString();
  final RxBool isSubmitting = false.obs;

  @override
  void onClose() {
    loginIdController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    errorText.value = null;
    final id = loginIdController.text.trim();
    final pw = passwordController.text;
    if (id.isEmpty || pw.isEmpty) {
      errorText.value = '아이디와 비밀번호를 입력해 주세요';
      return;
    }

    isSubmitting.value = true;
    try {
      final session = await _api.loginWithCredentials(
        loginId: id,
        password: pw,
      );
      await _auth.applySession(session, loginProvider: 'credentials');
      Get.offAllNamed(
        session.needsIntro ? AppRoutes.intro : AppRoutes.home,
      );
    } on ApiException catch (e) {
      errorText.value = e.message;
    } finally {
      isSubmitting.value = false;
    }
  }
}

class PasswordLoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => PasswordLoginController(Get.find(), Get.find()),
    );
  }
}

class PasswordLoginView extends GetView<PasswordLoginController> {
  const PasswordLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(title: '아이디로 로그인'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutter,
                AppDimens.space4,
                AppDimens.gutter,
                AppDimens.space8,
              ),
              children: [
                Text(
                  '웹에서 가입했거나, 설정에서 만든 아이디로 로그인합니다.',
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                AppField(
                  label: '아이디',
                  controller: controller.loginIdController,
                  hint: '아이디',
                  height: AppDimens.fieldHeight,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                AppField(
                  label: '비밀번호',
                  controller: controller.passwordController,
                  hint: '비밀번호',
                  obscureText: true,
                  height: AppDimens.fieldHeight,
                  onSubmitted: (_) => controller.submit(),
                ),
                Obx(() {
                  final err = controller.errorText.value;
                  if (err == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      err,
                      style: AppTypography.label.copyWith(
                        color: AppColors.destructive,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 28),
                Obx(
                  () => AppButton(
                    label: '로그인',
                    onPressed: controller.isSubmitting.value
                        ? null
                        : controller.submit,
                    loading: controller.isSubmitting.value,
                    block: true,
                    size: AppButtonSize.lg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
