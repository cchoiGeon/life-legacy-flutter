/// 책 미리보기의 한 쪽.
class BookPage {
  const BookPage({
    required this.chapterOrder,
    required this.chapterTitle,
    required this.pageNumber,
    required this.totalPages,
    required this.paragraphs,
  });

  /// "제 1 장"의 숫자
  final int chapterOrder;
  final String chapterTitle;

  /// 쪽 하단에 찍히는 번호. 책 전체에서의 쪽수다(장마다 1로 돌아가지 않는다).
  final int pageNumber;

  /// 책 전체 쪽수 — 하단 "12 / 34쪽"의 뒤 숫자.
  ///
  /// 쪽마다 같은 값이 실려 오는 게 낭비로 보이지만, 미리보기 화면이 쪽 하나만
  /// 들고도 "몇 쪽 중 몇 쪽"을 그릴 수 있어야 해서 여기 둔다.
  final int totalPages;

  /// 문단 단위. 렌더러가 문단 사이 간격을 준다.
  final List<String> paragraphs;

  factory BookPage.fromJson(Map<String, dynamic> json) => BookPage(
    chapterOrder: json['chapter_order'] as int? ?? 0,
    chapterTitle: json['chapter_title'] as String? ?? '',
    pageNumber: json['page_number'] as int? ?? 0,
    totalPages: json['total_pages'] as int? ?? 0,
    paragraphs:
        (json['paragraphs'] as List?)?.map((e) => e as String).toList() ??
        const [],
  );

  Map<String, dynamic> toJson() => {
    'chapter_order': chapterOrder,
    'chapter_title': chapterTitle,
    'page_number': pageNumber,
    'total_pages': totalPages,
    'paragraphs': paragraphs,
  };
}

/// 완성된 책의 요약(시안 21번 화면).
class Book {
  const Book({
    required this.title,
    required this.authorName,
    required this.chapterCount,
    required this.questionCount,
    required this.pageCount,
    required this.photoCount,
    required this.isComplete,
  });

  /// 표지 제목 — 시안 352:954는 "나의 이야기"
  final String title;

  /// 표지 아래 이름 — "김영희"
  final String authorName;

  final int chapterCount;

  /// 책에 실린 질문 수 — "5장 · 질문 40개를 모두 답하셨어요"
  final int questionCount;

  final int pageCount;

  /// 책에 실린 사진 수.
  ///
  /// ⚠️ 사진 첨부 흐름(시안 G 섹션)은 아직 만들지 않았다. 지금은 목업이
  ///    고정값을 준다 — G가 들어오면 실제 개수로 바뀐다. 0이면 요약 문구에서
  ///    사진 항목이 빠진다([summary]).
  final int photoCount;

  /// 모든 장이 done이면 true. 완성 화면 진입 조건.
  final bool isComplete;

  /// "전체 34쪽 · 5장 · 사진 12장" (시안 352:961)
  String get summary => [
    '전체 $pageCount쪽',
    '$chapterCount장',
    if (photoCount > 0) '사진 $photoCount장',
  ].join(' · ');

  /// "5장 · 질문 40개를 모두 답하셨어요" (시안 352:951)
  String get completionCaption => '$chapterCount장 · 질문 $questionCount개를 모두 답하셨어요';

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    title: json['title'] as String? ?? '',
    authorName: json['author_name'] as String? ?? '',
    chapterCount: json['chapter_count'] as int? ?? 0,
    questionCount: json['question_count'] as int? ?? 0,
    pageCount: json['page_count'] as int? ?? 0,
    photoCount: json['photo_count'] as int? ?? 0,
    isComplete: json['is_complete'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'author_name': authorName,
    'chapter_count': chapterCount,
    'question_count': questionCount,
    'page_count': pageCount,
    'photo_count': photoCount,
    'is_complete': isComplete,
  };
}
