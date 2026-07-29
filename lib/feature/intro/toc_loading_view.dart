import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'toc_controller.dart';

/// 09 목차 준비 중 — Figma 145:81.
///
/// 뒤로가기를 막는다. 생성이 끝나면 컨트롤러가 알아서 10번으로 넘긴다.
class TocLoadingView extends GetView<TocController> {
  const TocLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppSpinner(size: 64),
                const SizedBox(height: AppDimens.space8),
                Text(
                  '목차를 준비하고 있어요',
                  style: AppTypography.weight(
                    AppTypography.headingXl,
                    AppTypography.bold,
                  ),
                ),
                const SizedBox(height: AppDimens.space3),
                Obx(() {
                  final name = controller.name.value;
                  return Text(
                    name.isEmpty
                        ? '이야기를 담을\n순서를 짜고 있어요. 잠시만요.'
                        : '$name 님의 이야기를 담을\n순서를 짜고 있어요. 잠시만요.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
