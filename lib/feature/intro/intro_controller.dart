import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 자기소개 질문 + 작성 계획 — 성함은 가입 이름을 쓰고 i1은 없다.
///
/// 문항 뒤에 작성 계획 단계가 하나 더 있다([isWritingPlan]).
class IntroController extends GetxController {
  IntroController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final answerController = TextEditingController();

  final RxList<IntroQuestion> questions = <IntroQuestion>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSubmittingPlan = false.obs;

  /// 0부터. `questions.length`면 작성 계획 단계.
  final RxInt index = 0.obs;

  final RxString draft = ''.obs;

  /// 고른 선택지(라벨).
  final RxnString selected = RxnString();

  /// 조건부 상세(라벨).
  final RxnString selectedDetail = RxnString();

  final RxnInt birthYear = RxnInt();
  final RxnInt birthMonth = RxnInt();
  final RxnInt birthDay = RxnInt();

  // ── 작성 계획 ─────────────────────────────────────────────
  final RxnInt dailyMinutes = RxnInt();
  final RxList<int> availableWeekdays = <int>[].obs;
  final RxList<String> availablePeriods = <String>[].obs;
  final RxnInt durationWeeks = RxnInt();
  final RxString durationSource = 'recommended'.obs;
  final RxBool alarmEnabled = true.obs;
  final RxInt recommendedWeeks = 2.obs;

  /// questionId → 제출 초안
  final Map<String, IntroAnswerSubmission> answers = {};

  IntroQuestion? get current =>
      index.value < questions.length ? questions[index.value] : null;

  bool get isWritingPlan =>
      !isLoading.value && index.value >= questions.length && questions.isNotEmpty;

  int get step => index.value + 1;
  int get total => questions.isEmpty ? 0 : questions.length + 1;

  String get stepLabel => total == 0 ? '' : '$step / $total';

  double get progress => total == 0 ? 0 : step / total;

  String get ctaLabel => isWritingPlan ? '목차 만들기' : '다음';

  IntroChoiceOption? get selectedChoice {
    final label = selected.value;
    if (label == null || current == null) return null;
    for (final c in current!.choices) {
      if (c.label == label) return c;
    }
    return null;
  }

  static const dailyMinuteOptions = [10, 30, 60, 90, 120];
  static const durationWeekOptions = [1, 2, 4, 6];

  /// UI: 평일 = 월~금(1~5), 주말 = 토·일(6,0) — 서버 계약 0=일~6=토.
  static const weekdayPreset = [1, 2, 3, 4, 5];
  static const weekendPreset = [6, 0];

  @override
  void onInit() {
    super.onInit();
    answerController.addListener(_onDraftChanged);
    load();
  }

  @override
  void onClose() {
    answerController.removeListener(_onDraftChanged);
    answerController.dispose();
    super.onClose();
  }

  void _onDraftChanged() => draft.value = answerController.text;

