/// FAQ · QnA 지원 모델.
class FaqCatalog {
  const FaqCatalog({required this.categories, required this.sections});

  final List<FaqCategory> categories;
  final List<FaqSection> sections;

  factory FaqCatalog.fromJson(Map<String, dynamic> json) => FaqCatalog(
    categories: ((json['categories'] as List?) ?? const [])
        .map((e) => FaqCategory.fromJson(e as Map<String, dynamic>))
        .toList(),
    sections: ((json['sections'] as List?) ?? const [])
        .map((e) => FaqSection.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class FaqCategory {
  const FaqCategory({required this.id, required this.label});

  final String id;
  final String label;

  factory FaqCategory.fromJson(Map<String, dynamic> json) => FaqCategory(
    id: json['id'] as String,
    label: json['label'] as String,
  );
}

class FaqSection {
  const FaqSection({
    required this.id,
    required this.label,
    required this.items,
  });

  final String id;
  final String label;
  final List<FaqItem> items;

  factory FaqSection.fromJson(Map<String, dynamic> json) => FaqSection(
    id: json['id'] as String,
    label: json['label'] as String,
    items: ((json['items'] as List?) ?? const [])
        .map((e) => FaqItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;

  factory FaqItem.fromJson(Map<String, dynamic> json) => FaqItem(
    question: json['question'] as String,
    answer: json['answer'] as String,
  );
}

class QnaItem {
  const QnaItem({
    required this.id,
    this.category,
    required this.question,
    required this.status,
    this.answer,
    this.answeredAt,
    required this.createdAt,
  });

  final String id;
  final String? category;
  final String question;
  final String status;
  final String? answer;
  final String? answeredAt;
  final String createdAt;

  String get statusLabel => switch (status) {
    'pending' => '대기',
    'answered' => '답변됨',
    'published' => '게시됨',
    'closed' => '종료',
    _ => status,
  };

  factory QnaItem.fromJson(Map<String, dynamic> json) => QnaItem(
    id: json['id'] as String,
    category: json['category'] as String?,
    question: json['question'] as String,
    status: json['status'] as String? ?? 'pending',
    answer: json['answer'] as String?,
    answeredAt: json['answered_at'] as String?,
    createdAt: json['created_at'] as String? ?? '',
  );
}

class PublishedQna {
  const PublishedQna({
    required this.id,
    this.category,
    required this.question,
    required this.answer,
    this.publishedAt,
  });

  final String id;
  final String? category;
  final String question;
  final String answer;
  final String? publishedAt;

  factory PublishedQna.fromJson(Map<String, dynamic> json) => PublishedQna(
    id: json['id'] as String,
    category: json['category'] as String?,
    question: json['question'] as String,
    answer: json['answer'] as String? ?? '',
    publishedAt: json['published_at'] as String?,
  );
}
