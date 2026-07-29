/// 홈 대시보드가 한 번에 받아오는 요약(시안 11번 화면).
///
/// 화면 하나가 필요한 값을 한 번에 준다는 가정이다. 서버가 쪼개서 준다면
/// MockApiClient 자리에 들어갈 실제 구현이 여러 호출을 합쳐 이 모양으로
/// 맞춰주면 된다 — 화면은 그대로 둔다.
class HomeSummary {
  const HomeSummary({
    required this.todayQuestion,
    required this.todayQuestionId,
    required this.progress,
    required this.chapterDone,
    required this.chapterTotal,
    required this.remainingQuestions,
  });

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
    todayQuestion: json['today_question'] as String?,
    todayQuestionId: json['today_question_id'] as String?,
    progress: (json['progress'] as num?)?.toDouble() ?? 0,
    chapterDone: json['chapter_done'] as int? ?? 0,
    chapterTotal: json['chapter_total'] as int? ?? 0,
    remainingQuestions: json['remaining_questions'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'today_question': todayQuestion,
    'today_question_id': todayQuestionId,
    'progress': progress,
    'chapter_done': chapterDone,
    'chapter_total': chapterTotal,
    'remaining_questions': remainingQuestions,
  };
}

/// 자기소개 단계의 질문(시안 07·08번). 목차를 만들기 위한 사전 질문 5개.
class IntroQuestion {
  const IntroQuestion({
    required this.id,
    required this.order,
    required this.text,
    this.hint,
  });

  final String id;

  /// 1부터. "1 / 5"의 앞 숫자.
  final int order;

  /// "성함이 어떻게 되세요?"
  final String text;

  /// 입력창 placeholder
  final String? hint;

  factory IntroQuestion.fromJson(Map<String, dynamic> json) => IntroQuestion(
    id: json['id'] as String,
    order: json['order'] as int? ?? 0,
    text: json['text'] as String? ?? '',
    hint: json['hint'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'text': text,
    'hint': hint,
  };
}

/// 앱 설정(시안 22번).
class AppSettings {
  const AppSettings({
    required this.dailyQuestionAlarm,
    required this.newsAlarm,
  });

  final bool dailyQuestionAlarm;
  final bool newsAlarm;

  AppSettings copyWith({bool? dailyQuestionAlarm, bool? newsAlarm}) =>
      AppSettings(
        dailyQuestionAlarm: dailyQuestionAlarm ?? this.dailyQuestionAlarm,
        newsAlarm: newsAlarm ?? this.newsAlarm,
      );

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    dailyQuestionAlarm: json['daily_question_alarm'] as bool? ?? true,
    newsAlarm: json['news_alarm'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'daily_question_alarm': dailyQuestionAlarm,
    'news_alarm': newsAlarm,
  };
}
