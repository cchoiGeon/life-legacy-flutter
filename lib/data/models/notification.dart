/// 서버 `notification.type` 계약.
abstract final class NotificationType {
  static const dailyQuestion = 'daily_question';
  static const chapterDone = 'chapter_done';
  static const bookReady = 'book_ready';
}

/// 헤더 벨을 눌렀을 때 뜨는 알림 한 건.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.timeLabel,
    this.type = NotificationType.dailyQuestion,
    this.isRead = false,
    this.bookId,
    this.questionId,
    this.chapterId,
  });

  final String id;

  /// daily_question | chapter_done | book_ready
  final String type;

  /// "오늘의 질문이 도착했어요 · 학창 시절과 꿈"
  final String title;

  /// "오늘 오전 9:00" · "어제" 처럼 **서버가 만들어 준 표시용 문자열**.
  ///
  /// ⚠️ 상대 시각을 클라이언트에서 계산하지 않는다. 기기 시계가 틀어져 있으면
  ///    "2시간 전"이 엉뚱하게 나온다. 서버 계약이 정해지면 원본 시각도 함께
  ///    받아 두는 게 좋다.
  final String timeLabel;

  final bool isRead;

  /// 다권 딥링크 — 어느 책으로 갈지.
  final String? bookId;

  /// 작성 화면으로 갈 질문.
  final String? questionId;

  /// 리뷰 화면으로 갈 장.
  final String? chapterId;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    timeLabel: timeLabel,
    isRead: isRead ?? this.isRead,
    bookId: bookId,
    questionId: questionId,
    chapterId: chapterId,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: json['type'] as String? ?? NotificationType.dailyQuestion,
        title: json['title'] as String? ?? '',
        timeLabel: json['time_label'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
        bookId: json['book_id'] as String?,
        questionId: json['question_id'] as String?,
        chapterId: json['chapter_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'time_label': timeLabel,
    'is_read': isRead,
    'book_id': bookId,
    'question_id': questionId,
    'chapter_id': chapterId,
  };
}
