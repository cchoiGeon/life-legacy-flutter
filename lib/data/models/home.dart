import 'package:life_legacy/data/enums/enums.dart';

/// 홈 대시보드가 한 번에 받아오는 요약(시안 11번 화면).
///
/// 화면 하나가 필요한 값을 한 번에 준다는 가정이다. 서버가 쪼개서 준다면
/// MockApiClient 자리에 들어갈 실제 구현이 여러 호출을 합쳐 이 모양으로
/// 맞춰주면 된다 — 화면은 그대로 둔다.
class HomeSummary {
  const HomeSummary({
    this.bookId,
    required this.todayQuestion,
    required this.todayQuestionId,
    required this.progress,
    required this.chapterDone,
    required this.chapterTotal,
    required this.remainingQuestions,
  });

  final String? bookId;

  /// "첫 월급을 받던 날, 기분이 어떠셨나요?"
  /// 아직 시작한 이야기가 없으면 null → 빈 상태 화면(시안 12번).
  final String? todayQuestion;

  /// 이어서 이야기하기가 향할 질문 id
  final String? todayQuestionId;

  /// 0.0 ~ 1.0 — "내 자서전 진행 42%"
  final double progress;

  final int chapterDone;
  final int chapterTotal;
  final int remainingQuestions;

  bool get isEmpty => todayQuestion == null;

  /// "5장 중 2장 완성 · 남은 질문 12개"
  String get progressCaption =>
      '$chapterTotal장 중 $chapterDone장 완성 · 남은 질문 $remainingQuestions개';

  factory HomeSummary.fromJson(Map<String, dynamic> json) => HomeSummary(
    bookId: json['book_id'] as String?,
    todayQuestion: json['today_question'] as String?,
    todayQuestionId: json['today_question_id'] as String?,
    progress: (json['progress'] as num?)?.toDouble() ?? 0,
    chapterDone: json['chapter_done'] as int? ?? 0,
    chapterTotal: json['chapter_total'] as int? ?? 0,
    remainingQuestions: json['remaining_questions'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'book_id': bookId,
    'today_question': todayQuestion,
    'today_question_id': todayQuestionId,
    'progress': progress,
    'chapter_done': chapterDone,
    'chapter_total': chapterTotal,
    'remaining_questions': remainingQuestions,
  };
}

/// 자기소개 단계의 질문.
class IntroQuestion {
  const IntroQuestion({
    required this.id,
    required this.order,
    required this.text,
    this.subtitle,
    this.hint,
    this.type = IntroAnswerType.text,
    this.skippable = false,
    this.choices = const [],
  });

  final String id;
  final int order;
  final String text;
  final String? subtitle;
  final String? hint;
  final IntroAnswerType type;
  final bool skippable;
  final List<IntroChoiceOption> choices;

  factory IntroQuestion.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'] as List? ?? const [];
    final choices = rawChoices.map((e) {
      if (e is String) {
        return IntroChoiceOption(id: e, label: e);
      }
      return IntroChoiceOption.fromJson(e as Map<String, dynamic>);
    }).toList();

    final typeWire = json['answer_type'] as String?;
    return IntroQuestion(
      id: json['id'] as String,
      order: json['order'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      hint: json['hint'] as String?,
      type: typeWire != null
          ? IntroAnswerType.fromWire(typeWire)
          : (choices.isEmpty ? IntroAnswerType.text : IntroAnswerType.choice),
      skippable: json['skippable'] as bool? ?? false,
      choices: choices,
    );
  }
}

class IntroChoiceOption {
  const IntroChoiceOption({
    required this.id,
    required this.label,
    this.details = const [],
  });

  final String id;
  final String label;
  final List<IntroChoiceOption> details;

  bool get hasDetails => details.isNotEmpty;

  factory IntroChoiceOption.fromJson(Map<String, dynamic> json) =>
      IntroChoiceOption(
        id: json['id'] as String? ?? json['label'] as String? ?? '',
        label: json['label'] as String? ?? '',
        details: (json['details'] as List?)
                ?.map(
                  (e) => IntroChoiceOption.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      );
}

/// 자기소개 제출 한 문항.
class IntroAnswerSubmission {
  const IntroAnswerSubmission({
    required this.questionId,
    this.value,
    this.choiceId,
    this.detailChoiceId,
    this.detailValue,
    this.skipped = false,
  });

  final String questionId;
  final String? value;
  final String? choiceId;
  final String? detailChoiceId;
  final String? detailValue;
  final bool skipped;

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    if (skipped) 'skipped': true,
    if (!skipped && value != null) 'value': value,
    if (choiceId != null) 'choice_id': choiceId,
    if (detailChoiceId != null) 'detail_choice_id': detailChoiceId,
    if (detailValue != null) 'detail_value': detailValue,
  };
}

/// 작성 계획.
class WritingPlan {
  const WritingPlan({
    required this.dailyMinutes,
    required this.availableWeekdays,
    required this.availablePeriods,
    required this.durationWeeks,
    required this.durationSource,
    required this.alarmEnabled,
  });

  final int dailyMinutes;
  final List<int> availableWeekdays;
  final List<String> availablePeriods;
  final int durationWeeks;
  final String durationSource;
  final bool alarmEnabled;

