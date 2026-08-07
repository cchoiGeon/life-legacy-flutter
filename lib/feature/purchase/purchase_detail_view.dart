import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'purchase_content.dart';
import 'purchase_flow.dart';

/// FREE / T1~T4 개별 구매 안내 페이지.
class PurchaseDetailView extends StatelessWidget {
  const PurchaseDetailView({super.key});

  PurchasePlan? get _plan {
    final args = Get.arguments;
    final code = args is Map ? args['code'] as String? : null;
    return PurchaseContent.planByCode(code) ??
        PurchaseContent.planByCode(Get.parameters['code']);
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    if (plan == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const AppTopBar(title: '플랜'),
            Expanded(
              child: Center(
                child: Text(
                  '플랜 정보를 찾을 수 없어요',
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppTopBar(title: plan.isFree ? plan.name : '${plan.name} 구매'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutter,
                8,
                AppDimens.gutter,
                AppDimens.space8,
              ),
              children: [
                Text(
                  plan.tagline,
                  style: AppTypography.titlePage.copyWith(height: 1.3),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      plan.price,
                      style: AppTypography.weight(
                        AppTypography.titleScreen,
                        AppTypography.bold,
                      ).copyWith(color: AppColors.warm),
                    ),
                    if (plan.originalPrice.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          plan.originalPrice,
                          style: AppTypography.bodyBase.copyWith(
                            color: AppColors.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (plan.recommended) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '가장 많이 선택하는 플랜',
                        style: AppTypography.weight(
                          AppTypography.bodySm,
                          AppTypography.bold,
                        ).copyWith(color: AppColors.brandFg),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    plan.stepCaption,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '이 플랜으로 가능한 단계',
                  style: AppTypography.titleSection.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                for (final s in PurchaseContent.bookProcessSteps) ...[
                  _StepAvailability(
                    title: '${s.step}. ${s.title}',
                    available: s.step <= plan.maxProcessStep,
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                Text(
                  '포함 내용',
                  style: AppTypography.titleSection.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                for (final f in plan.features) ...[
                  _FeatureLine(f),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 20),
                if (!plan.isFree)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      PurchaseContent.webOnlyLead,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimens.gutter,
              8,
              AppDimens.gutter,
              AppInsets.bottom(context, 16),
            ),
            child: Column(
              children: [
                if (plan.isFree)
                  const AppButton(
                    label: '쿠폰 코드로 업그레이드',
                    size: AppButtonSize.lg,
                    block: true,
                    onPressed: PurchaseFlow.openCoupon,
                  )
                else ...[
                  AppButton(
                    label: '웹에서 ${plan.name} 구매하기',
                    size: AppButtonSize.lg,
                    block: true,
                    onPressed: () =>
                        PurchaseFlow.openWebsiteForPurchase(context),
                    icon: const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.brandFg,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const AppButton(
                    label: '쿠폰 코드로 등록',
                    size: AppButtonSize.lg,
                    block: true,
                    variant: AppButtonVariant.outline,
                    onPressed: PurchaseFlow.openCoupon,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepAvailability extends StatelessWidget {
  const _StepAvailability({required this.title, required this.available});

  final String title;
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          available ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
          size: 18,
          color: available ? AppColors.warm : AppColors.stone400,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodySm.copyWith(
              color: available
                  ? AppColors.textPrimary
                  : AppColors.textTertiary,
            ),
          ),
        ),
        Text(
          available ? '가능' : '불가',
          style: AppTypography.caption.copyWith(
            color: available ? AppColors.warm : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.warm,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
