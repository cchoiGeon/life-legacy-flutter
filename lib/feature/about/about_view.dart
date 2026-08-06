import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/feature/about/about_content.dart';
import 'package:life_legacy/feature/purchase/purchase_flow.dart';

/// 소개 — 랜딩·메뉴에서 진입.
class AboutView extends StatelessWidget {
  const AboutView({super.key});

  Future<void> _openWebsite(BuildContext context) async {
    await PurchaseFlow.openWebsiteForPurchase(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(title: '소개'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutter,
                8,
                AppDimens.gutter,
                AppDimens.space8,
              ),
              children: [
                const AppBrandMark(size: 56),
                const SizedBox(height: 16),
                const Center(
                  child: AppWordmark(fontSize: 28, letterSpacing: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  AboutContent.subtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.brandTagline.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Text(
                  AboutContent.intro,
                  style: AppTypography.bodyBase.copyWith(height: 1.55),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F4A3A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    AboutContent.freeTrialNote,
                    style: AppTypography.weight(
                      AppTypography.bodyBase,
                      AppTypography.bold,
                    ).copyWith(color: Colors.white, height: 1.4),
                  ),
                ),
                const AppSettingSection('이런 점이 좋아요'),
                for (final f in AboutContent.features) ...[
                  _InfoCard(title: f.title, body: f.description),
                  const SizedBox(height: 10),
                ],
                const AppSettingSection('사용 방법'),
                for (final s in AboutContent.howItWorks) ...[
                  _StepRow(
                    step: s.step,
                    title: s.title,
                    body: s.description,
                  ),
                  const SizedBox(height: 10),
                ],
                const AppSettingSection('실제 후기'),
                Text(
                  AboutContent.reviewsIntro,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                const _ScoreCard(),
                const SizedBox(height: 12),
                for (final quote in AboutContent.reviews) ...[
                  _ReviewCard(quote: quote),
                  const SizedBox(height: 10),
                ],
                const AppSettingSection('요금제'),
                Text(
                  AboutContent.pricingIntro,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                for (final plan in AboutContent.plans) ...[
                  _PlanCard(
                    name: plan.name,
                    description: plan.description,
                    price: plan.price,
                    originalPrice: plan.originalPrice,
                    recommended: plan.recommended,
                    onTap: plan.code == 'FREE'
                        ? null
                        : () => PurchaseFlow.openPlan(plan.code),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  AboutContent.pricingNote,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textTertiary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: '플랜 구매 안내',
                  onPressed: () => PurchaseFlow.openList(),
                  variant: AppButtonVariant.outline,
                  block: true,
                ),
                const AppSettingSection('개인정보 보호'),
                for (final p in AboutContent.privacyPrinciples) ...[
                  _InfoCard(title: p.title, body: p.body),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 12),
                AppButton(
                  label: '웹페이지 이동하기',
                  onPressed: () => _openWebsite(context),
                  variant: AppButtonVariant.primary,
                  block: true,
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: AppColors.brandFg,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: GestureDetector(
                    onTap: () => _openWebsite(context),
                    child: Text(
                      AboutContent.websiteLabel,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.brand,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.brand,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: '사용설명서 보기',
                  onPressed: () => Get.toNamed(AppRoutes.guide),
                  variant: AppButtonVariant.outline,
                  block: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '${AboutContent.reviewsScore} / ${AboutContent.reviewsScoreMax}',
            style: AppTypography.weight(
              AppTypography.titleSection,
              AppTypography.bold,
            ).copyWith(color: AppColors.brand, fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text(
            AboutContent.reviewsScoreLabel,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“',
            style: AppTypography.weight(
              AppTypography.titleSection,
              AppTypography.bold,
            ).copyWith(color: AppColors.warm, fontSize: 28, height: 1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              quote,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.recommended = false,
    this.onTap,
  });

  final String name;
  final String description;
  final String price;
  final String? originalPrice;
  final bool recommended;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recommended ? AppColors.cream : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: recommended ? AppColors.brand : AppColors.borderSoft,
          width: recommended ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: AppTypography.weight(
                  AppTypography.bodyBase,
                  AppTypography.bold,
                ),
              ),
              if (recommended) ...[
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
              if (onTap != null) ...[
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
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
                price,
                style: AppTypography.weight(
                  AppTypography.titleSection,
                  AppTypography.bold,
                ).copyWith(color: AppColors.brand),
              ),
              if (originalPrice != null) ...[
                const SizedBox(width: 8),
                Text(
                  originalPrice!,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textTertiary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: card,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.weight(
              AppTypography.bodyBase,
              AppTypography.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.title,
    required this.body,
  });

  final int step;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.brand,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$step',
            style: AppTypography.weight(
              AppTypography.bodySm,
              AppTypography.bold,
            ).copyWith(color: AppColors.brandFg),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.weight(
                  AppTypography.bodyBase,
                  AppTypography.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
