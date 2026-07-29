import 'package:life_legacy/data/enums/enums.dart';

/// 자서전의 장(章).
class Chapter {
  const Chapter({
    required this.id,
    required this.order,
    required this.title,
    required this.status,
    required this.answeredCount,
    required this.questionCount,
  });

  final String id;

  /// 1부터 시작. "제1장 · 어린 시절"의 숫자.
  final int order;

  /// "안동에서의 어린 시절"
  final String title;

  final ChapterStatus status;

  /// 답변을 마친 질문 수
  final int answeredCount;

  /// 이 장의 전체 질문 수
  final int questionCount;

  /// 0.0 ~ 1.0
  double get progress => questionCount == 0 ? 0 : answeredCount / questionCount;

  /// 목록에 뜨는 보조 문구. 상태마다 다른 문장을 쓴다(시안 19번 화면).
  String get subtitle => switch (status) {
    ChapterStatus.done => '완성 · $questionCount개 질문 답변 완료',
    ChapterStatus.writing => '작성 중 · $answeredCount / $questionCount 질문',
    ChapterStatus.locked => '아직 잠겨 있어요',
  };

  Chapter copyWith({
    ChapterStatus? status,
    int? answeredCount,
    String? title,
  }) => Chapter(
    id: id,
    order: order,
    title: title ?? this.title,
    status: status ?? this.status,
    answeredCount: answeredCount ?? this.answeredCount,
    questionCount: questionCount,
  );

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    id: json['id'] as String,
    order: json['order'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    status: ChapterStatus.fromWire(json['status'] as String?),
    answeredCount: json['answered_count'] as int? ?? 0,
    questionCount: json['question_count'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'title': title,
    'status': status.wire,
    'answered_count': answeredCount,
    'question_count': questionCount,
  };
}

/// 장 안의 질문 하나.
class Question {
  const Question({
    required this.id,
    required this.chapterId,
    required this.order,
    required this.text,
    this.answer,
  });

  final String id;
  final String chapterId;

  /// 장 안에서의 순번(1부터). "질문 3 / 6"의 앞 숫자.
  final int order;

  /// "어린 시절 살던 동네는 어떤 모습이었나요?"
  final String text;

  /// 확정 저장된 답변. 아직 안 했으면 null.
  final String? answer;

  bool get isAnswered => answer != null;

  Question copyWith({String? answer}) => Question(
    id: id,
    chapterId: chapterId,
    order: order,
    text: text,
    answer: answer ?? this.answer,
  );

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] as String,
    chapterId: json['chapter_id'] as String? ?? '',
    order: json['order'] as int? ?? 0,
    text: json['text'] as String? ?? '',
    answer: json['answer'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'chapter_id': chapterId,
    'order': order,
    'text': text,
    'answer': answer,
  };
}
