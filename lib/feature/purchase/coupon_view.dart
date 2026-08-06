import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

/// 쿠폰 코드 입력 → T1~T4 플랜 적용.
class CouponController extends GetxController {
  CouponController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final codeController = TextEditingController();
  final RxnString codeError = RxnString();
  final RxBool isSubmitting = false.obs;

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    codeError.value = null;
    final code = codeController.text.trim();
    if (code.length < 4) {
      codeError.value = '쿠폰 코드를 입력해 주세요';
      return;
    }

    isSubmitting.value = true;
    try {
      final result = await _api.redeemCoupon(code);
      _toast.show(result.message, description: '${result.planCode} 플랜');
      Get.back(result: result);
    } on ApiException catch (e) {
      switch (e.code) {
        case 'COUPON_NOT_FOUND':
        case 'COUPON_INACTIVE':
        case 'COUPON_EXPIRED':
        case 'COUPON_EXHAUSTED':
        case 'COUPON_ALREADY_REDEEMED':
          codeError.value = e.message;
        default:
          _toast.showError(e);
      }
    } finally {
      isSubmitting.value = false;
    }
  }
}

class CouponBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => CouponController(Get.find(), Get.find()),
    );
  }
}

class CouponView extends GetView<CouponController> {
  const CouponView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(title: '쿠폰 등록'),
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
                  '받으신 쿠폰 코드를 입력하면 해당 플랜(T1~T4)이 바로 적용돼요. '
                  '적용 후에는 2장 이후 작성과 플랜에 포함된 기능을 이용할 수 있어요.',
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => AppField(
                    label: '쿠폰 코드',
                    controller: controller.codeController,
                    hint: '예: WELCOME-T1',
                    errorText: controller.codeError.value,
                    height: AppDimens.fieldHeight,
                  ),
                ),
                const SizedBox(height: 28),
                Obx(
                  () => AppButton(
                    label: '등록하기',
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
