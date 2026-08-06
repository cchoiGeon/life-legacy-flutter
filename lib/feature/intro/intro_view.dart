import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'intro_controller.dart';

/// 자기소개 문항 + 작성 계획 — Figma 인트로 시안.
class IntroView extends GetView<IntroController> {
  const IntroView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppSpinner());
        }

        if (controller.isWritingPlan) {
          return const _IntroScaffold(
            title: '자서전 작성하는 데\n예상 시간은?',
            subtitle: '가능 시간에 맞춰 추천해 드릴게요. 나중에 변경 가능해요.',
            body: _WritingPlanBody(),
            showSkip: false,
          );
        }

        final question = controller.current;
        if (question == null) {
          return const Center(child: Text('질문을 불러오지 못했어요'));
        }

        return _IntroScaffold(
          title: controller.isGenderBirthStep
              ? '성별과 생년월일을\n알려주세요'
              : question.text,
          subtitle: controller.isGenderBirthStep
              ? '책에서 부르는 말과 나이 맞춤 질문에 써요'
              : question.subtitle,
          body: controller.isGenderBirthStep
              ? _GenderBirthBody(question: question)
              : switch (question.type) {
                  IntroAnswerType.choice => _Choices(question: question),
                  IntroAnswerType.date => Obx(
                      () => AppBirthDateField(
                        value: controller.birthDate,
                        onChanged: controller.setBirthDate,
                      ),
                    ),
                  IntroAnswerType.text => _Field(question: question),
                  IntroAnswerType.multiChoice => const SizedBox.shrink(),
                },
          showSkip: question.skippable,
        );
      }),
    );
  }
}

