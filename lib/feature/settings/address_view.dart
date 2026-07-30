import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'address_controller.dart';

/// F4 인쇄본 배송지 수정 — Figma 370:901.
class AddressView extends GetView<AddressController> {
  const AddressView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          const AppTopBar(title: '인쇄본 배송지'),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: AppSpinner());
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  16,
                  AppDimens.gutter,
                  AppDimens.space6,
                ),
                children: [
                  Text(
                    '완성된 책을 받으실 주소예요',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppField(
                    label: '받는 분',
                    controller: controller.recipient,
                    hint: '성함',
                    height: AppDimens.fieldHeight,
                    textStyle: _fieldStyle,
                  ),
                  const SizedBox(height: 22),
                  AppField(
                    label: '연락처',
                    controller: controller.phone,
                    hint: '010 0000 0000',
                    height: AppDimens.fieldHeight,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                    ],
                    textStyle: _fieldStyle,
                  ),
                  const SizedBox(height: 22),
                  const _AddressLabel('주소'),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppField(
                          controller: controller.postalCode,
                          hint: '우편번호',
                          height: AppDimens.fieldHeight,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          textStyle: _fieldStyle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 114,
                        height: AppDimens.fieldHeight,
                        child: AppButton(
                          label: '주소 찾기',
                          variant: AppButtonVariant.neutral,
                          size: AppButtonSize.md,
                          block: true,
                          labelStyle: AppTypography.weight(
                            AppTypography.bodyChat,
                            AppTypography.bold,
                          ),
                          onPressed: controller.searchPostalCode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AppField(
                    controller: controller.line1,
                    hint: '기본 주소',
                    height: AppDimens.fieldHeight,
                    textStyle: _fieldStyle,
                  ),
                  const SizedBox(height: 10),
                  AppField(
                    controller: controller.line2,
                    hint: '상세 주소 (동·호수)',
                    height: AppDimens.fieldHeight,
                    textStyle: _fieldStyle,
                  ),
                ],
              );
            }),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimens.gutter,
              0,
              AppDimens.gutter,
              AppInsets.bottom(context, AppDimens.space5),
            ),
            child: Obx(
              () => AppButton(
                label: '저장하기',
                size: AppButtonSize.lg,
                block: true,
                enabled: controller.canSave,
                loading: controller.isSaving.value,
                onPressed: controller.save,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 시안 370:907 — 입력 글자 17.
  static TextStyle get _fieldStyle =>
      AppTypography.bodyBase.copyWith(fontSize: 17, height: 1.3);
}

/// 우편번호 줄은 [AppField]의 label을 못 쓴다 — 라벨 하나에 필드가 둘이라
/// 따로 그린다.
class _AddressLabel extends StatelessWidget {
  const _AddressLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimens.space2),
    child: Text(
      text,
      style: AppTypography.weight(
        AppTypography.caption,
        AppTypography.medium,
      ).copyWith(color: AppColors.textStrong),
    ),
  );
}
