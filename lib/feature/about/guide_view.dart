import 'package:flutter/material.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import 'guide_content.dart';

/// 사용설명서 — 랜딩·메뉴에서 진입.
class GuideView extends StatelessWidget {
  const GuideView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(title: '사용설명서'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutter,
                8,
                AppDimens.gutter,
                AppDimens.space8,
              ),
              children: [
                Text(GuideContent.title, style: AppTypography.titlePage),
                const SizedBox(height: 8),
                Text(
                  GuideContent.subtitle,
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  GuideContent.intro,
                  style: AppTypography.bodyBase.copyWith(height: 1.55),
                ),
                const AppSettingSection('전체 흐름'),
                for (final s in GuideContent.flowSteps) ...[
                  _StepCard(
                    step: s.step,
                    title: s.title,
                    body: s.description,
                  ),
                  const SizedBox(height: 10),
                ],
                const AppSettingSection('화면별 안내'),
                for (final sec in GuideContent.sections) ...[
                  _SectionCard(
                    title: sec.title,
                    summary: sec.summary,
                    bullets: sec.bullets,
                  ),
                  const SizedBox(height: 10),
                ],
                const AppSettingSection('도움말'),
                for (final tip in GuideContent.tips) ...[
                  _TipCard(title: tip.title, body: tip.body),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.body,
  });

  final int step;
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$step',
            style: AppTypography.weight(
              AppTypography.titleSection,
              AppTypography.bold,
            ).copyWith(color: AppColors.brand),
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
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.summary,
    required this.bullets,
  });

  final String title;
  final String summary;
  final List<String> bullets;

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
          const SizedBox(height: 4),
          Text(
            summary,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '· ',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.brand,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: AppTypography.bodySm.copyWith(height: 1.4),
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

class _TipCard extends StatelessWidget {
  const _TipCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
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
          Text(body, style: AppTypography.bodySm.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}
