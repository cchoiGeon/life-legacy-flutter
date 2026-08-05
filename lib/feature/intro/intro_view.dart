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
            subtitle: '알림 여부 맞춰서 드릴게요. 나중에 변경 가능해요.',
            body: _WritingPlanBody(),
            showSkip: false,
          );
        }

        final question = controller.current;
        if (question == null) {
          return const Center(child: Text('질문을 불러오지 못했어요'));
        }

        return _IntroScaffold(
          title: question.text,
          subtitle: question.subtitle,
          body: switch (question.type) {
            IntroAnswerType.choice => _Choices(question: question),
            IntroAnswerType.date => const _DatePickers(),
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

class _Choices extends GetView<IntroController> {
  const _Choices({required this.question});

  final IntroQuestion question;

  @override
  Widget build(BuildContext context) {
    final height = AppChoiceTile.heightFor(question.choices.length);

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

class _DatePickers extends GetView<IntroController> {
  const _DatePickers();

  static final _years = [
    for (var y = DateTime.now().year; y >= 1920; y--) y,
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final maxDay = controller.daysInSelectedMonth();
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: _DropdownInt(
              hint: '연',
              value: controller.birthYear.value,
              items: _years,
              labelOf: (y) => '$y년',
              onChanged: controller.setBirthYear,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DropdownInt(
              hint: '월',
              value: controller.birthMonth.value,
              items: [for (var m = 1; m <= 12; m++) m],
              labelOf: (m) => '$m월',
              onChanged: controller.setBirthMonth,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DropdownInt(
              hint: '일',
              value: controller.birthDay.value,
              items: [for (var d = 1; d <= maxDay; d++) d],
              labelOf: (d) => '$d일',
              onChanged: controller.setBirthDay,
            ),
          ),
        ],
      );
    });
  }
}

class _DropdownInt extends StatelessWidget {
  const _DropdownInt({
    required this.hint,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String hint;
  final int? value;
  final List<int> items;
  final String Function(int) labelOf;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimens.fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value != null && items.contains(value) ? value : null,
          hint: Text(
            hint,
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          items: [
            for (final v in items)
              DropdownMenuItem(value: v, child: Text(labelOf(v))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('하루 가능 시간'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in IntroController.dailyMinuteOptions)
                _Chip(
                  label: _minutesLabel(m),
                  selected: controller.dailyMinutes.value == m,
                  onTap: () => controller.selectDailyMinutes(m),
                ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionLabel('가능 요일'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Chip(
                  label: '평일',
                  selected: controller.weekdayPresetSelected(
                    IntroController.weekdayPreset,
                  ),
                  onTap: () => controller.toggleWeekdayPreset(
                    IntroController.weekdayPreset,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Chip(
                  label: '주말',
                  selected: controller.weekdayPresetSelected(
                    IntroController.weekendPreset,
                  ),
                  onTap: () => controller.toggleWeekdayPreset(
                    IntroController.weekendPreset,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionLabel('시간대'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Chip(
                  label: '오전',
                  selected: controller.availablePeriods.contains('am'),
                  onTap: () => controller.togglePeriod('am'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Chip(
                  label: '오후',
                  selected: controller.availablePeriods.contains('pm'),
                  onTap: () => controller.togglePeriod('pm'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const _SectionLabel('예상 기간'),
          const SizedBox(height: 8),
          Text(
            '평균 2~3주 정도 걸려요. 추천 ${controller.recommendedWeeks.value}주',
            style: AppTypography.caption.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in IntroController.durationWeekOptions)
                _Chip(
                  label: w == controller.recommendedWeeks.value
                      ? '$w주 (추천)'
                      : '$w주',
                  selected: controller.durationWeeks.value == w,
                  onTap: () => controller.selectDurationWeeks(
                    w,
                    recommended: w == controller.recommendedWeeks.value,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  '작성 알림 받기',
                  style: AppTypography.weight(
                    AppTypography.bodyBase,
                    AppTypography.medium,
                  ),
                ),
              ),
              Switch(
                value: controller.alarmEnabled.value,
                onChanged: (v) => controller.alarmEnabled.value = v,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _minutesLabel(int m) => switch (m) {
        10 => '10분',
        30 => '평균 30분',
        60 => '1시간',
        90 => '1시간 반',
        120 => '2시간 이상',
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodyBase.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
