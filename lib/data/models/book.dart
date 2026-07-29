/// 책 미리보기의 한 쪽.
class BookPage {
  const BookPage({
    required this.chapterOrder,
    required this.chapterTitle,
    required this.pageNumber,
    required this.paragraphs,
  });

  /// "제 1 장"의 숫자
  final int chapterOrder;
  final String chapterTitle;

  /// 쪽 하단에 "— 12 —"로 찍히는 번호
  final int pageNumber;

  /// 문단 단위. 렌더러가 문단 사이 간격을 준다.
  final List<String> paragraphs;

  factory BookPage.fromJson(Map<String, dynamic> json) => BookPage(
    chapterOrder: json['chapter_order'] as int? ?? 0,
    chapterTitle: json['chapter_title'] as String? ?? '',
    pageNumber: json['page_number'] as int? ?? 0,
    paragraphs:
        (json['paragraphs'] as List?)?.map((e) => e as String).toList() ??
        const [],
  );

  Map<String, dynamic> toJson() => {
    'chapter_order': chapterOrder,
    'chapter_title': chapterTitle,
    'page_number': pageNumber,
    'paragraphs': paragraphs,
  };
}

/// 완성된 책의 요약(시안 21번 화면).
class Book {
  const Book({
    required this.title,
    required this.chapterCount,
    required this.pageCount,
    required this.isComplete,
  });

  /// "영희 님의 인생 이야기"
  final String title;
  final int chapterCount;
  final int pageCount;

  /// 모든 장이 done이면 true. 완성 화면 진입 조건.
  final bool isComplete;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    title: json['title'] as String? ?? '',
    chapterCount: json['chapter_count'] as int? ?? 0,
    pageCount: json['page_count'] as int? ?? 0,
    isComplete: json['is_complete'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'chapter_count': chapterCount,
    'page_count': pageCount,
    'is_complete': isComplete,
  };
}
