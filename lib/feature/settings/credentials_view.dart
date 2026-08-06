import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

/// 설정 — 카카오/전화 사용자가 아이디·비밀번호를 처음 만든다.
class CredentialsController extends GetxController {
  CredentialsController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  final loginIdController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  final RxnString loginIdError = RxnString();
  final RxnString passwordError = RxnString();
  final RxBool isSubmitting = false.obs;

  @override
  void onClose() {
    loginIdController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    loginIdError.value = null;
    passwordError.value = null;

    final id = loginIdController.text.trim();
    final pw = passwordController.text;
    final confirm = confirmController.text;

    if (id.length < 3) {
      loginIdError.value = '아이디는 3자 이상이어야 해요';
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(id)) {
      loginIdError.value = '영문·숫자·._-만 사용할 수 있어요';
      return;
    }
    if (pw.length < 6) {
      passwordError.value = '비밀번호는 6자 이상이어야 해요';
      return;
    }
    if (pw != confirm) {
      passwordError.value = '비밀번호가 서로 달라요';
      return;
    }

    isSubmitting.value = true;
    try {
      final user = await _api.setCredentials(loginId: id, password: pw);
      _auth.updateUser(user);
      _toast.show('아이디와 비밀번호를 만들었어요');
      Get.back();
    } on ApiException catch (e) {
      if (e.code == 'LOGIN_ID_TAKEN') {
        loginIdError.value = e.message;
      } else {
        _toast.showError(e);
      }
    } finally {
      isSubmitting.value = false;
    }
  }
}

class CredentialsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CredentialsController(
        Get.find(),
        Get.find(),
        Get.find(),
      ),
    );
  }
}

class CredentialsView extends GetView<CredentialsController> {
  const CredentialsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(title: '아이디·비밀번호 만들기'),
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
                  '카카오·전화로 시작하신 경우, 아이디와 비밀번호를 만들어 두면 '
                  '다음에 더 쉽게 로그인할 수 있어요.',
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => AppField(
                    label: '아이디',
                    controller: controller.loginIdController,
                    hint: '영문·숫자 3자 이상',
                    errorText: controller.loginIdError.value,
                    height: AppDimens.fieldHeight,
                  ),
                ),
                const SizedBox(height: 16),
                Obx(
                  () => AppField(
                    label: '비밀번호',
                    controller: controller.passwordController,
                    hint: '6자 이상',
                    obscureText: true,
                    errorText: controller.passwordError.value,
                    height: AppDimens.fieldHeight,
                  ),
                ),
                const SizedBox(height: 16),
                AppField(
                  label: '비밀번호 확인',
                  controller: controller.confirmController,
                  hint: '한 번 더 입력',
                  obscureText: true,
                  height: AppDimens.fieldHeight,
                ),
                const SizedBox(height: 28),
                Obx(
                  () => AppButton(
                    label: '만들기',
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
