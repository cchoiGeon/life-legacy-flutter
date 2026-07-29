/// 헤더 벨을 눌렀을 때 뜨는 알림 한 건.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.timeLabel,
    this.isRead = false,
  });

  final String id;

  /// "오늘의 질문이 도착했어요 · 학창 시절과 꿈"
  final String title;

  /// "오늘 오전 9:00" · "어제" 처럼 **서버가 만들어 준 표시용 문자열**.
  ///
  /// ⚠️ 상대 시각을 클라이언트에서 계산하지 않는다. 기기 시계가 틀어져 있으면
  ///    "2시간 전"이 엉뚱하게 나온다. 서버 계약이 정해지면 원본 시각도 함께
  ///    받아 두는 게 좋다.
  final String timeLabel;

  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    timeLabel: timeLabel,
    isRead: isRead ?? this.isRead,
  );

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        timeLabel: json['time_label'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'time_label': timeLabel,
    'is_read': isRead,
  };
}