class _IntroScaffold extends GetView<IntroController> {
  const _IntroScaffold({
    required this.title,
    required this.body,
    this.subtitle,
    this.showSkip = false,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final bool showSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTopBar(
          onBack: controller.back,
          trailing: Obx(
            () => Text(controller.stepLabel, style: AppTypography.stepLabel),
          ),
        ),
        Obx(
          () => AppProgressBar(
            value: controller.progress,
            height: 4,
            rounded: false,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutter,
              20,
              AppDimens.gutter,
              AppDimens.space6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppScreenHeading(title: title, subtitle: subtitle),
                const SizedBox(height: 41),
                body,
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimens.gutter,
            0,
            AppDimens.gutter,
            AppInsets.bottom(context, 22),
          ),
          child: Column(
            children: [
              if (showSkip)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextButton(
                    onPressed: controller.skip,
                    child: Text(
                      '건너뛰기',
                      style: AppTypography.bodyBase.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              Obx(
                () => AppButton(
                  label: controller.ctaLabel,
                  size: AppButtonSize.lg,
                  block: true,
                  enabled: controller.canGoNext,
                  loading: controller.isSubmittingPlan.value,
                  onPressed: controller.next,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GenderBirthBody extends GetView<IntroController> {
  const _GenderBirthBody({required this.question});

  final IntroQuestion question;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '성별',
          style: AppTypography.weight(
            AppTypography.bodyBase,
            AppTypography.semibold,
          ),
        ),
        const SizedBox(height: 12),
        _Choices(question: question),
        const SizedBox(height: 28),
        Text(
          '생년월일',
          style: AppTypography.weight(
            AppTypography.bodyBase,
            AppTypography.semibold,
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => AppBirthDateField(
            value: controller.birthDate,
            onChanged: controller.setBirthDate,
          ),
        ),
      ],
    );
  }
}

class _Choices extends GetView<IntroController> {
  const _Choices({required this.question});

  final IntroQuestion question;

  @override
  Widget build(BuildContext context) {
    // 성별+생년월일 합친 화면은 타일을 조금 낮춰 한 화면에 맞춘다.
    final height = controller.isGenderBirthStep
        ? 74.0
        : AppChoiceTile.heightFor(question.choices.length);

    return Obx(() {
      final selected = controller.selectedChoice;
      final details = selected?.details ?? const <IntroChoiceOption>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, choice) in question.choices.indexed) ...[
            if (i > 0) const SizedBox(height: AppChoiceTile.gap),
            AppChoiceTile(
              label: choice.label,
              height: height,
              selected: controller.selected.value == choice.label,
              onTap: () => controller.choose(choice.label),
            ),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              '구체적으로 알려주세요',
              style: AppTypography.weight(
                AppTypography.bodyBase,
                AppTypography.medium,
              ).copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            for (final (i, detail) in details.indexed) ...[
              if (i > 0) const SizedBox(height: AppChoiceTile.gap),
              AppChoiceTile(
                label: detail.label,
                height: AppChoiceTile.heightFor(details.length),
                selected: controller.selectedDetail.value == detail.label,
                onTap: () => controller.chooseDetail(detail.label),
              ),
            ],
          ],
        ],
      );
    });
  }
}

class _Field extends GetView<IntroController> {
  const _Field({required this.question});

  final IntroQuestion question;

  @override
  Widget build(BuildContext context) => AppField(
    controller: controller.answerController,
    hint: question.hint,
    height: AppDimens.fieldHeight,
    autofocus: true,
    textStyle: AppTypography.weight(
      AppTypography.headingXl,
      AppTypography.medium,
    ).copyWith(height: 1.3),
  );
}

class _WritingPlanBody extends GetView<IntroController> {
  const _WritingPlanBody();

  static const _averageMinutes = 30;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('하루 가능 시간'),
          const SizedBox(height: 12),
          _OptionGrid(
            crossAxisCount: 3,
            children: [
              for (final m in IntroController.dailyMinuteOptions)
                _PlanChip(
                  label: _minutesLabel(m),
                  selected: controller.dailyMinutes.value == m,
                  emphasized: m == _averageMinutes,
                  onTap: () => controller.selectDailyMinutes(m),
                ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionLabel('가능 요일'),
          const SizedBox(height: 12),
          _OptionGrid(
            crossAxisCount: 2,
            children: [
              _PlanChip(
                label: '평일',
                selected: controller.weekdayPresetSelected(
                  IntroController.weekdayPreset,
                ),
                onTap: () => controller.toggleWeekdayPreset(
                  IntroController.weekdayPreset,
                ),
              ),
              _PlanChip(
                label: '주말',
                selected: controller.weekdayPresetSelected(
                  IntroController.weekendPreset,
                ),
                onTap: () => controller.toggleWeekdayPreset(
                  IntroController.weekendPreset,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionLabel('시간대'),
          const SizedBox(height: 12),
          _OptionGrid(
            crossAxisCount: 2,
            children: [
              _PlanChip(
                label: '오전',
                selected: controller.availablePeriods.contains('am'),
                onTap: () => controller.togglePeriod('am'),
              ),
              _PlanChip(
                label: '오후',
                selected: controller.availablePeriods.contains('pm'),
                onTap: () => controller.togglePeriod('pm'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionLabel('예상 기간'),
          const SizedBox(height: 8),
          Text(
            '평균 2~3주 정도 걸려요',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          _OptionGrid(
            crossAxisCount: 4,
            children: [
              for (final w in IntroController.durationWeekOptions)
                _PlanChip(
                  label: '$w주',
                  selected: controller.durationWeeks.value == w,
                  emphasized: w == controller.recommendedWeeks.value,
                  onTap: () => controller.selectDurationWeeks(
                    w,
                    recommended: w == controller.recommendedWeeks.value,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _minutesLabel(int m) => switch (m) {
        10 => '10분',
        30 => '30분',
        60 => '1시간',
        90 => '1시간 반',
        120 => '2시간+',
        _ => '$m분',
      };
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.weight(
          AppTypography.bodyBase,
          AppTypography.semibold,
        ),
      );
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.crossAxisCount,
    required this.children,
  });

  final int crossAxisCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: crossAxisCount >= 4 ? 1.7 : 2.4,
      children: children,
    );
  }
}

/// 작은 선택 칩. [emphasized]는 평균·추천 안내용 테두리 하이라이트.
class _PlanChip extends StatelessWidget {
  const _PlanChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final bool selected;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary
        : emphasized
            ? AppColors.warm
            : AppColors.border;
    final borderWidth = selected || emphasized ? 1.5 : 1.0;

    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: emphasized && !selected
                ? [
                    BoxShadow(
                      color: AppColors.warm.withValues(alpha: 0.35),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.weight(
              AppTypography.bodySm,
              selected || emphasized
                  ? AppTypography.semibold
                  : AppTypography.regular,
            ).copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
