import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/feature/legal/legal_document_view.dart';

import 'purchase_content.dart';
import 'purchase_flow.dart';

/// FREE + T1~T4 플랜 목록 — 카드 · 제작 순서 · 환불/FAQ.
class PurchaseView extends StatefulWidget {
  const PurchaseView({super.key});

  @override
  State<PurchaseView> createState() => _PurchaseViewState();
}

class _PurchaseViewState extends State<PurchaseView> {
  String _selected = 'T1';

  bool get _isPaywall {
    final args = Get.arguments;
    return args is Map && args['paywall'] == true;
  }

  PurchasePlan get _selectedPlan =>
      PurchaseContent.planByCode(_selected) ?? PurchaseContent.plans[1];

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
                    PurchaseContent.listHeroTitle,
                    style: AppTypography.titlePage.copyWith(height: 1.3),
                  ),
                  const SizedBox(height: 8),
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
                  _PlanCard(
                    plan: plan,
                    selected: plan.code == _selected,
                    onTap: () => setState(() => _selected = plan.code),
                    onDetail: () => PurchaseFlow.openPlan(plan.code),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 12),
                const _BookProcessSection(),
                const SizedBox(height: 24),
                const _RefundSection(),
                const SizedBox(height: 16),
                const _ProductFaqSection(),
                const SizedBox(height: 16),
                const AppButton(
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
          _StickyBar(plan: _selectedPlan),
        ],
      ),
    );
  }
}

class _StickyBar extends StatelessWidget {
  const _StickyBar({required this.plan});

  final PurchasePlan plan;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      elevation: 8,
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimens.gutter,
          12,
          AppDimens.gutter,
          AppInsets.bottom(context, 12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              plan.isFree ? '체험 플랜 · 무료' : '결제 금액 ${plan.price}',
              style: AppTypography.weight(
                AppTypography.bodyBase,
                AppTypography.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              PurchaseContent.webOnlyStickyHint,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            if (plan.isFree)
              AppButton(
                label: '플랜 상세 보기',
                size: AppButtonSize.lg,
                block: true,
                onPressed: () => PurchaseFlow.openPlan(plan.code),
              )
            else
              AppButton(
                label: PurchaseContent.webPayCta,
                size: AppButtonSize.lg,
                block: true,
                onPressed: () => PurchaseFlow.openWebsiteForPurchase(context),
              ),
          ],
        ),
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
    required this.onDetail,
  });

  final PurchasePlan plan;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 2 : 0,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.warm : AppColors.borderSoft,
              width: selected ? 1.5 : 1,
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
                      AppTypography.titleSection,
                      AppTypography.bold,
                    ),
                  ),
                  if (plan.recommended) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warm.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '추천',
                        style: AppTypography.weight(
                          AppTypography.caption,
                          AppTypography.bold,
                        ).copyWith(color: AppColors.brand),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: selected ? AppColors.warm : AppColors.stone300,
                    size: 26,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                plan.tagline,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (plan.originalPrice.isNotEmpty) ...[
                    Text(
                      plan.originalPrice,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textTertiary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    plan.price,
                    style: AppTypography.weight(
                      AppTypography.titleSection,
                      AppTypography.bold,
                    ).copyWith(color: AppColors.warm),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                plan.stepCaption,
                style: AppTypography.caption.copyWith(
                  color: AppColors.warm,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              for (final f in plan.features.take(4)) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: AppColors.stone400,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          f,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDetail,
                  child: Text(
                    '자세히',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.brand,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookProcessSection extends StatelessWidget {
  const _BookProcessSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            PurchaseContent.bookProcessTitle,
            style: AppTypography.weight(
              AppTypography.titleSection,
              AppTypography.bold,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < PurchaseContent.bookProcessSteps.length; i++) ...[
            _ProcessStep(
              step: PurchaseContent.bookProcessSteps[i],
              isLast: i == PurchaseContent.bookProcessSteps.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProcessStep extends StatelessWidget {
  const _ProcessStep({required this.step, required this.isLast});

  final ({
    int step,
    String title,
    String duration,
    String body,
    String? warning,
    bool premiumOnly,
  }) step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${step.step}',
                    style: AppTypography.weight(
                      AppTypography.bodySm,
                      AppTypography.bold,
                    ).copyWith(color: AppColors.brandFg),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.stone300,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        step.title,
                        style: AppTypography.weight(
                          AppTypography.bodyBase,
                          AppTypography.bold,
                        ),
                      ),
                      if (step.premiumOnly)
                        const _Pill('프리미엄 전용', AppColors.warm),
                      _Pill(step.duration, AppColors.stone400),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.body,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  if (step.warning != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE8C96A)),
                      ),
                      child: Text(
                        step.warning!,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color == AppColors.warm ? AppColors.brand : color,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _RefundSection extends StatelessWidget {
  const _RefundSection();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(
          PurchaseContent.refundSummaryTitle,
          style: AppTypography.weight(
            AppTypography.bodyBase,
            AppTypography.bold,
          ),
        ),
        children: [
          Text(
            PurchaseContent.refundSummaryBody,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => LegalDocumentView.open('refund_policy'),
              child: Text(
                PurchaseContent.refundFullLabel,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.brand,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductFaqSection extends StatelessWidget {
  const _ProductFaqSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          PurchaseContent.productFaqTitle,
          style: AppTypography.weight(
            AppTypography.bodyBase,
            AppTypography.bold,
          ),
        ),
        const SizedBox(height: 4),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Column(
            children: [
              for (final item in PurchaseContent.productFaqs)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    item.q,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          item.a,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
