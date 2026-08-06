import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'purchase_content.dart';
import 'purchase_flow.dart';

/// T1~T4 플랜 목록 — 각 카드에서 상세(구매) 페이지로 이동.
class PurchaseView extends StatelessWidget {
  const PurchaseView({super.key});

  bool get _isPaywall {
    final args = Get.arguments;
    return args is Map && args['paywall'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(title: PurchaseContent.listTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutter,
                8,
                AppDimens.gutter,
                AppDimens.space8,
              ),
              children: [
                if (_isPaywall) ...[
                  const _PaywallBanner(),
                  const SizedBox(height: 20),
                ] else ...[
                  Text(
                    PurchaseContent.listSubtitle,
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                for (final plan in PurchaseContent.plans) ...[
                  _PlanTile(
                    plan: plan,
                    onTap: () => PurchaseFlow.openPlan(plan.code),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                AppButton(
                  label: '쿠폰 코드 등록',
                  onPressed: PurchaseFlow.openCoupon,
                  variant: AppButtonVariant.outline,
                  block: true,
                ),
                const SizedBox(height: 16),
                Text(
                  '결제는 ${PurchaseContent.websiteLabel} 웹사이트에서 진행됩니다.\n'
                  '쿠폰이 있으면 앱에서 바로 플랜을 적용할 수 있어요.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    height: 1.45,
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

class _PaywallBanner extends StatelessWidget {
  const _PaywallBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2F4A3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            PurchaseContent.paywallBannerTitle,
            style: AppTypography.weight(
              AppTypography.bodyBase,
              AppTypography.bold,
            ).copyWith(color: Colors.white, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            PurchaseContent.paywallBannerBody,
            style: AppTypography.bodySm.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.onTap});

  final PurchasePlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: plan.recommended ? AppColors.cream : AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: plan.recommended ? AppColors.brand : AppColors.borderSoft,
              width: plan.recommended ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    plan.name,
                    style: AppTypography.weight(
                      AppTypography.bodyBase,
                      AppTypography.bold,
                    ),
                  ),
                  if (plan.recommended) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brand,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '추천',
                        style: AppTypography.weight(
                          AppTypography.bodySm,
                          AppTypography.bold,
                        ).copyWith(color: AppColors.brandFg, fontSize: 11),
                      ),
                    ),
                  ],
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                plan.tagline,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.price,
                    style: AppTypography.weight(
                      AppTypography.titleSection,
                      AppTypography.bold,
                    ).copyWith(color: AppColors.brand),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    plan.originalPrice,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textTertiary,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
