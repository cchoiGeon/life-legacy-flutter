import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';

/// 18 직접 고치기 — Figma 152:246.
///
/// 상단에 취소/저장이 있고 하단에도 같은 버튼이 있다(시안 그대로).
/// 시니어 사용자가 키보드 위쪽 버튼을 못 찾는 경우를 대비한 배치로 보인다.
class EditStage extends GetView<WriteController> {
  const EditStage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTopBar(
          title: '직접 고치기',
          showBack: false,
          leading: Padding(
            padding: const EdgeInsets.only(left: AppDimens.space3),
            child: AppTextAction(label: '취소', onTap: controller.cancelEditing),
          ),
          trailing: AppTextAction(
            label: '저장',
            emphasized: true,
            onTap: controller.saveEdited,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimens.space4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimens.radiusBase),
                border: Border.all(
                  color: AppColors.stone200,
                  width: AppDimens.borderWidthStrong,
                ),
              ),
              child: TextField(
                controller: controller.editController,
                autofocus: true,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                cursorColor: AppColors.brand,
                style: AppTypography.bookBody,
                decoration: const InputDecoration.collapsed(hintText: null),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.gutter,
            AppDimens.space4,
            AppDimens.gutter,
            AppDimens.space5,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: '취소',
                  variant: AppButtonVariant.neutral,
                  size: AppButtonSize.lg,
                  block: true,
                  onPressed: controller.cancelEditing,
                ),
              ),
              const SizedBox(width: AppDimens.space3),
              Expanded(
                child: Obx(
                  () => AppButton(
                    label: '저장',
                    size: AppButtonSize.lg,
                    block: true,
                    loading: controller.isBusy.value,
                    onPressed: controller.saveEdited,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