  Future<void> load() async {
    isLoading.value = true;
    try {
      questions.value = await _api.introQuestions();
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  bool get canGoNext {
    if (isWritingPlan) {
      return dailyMinutes.value != null &&
          availableWeekdays.isNotEmpty &&
          availablePeriods.isNotEmpty &&
          durationWeeks.value != null &&
          !isSubmittingPlan.value;
    }

    final q = current;
    if (q == null) return false;
    return switch (q.type) {
      IntroAnswerType.choice =>
        selected.value != null &&
            (!(selectedChoice?.hasDetails ?? false) ||
                selectedDetail.value != null),
      IntroAnswerType.date =>
        birthYear.value != null &&
            birthMonth.value != null &&
            birthDay.value != null,
      IntroAnswerType.text => draft.value.trim().isNotEmpty,
      IntroAnswerType.multiChoice => false,
    };
  }

  void choose(String label) {
    if (selected.value == label) return;
    selected.value = label;
    selectedDetail.value = null;
  }

  void chooseDetail(String label) => selectedDetail.value = label;

  void setBirthYear(int? y) {
    birthYear.value = y;
    _clampDay();
  }

  void setBirthMonth(int? m) {
    birthMonth.value = m;
    _clampDay();
  }

  void setBirthDay(int? d) => birthDay.value = d;

  void _clampDay() {
    final y = birthYear.value;
    final m = birthMonth.value;
    final d = birthDay.value;
    if (y == null || m == null || d == null) return;
    final max = DateTime(y, m + 1, 0).day;
    if (d > max) birthDay.value = max;
  }

  int daysInSelectedMonth() {
    final y = birthYear.value ?? 2000;
    final m = birthMonth.value ?? 1;
    return DateTime(y, m + 1, 0).day;
  }

  void toggleWeekdayPreset(List<int> preset) {
    final allOn = preset.every(availableWeekdays.contains);
    if (allOn) {
      availableWeekdays.removeWhere(preset.contains);
    } else {
      for (final d in preset) {
        if (!availableWeekdays.contains(d)) availableWeekdays.add(d);
      }
    }
    availableWeekdays.refresh();
    _refreshRecommended();
  }

  bool weekdayPresetSelected(List<int> preset) =>
      preset.every(availableWeekdays.contains);

  void togglePeriod(String period) {
    if (availablePeriods.contains(period)) {
      availablePeriods.remove(period);
    } else {
      availablePeriods.add(period);
    }
    availablePeriods.refresh();
  }

  void selectDailyMinutes(int minutes) {
    dailyMinutes.value = minutes;
    _refreshRecommended();
  }

  void selectDurationWeeks(int weeks, {required bool recommended}) {
    durationWeeks.value = weeks;
    durationSource.value = recommended ? 'recommended' : 'manual';
  }

  void _refreshRecommended() {
    final minutes = dailyMinutes.value ?? 30;
    final days = availableWeekdays.isEmpty ? 3 : availableWeekdays.length;
    final rec = () {
      if (minutes >= 90 && days >= 4) return 1;
      if (minutes >= 60) return 2;
      if (minutes >= 30) return 4;
      return 6;
    }();
    recommendedWeeks.value = rec;
    if (durationSource.value == 'recommended' || durationWeeks.value == null) {
      durationWeeks.value = rec;
      durationSource.value = 'recommended';
    }
  }

  /// 건너뛰기 — 결혼·자녀만.
  void skip() {
    final q = current;
    if (q == null || !q.skippable) return;
    answers[q.id] = IntroAnswerSubmission(questionId: q.id, skipped: true);
    _advance();
  }

  void next() {
    if (isWritingPlan) {
      _submitWritingPlanAndToc();
      return;
    }

    final q = current;
    if (q == null || !canGoNext) return;

    answers[q.id] = switch (q.type) {
      IntroAnswerType.choice => IntroAnswerSubmission(
          questionId: q.id,
          value: selected.value,
          choiceId: selectedChoice?.id,
          detailValue: selectedDetail.value,
          detailChoiceId: selectedChoice?.details
              .where((d) => d.label == selectedDetail.value)
              .map((d) => d.id)
              .firstOrNull,
        ),
      IntroAnswerType.date => IntroAnswerSubmission(
          questionId: q.id,
          value:
              '${birthYear.value!.toString().padLeft(4, '0')}-'
              '${birthMonth.value!.toString().padLeft(2, '0')}-'
              '${birthDay.value!.toString().padLeft(2, '0')}',
        ),
      IntroAnswerType.text => IntroAnswerSubmission(
          questionId: q.id,
          value: answerController.text.trim(),
        ),
      IntroAnswerType.multiChoice => IntroAnswerSubmission(
          questionId: q.id,
          skipped: true,
        ),
    };

    _advance();
  }

  void _advance() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index.value + 1 > questions.length) return;
    index.value++;
    if (isWritingPlan) {
      _enterWritingPlan();
    } else {
      _restore();
    }
  }

  Future<void> _enterWritingPlan() async {
    try {
      final result = await _api.writingPlan();
      recommendedWeeks.value = result.recommendedWeeks;
      final plan = result.plan;
      if (plan != null) {
        dailyMinutes.value = plan.dailyMinutes;
        availableWeekdays
          ..clear()
          ..addAll(plan.availableWeekdays);
        availablePeriods
          ..clear()
          ..addAll(plan.availablePeriods);
        durationWeeks.value = plan.durationWeeks;
        durationSource.value = plan.durationSource;
        alarmEnabled.value = plan.alarmEnabled;
      } else {
        durationWeeks.value = result.recommendedWeeks;
        durationSource.value = 'recommended';
      }
    } on ApiException {
      durationWeeks.value = recommendedWeeks.value;
      durationSource.value = 'recommended';
    }
  }

  Future<void> _submitWritingPlanAndToc() async {
    if (!canGoNext || isSubmittingPlan.value) return;
    isSubmittingPlan.value = true;
    try {
      final plan = WritingPlan(
        dailyMinutes: dailyMinutes.value!,
        availableWeekdays: List.of(availableWeekdays),
        availablePeriods: List.of(availablePeriods),
        durationWeeks: durationWeeks.value!,
        durationSource: durationSource.value,
        alarmEnabled: alarmEnabled.value,
      );
      await _api.updateWritingPlan(plan);
      Get.offNamed(
        AppRoutes.tocLoading,
        arguments: answers.values.toList(),
      );
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isSubmittingPlan.value = false;
    }
  }

  void back() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (index.value == 0) {
      Get.back();
      return;
    }
    index.value--;
    if (index.value < questions.length) {
      _restore();
    }
  }

  void _restore() {
    final q = current;
    selected.value = null;
    selectedDetail.value = null;
    birthYear.value = null;
    birthMonth.value = null;
    birthDay.value = null;
    answerController.clear();

    final saved = q == null ? null : answers[q.id];
    if (q == null || saved == null || saved.skipped) return;

    switch (q.type) {
      case IntroAnswerType.choice:
        selected.value = saved.value;
        selectedDetail.value = saved.detailValue;
      case IntroAnswerType.date:
        final parts = (saved.value ?? '').split('-');
        if (parts.length == 3) {
          birthYear.value = int.tryParse(parts[0]);
          birthMonth.value = int.tryParse(parts[1]);
          birthDay.value = int.tryParse(parts[2]);
        }
      case IntroAnswerType.text:
        answerController.text = saved.value ?? '';
      case IntroAnswerType.multiChoice:
        break;
    }
  }
}
