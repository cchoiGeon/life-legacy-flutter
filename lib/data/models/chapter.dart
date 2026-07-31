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
    this.nextQuestionText,
  });

  final String id;

  /// 1부터 시작. "제1장 · 어린 시절"의 숫자.
  final int order;

  /// "어린 시절"
  final String title;

  final ChapterStatus status;

  /// 답변을 마친 질문 수
  final int answeredCount;

  /// 이 장의 전체 질문 수
  final int questionCount;

  /// 다음에 답할 질문 — 자서전 목록(E1)에 "다음 질문 · 첫 소풍의 기억"으로
  /// 뜬다. 진행 중인 장에만 있다.
  final String? nextQuestionText;

  /// 0.0 ~ 1.0
  double get progress => questionCount == 0 ? 0 : answeredCount / questionCount;

  /// 자서전 목록(E1 341:682)의 보조 문구.
  ///
  /// 진행 중인 장은 남은 개수가 아니라 **다음 질문 제목**을 보여준다 —
  /// "3/8"은 이미 오른쪽에 있고, 여기서는 "무엇을 물어볼지" 알려줘야
  /// 이어서 쓰고 싶어진다.
  String get subtitle => switch (status) {
    ChapterStatus.done => '질문 $questionCount개 모두 답했어요',
    ChapterStatus.writing =>
      nextQuestionText == null ? '이어서 쓸 수 있어요' : '다음 질문 · $nextQuestionText',
    ChapterStatus.locked => '${order - 1}장을 마치면 열려요',
  };

  /// 목록 오른쪽 상태 글자. 잠긴 장은 아무것도 쓰지 않는다.
  String? get statusLabel => switch (status) {
    ChapterStatus.done => '완료',
    ChapterStatus.writing =>
      answeredCount == 0 ? '시작하기' : '$answeredCount/$questionCount',
    ChapterStatus.locked => null,
  };

  Chapter copyWith({
    ChapterStatus? status,
    int? answeredCount,
    String? title,
    String? nextQuestionText,
  }) => Chapter(
    id: id,
    order: order,
    title: title ?? this.title,
    status: status ?? this.status,
    answeredCount: answeredCount ?? this.answeredCount,
    questionCount: questionCount,
    nextQuestionText: nextQuestionText ?? this.nextQuestionText,
  );

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    id: json['id'] as String,
    order: json['order'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    status: ChapterStatus.fromWire(json['status'] as String?),
    answeredCount: json['answered_count'] as int? ?? 0,
    questionCount: json['question_count'] as int? ?? 0,
    nextQuestionText: json['next_question_text'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'title': title,
    'status': status.wire,
    'answered_count': answeredCount,
    'question_count': questionCount,
    'next_question_text': nextQuestionText,
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

/// 1차 답변을 보고 AI가 되물어 오는 질문. 질문 하나당 **한 번**이다.
///
/// [text]는 요약 + 공감 + 질문이 한 덩어리로 온다 —
/// "제주도 이야기를 꺼내시니 … 가장 오래 머문 곳은 어디였나요?"
/// 그래서 원래 질문보다 서너 배 길고, 화면이 스크롤을 열어 둔다.
class Followup {
  const Followup({required this.id, required this.text});

  /// 꼬리답변을 보낼 때 경로에 실린다.
  final String id;

  final String text;

  factory Followup.fromJson(Map<String, dynamic> json) => Followup(
    id: json['id'] as String,
    text: json['text'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}
