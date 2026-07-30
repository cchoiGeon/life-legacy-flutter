import 'package:life_legacy/data/enums/enums.dart';

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
    this.subtitle,
    this.hint,
    this.type = IntroAnswerType.text,
    this.choices = const [],
  });

  final String id;

  /// 1부터. "1 / 5"의 앞 숫자.
  final int order;

  /// "성함을 알려주세요"
  final String text;

  /// 제목 아래 한 줄 — "책 표지에 들어갈 이름이에요".
  ///
  /// **왜 여기까지 묻는지**를 알려주는 자리다. 시니어 사용자가 개인정보를
  /// 왜 주는지 모른 채 넘어가지 않게 시안이 문항마다 붙여 놓았다.
  final String? subtitle;

  /// 입력창 placeholder. [type]이 text일 때만 쓴다.
  final String? hint;

  final IntroAnswerType type;

  /// 고르기 문항의 선택지. 화면은 **세로로 쌓아** 그린다.
  ///
  /// 개수 제한이 없다 — 둘이면 높이 96, 셋 이상이면 74로 줄어든다
  /// (`AppChoiceTile.heightFor`). 예전에는 두 개를 가로로 놓는다고 가정했지만
  /// 학력 문항이 4지선다가 되면서 그 가정을 버렸다.
  final List<String> choices;

  factory IntroQuestion.fromJson(Map<String, dynamic> json) {
    final choices =
        (json['choices'] as List?)?.map((e) => e as String).toList() ??
        const <String>[];
    return IntroQuestion(
      id: json['id'] as String,
      order: json['order'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      hint: json['hint'] as String?,
      // 서버가 type을 안 주면 선택지 유무로 판단한다.
      type: choices.isEmpty ? IntroAnswerType.text : IntroAnswerType.choice,
      choices: choices,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'text': text,
    'subtitle': subtitle,
    'hint': hint,
    'choices': choices,
  };
}

/// 자기소개 답변을 사람이 읽는 형태로 정리한 것 — 시안 F3(내 정보)의
/// "자기소개" 구획.
///
/// 답변 원본(`Map<질문 id, 답>`)을 그대로 보여주면 화면이 서버의 질문 id를
/// 알아야 한다. 그래서 서버가 라벨과 값을 짝지어 내려주는 모양으로 잡았다.
class IntroProfile {
  const IntroProfile({required this.entries});

  /// 순서가 곧 화면 순서다 — 성별 · 결혼 · 자녀 · 학력.
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
  const IntroProfileEntry({required this.label, required this.value});

  /// "성별"
  final String label;

  /// "여성"
  final String value;

  factory IntroProfileEntry.fromJson(Map<String, dynamic> json) =>
      IntroProfileEntry(
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
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