  Map<String, dynamic> toJson() => {
    'daily_minutes': dailyMinutes,
    'available_weekdays': availableWeekdays,
    'available_periods': availablePeriods,
    'duration_weeks': durationWeeks,
    'duration_source': durationSource,
    'alarm_enabled': alarmEnabled,
  };

  factory WritingPlan.fromJson(Map<String, dynamic> json) => WritingPlan(
    dailyMinutes: json['daily_minutes'] as int? ?? 30,
    availableWeekdays: (json['available_weekdays'] as List?)
            ?.map((e) => e as int)
            .toList() ??
        const [],
    availablePeriods: (json['available_periods'] as List?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    durationWeeks: json['duration_weeks'] as int? ?? 2,
    durationSource: json['duration_source'] as String? ?? 'recommended',
    alarmEnabled: json['alarm_enabled'] as bool? ?? true,
  );
}

class WritingPlanResult {
  const WritingPlanResult({
    required this.recommendedWeeks,
    this.plan,
  });

  final int recommendedWeeks;
  final WritingPlan? plan;

  factory WritingPlanResult.fromJson(Map<String, dynamic> json) =>
      WritingPlanResult(
        recommendedWeeks: json['recommended_weeks'] as int? ?? 2,
        plan: json['plan'] != null
            ? WritingPlan.fromJson(json['plan'] as Map<String, dynamic>)
            : null,
      );
}

/// 자기소개 답변을 사람이 읽는 형태로 정리한 것 — 시안 F3(내 정보)의
/// "자기소개" 구획.
class IntroProfile {
  const IntroProfile({required this.entries});

  final List<IntroProfileEntry> entries;

  factory IntroProfile.fromJson(Map<String, dynamic> json) => IntroProfile(
    entries:
        (json['entries'] as List?)
            ?.map((e) => IntroProfileEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  Map<String, dynamic> toJson() => {
    'entries': [for (final e in entries) e.toJson()],
  };
}

class IntroProfileEntry {
  const IntroProfileEntry({
    required this.label,
    this.value,
    this.skipped = false,
  });

  final String label;
  final String? value;
  final bool skipped;

  factory IntroProfileEntry.fromJson(Map<String, dynamic> json) =>
      IntroProfileEntry(
        label: json['label'] as String? ?? '',
        value: json['value'] as String?,
        skipped: json['skipped'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'label': label,
    'value': value,
    'skipped': skipped,
  };
}

/// 인쇄본 배송지 — 시안 F3(보기) · F4(수정).
class Address {
  const Address({
    required this.recipient,
    required this.phone,
    required this.postalCode,
    required this.line1,
    required this.line2,
  });

  /// 받는 분
  final String recipient;

  /// 연락처 (숫자만)
  final String phone;

  /// 우편번호 "03186"
  final String postalCode;

  /// 기본 주소 "서울 종로구 세종대로 175"
  final String line1;

  /// 상세 주소 "302동 1201호"
  final String line2;

  /// 01012345678 → "010 1234 5678".
  ///
  /// 저장은 숫자만 하고 **보여줄 때만** 띄운다. 설정·내 정보·배송지 세 화면이
  /// 같은 모양이어야 해서 여기 한 곳에 뒀다.
  static String formatPhone(String digits) {
    if (digits.length != 11) return digits;
    return '${digits.substring(0, 3)} ${digits.substring(3, 7)} '
        '${digits.substring(7)}';
  }

  /// 다섯 칸이 다 차야 인쇄본을 보낼 수 있다.
  bool get isComplete =>
      recipient.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      postalCode.trim().isNotEmpty &&
      line1.trim().isNotEmpty;

  /// F3에 한 줄로 뜨는 형태 — "서울 종로구 세종대로 175 302동 1201호 (03186)"
  String get oneLine {
    final parts = [line1, line2].where((e) => e.trim().isNotEmpty);
    final body = parts.join(' ');
    return postalCode.trim().isEmpty ? body : '$body ($postalCode)';
  }

  Address copyWith({
    String? recipient,
    String? phone,
    String? postalCode,
    String? line1,
    String? line2,
  }) => Address(
    recipient: recipient ?? this.recipient,
    phone: phone ?? this.phone,
    postalCode: postalCode ?? this.postalCode,
    line1: line1 ?? this.line1,
    line2: line2 ?? this.line2,
  );

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    recipient: json['recipient'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    postalCode: json['postal_code'] as String? ?? '',
    line1: json['line1'] as String? ?? '',
    line2: json['line2'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'recipient': recipient,
    'phone': phone,
    'postal_code': postalCode,
    'line1': line1,
    'line2': line2,
  };
}

/// 앱 설정(시안 22번).
///
/// 지금 켜고 끌 수 있는 건 "오늘의 질문 알림" 하나뿐이다.
class AppSettings {
  const AppSettings({required this.dailyQuestionAlarm});

  final bool dailyQuestionAlarm;

  AppSettings copyWith({bool? dailyQuestionAlarm}) => AppSettings(
    dailyQuestionAlarm: dailyQuestionAlarm ?? this.dailyQuestionAlarm,
  );

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    dailyQuestionAlarm: json['daily_question_alarm'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {'daily_question_alarm': dailyQuestionAlarm};
}
