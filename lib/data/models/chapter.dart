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
    this.sourceType = ChapterSource.template,
    this.templateId,
    this.nextQuestionText,
    this.reviewStatus,
    this.ebookEligible = false,
  });

  final String id;

  /// 1부터 시작. "제1장 · 어린 시절"의 숫자.
  final int order;

  /// "어린 시절"
  final String title;

  final ChapterStatus status;

  final ChapterSource sourceType;

  /// 카탈로그에서 온 경우 원본 템플릿 id. 초안에서 중복 추가 방지용.
  final String? templateId;

  /// 답변을 마친 질문 수
  final int answeredCount;

  /// 이 장의 전체 질문 수
  final int questionCount;

  /// 다음에 답할 질문 — 자서전 목록(E1)에 "다음 질문 · 첫 소풍의 기억"으로
  /// 뜬다. 진행 중인 장에만 있다.
  final String? nextQuestionText;

  /// null | draft | reviewed
  final String? reviewStatus;

  final bool ebookEligible;

  /// 아직 서버에 없는 로컬 초안 행
  bool get isLocalDraft => id.startsWith('tmp_') || id.startsWith('tpl_');

  bool get isReviewed => reviewStatus == 'reviewed';

  /// 0.0 ~ 1.0
  double get progress => questionCount == 0 ? 0 : answeredCount / questionCount;

  /// 자서전 목록(E1 341:682)의 보조 문구.
  String get subtitle => switch (status) {
    ChapterStatus.done => isReviewed
        ? '리뷰 완료 · 전자책 포함'
        : '질문 $questionCount개 모두 답했어요',
    ChapterStatus.writing =>
      nextQuestionText == null ? '이어서 쓸 수 있어요' : '다음 질문 · $nextQuestionText',
    ChapterStatus.locked => '${order - 1}장을 마치면 열려요',
  };

  /// 목록 오른쪽 상태 글자. 잠긴 장은 아무것도 쓰지 않는다.
  String? get statusLabel => switch (status) {
    ChapterStatus.done => isReviewed ? '리뷰됨' : '완료',
    ChapterStatus.writing =>
      answeredCount == 0 ? '시작하기' : '$answeredCount/$questionCount',
    ChapterStatus.locked => null,
  };

  Chapter copyWith({
    ChapterStatus? status,
    int? answeredCount,
    String? title,
    String? nextQuestionText,
    ChapterSource? sourceType,
    String? templateId,
    int? order,
    int? questionCount,
    String? reviewStatus,
    bool? ebookEligible,
  }) => Chapter(
    id: id,
    order: order ?? this.order,
    title: title ?? this.title,
    status: status ?? this.status,
    answeredCount: answeredCount ?? this.answeredCount,
    questionCount: questionCount ?? this.questionCount,
    sourceType: sourceType ?? this.sourceType,
    templateId: templateId ?? this.templateId,
    nextQuestionText: nextQuestionText ?? this.nextQuestionText,
    reviewStatus: reviewStatus ?? this.reviewStatus,
    ebookEligible: ebookEligible ?? this.ebookEligible,
  );

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
    id: json['id'] as String,
    order: json['order'] as int? ?? 0,
    title: json['title'] as String? ?? '',
    status: ChapterStatus.fromWire(json['status'] as String?),
    answeredCount: json['answered_count'] as int? ?? 0,
    questionCount: json['question_count'] as int? ?? 0,
    sourceType: ChapterSource.fromWire(json['source_type'] as String?),
    templateId: json['template_id'] as String?,
    nextQuestionText: json['next_question_text'] as String?,
    reviewStatus: json['review_status'] as String?,
    ebookEligible: json['ebook_eligible'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'title': title,
    'status': status.wire,
    'source_type': sourceType.wire,
    'answered_count': answeredCount,
    'question_count': questionCount,
    'next_question_text': nextQuestionText,
    'review_status': reviewStatus,
    'ebook_eligible': ebookEligible,
  };
}

/// GET /catalog/chapters 항목.
class CatalogChapter {
  const CatalogChapter({
    required this.id,
    required this.title,
    required this.questionCount,
    required this.alreadyAdded,
  });

  final String id;
  final String title;
  final int questionCount;
  final bool alreadyAdded;

  factory CatalogChapter.fromJson(Map<String, dynamic> json) => CatalogChapter(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    questionCount: json['question_count'] as int? ?? 0,
    alreadyAdded: json['already_added'] as bool? ?? false,
  );
}

/// PATCH /intro/toc/draft 한 항목.
class TocDraftChapter {
  const TocDraftChapter.existing({required this.id, this.title})
    : templateId = null;

  const TocDraftChapter.fromTemplate({required this.templateId})
    : id = null,
      title = null;

  const TocDraftChapter.custom({required this.title})
    : id = null,
      templateId = null;

  final String? id;
  final String? templateId;
  final String? title;

  Map<String, dynamic> toJson() {
    if (id != null) {
      return {
        'id': id,
        if (title != null) 'title': title,
      };
    }
    if (templateId != null) return {'template_id': templateId};
    return {'title': title};
  }
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

/// 1차 답변을 보고 AI가 되물어 오는 질문.
///
/// [text]는 요약 + 공감 + 질문이 한 덩어리로 온다 —
/// "제주도 이야기를 꺼내시니 … 가장 오래 머문 곳은 어디였나요?"
/// 그래서 원래 질문보다 서너 배 길고, 화면이 스크롤을 열어 둔다.
///
/// 앱은 횟수를 세지 않는다. 서버가 `followup`을 주면 한 번 더, `next_question`이면 확정.
class Followup {
  const Followup({
    required this.id,
    required this.text,
    this.seq,
  });

  /// 꼬리답변을 보낼 때 경로에 실린다.
  final String id;

  final String text;

  /// 꼬리질문 회차 (1부터). 표시용 — 분기에는 쓰지 않는다.
  final int? seq;

  factory Followup.fromJson(Map<String, dynamic> json) => Followup(
    id: json['id'] as String,
    text: json['text'] as String? ?? '',
    seq: json['seq'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    if (seq != null) 'seq': seq,
  };
}

/// POST …/followup/{id}/answer 결과 — followup과 next_question은 동시에 오지 않는다.
class FollowupAdvanceResult {
  const FollowupAdvanceResult({
    this.followup,
    this.nextQuestion,
    this.chapterCompleted = false,
  });

  final Followup? followup;
  final Question? nextQuestion;
  final bool chapterCompleted;

  bool get needsAnotherFollowup => followup != null;

  factory FollowupAdvanceResult.fromJson(Map<String, dynamic> json) {
    final fu = json['followup'];
    return FollowupAdvanceResult(
      followup: fu is Map<String, dynamic> ? Followup.fromJson(fu) : null,
      nextQuestion: json['next_question'] == null
          ? null
          : Question.fromJson(json['next_question'] as Map<String, dynamic>),
      chapterCompleted: json['chapter_completed'] as bool? ?? false,
    );
  }
}

/// GET /books/{id}/chapters/{id}/review
class ChapterReview {
  const ChapterReview({
    required this.chapterId,
    required this.chapterOrder,
    required this.chapterTitle,
    required this.status,
    required this.version,
    required this.paragraphs,
    this.media = const [],
    this.permissions = const ReviewPermissions(),
    this.editHint = '문장을 고칠 수 있어요',
    this.message,
    this.nextChapterId,
  });

  final String chapterId;
  final int chapterOrder;
  final String chapterTitle;

  /// draft | reviewed
  final String status;
  final int version;
  final List<String> paragraphs;
  final List<ReviewMedia> media;
  final ReviewPermissions permissions;
  final String editHint;

  /// PATCH 저장 응답 메시지 (예: 챕터1 저장 완료)
  final String? message;
  final String? nextChapterId;

  String get bodyText => paragraphs.join('\n\n');

  factory ChapterReview.fromJson(Map<String, dynamic> json) {
    final perms = json['permissions'];
    return ChapterReview(
      chapterId: json['chapter_id'] as String,
      chapterOrder: json['chapter_order'] as int? ?? 0,
      chapterTitle: json['chapter_title'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      version: json['version'] as int? ?? 1,
      paragraphs: (json['paragraphs'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      media: (json['media'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ReviewMedia.fromJson)
              .toList() ??
          const [],
      permissions: perms is Map<String, dynamic>
          ? ReviewPermissions.fromJson(perms)
          : const ReviewPermissions(),
      editHint: json['edit_hint'] as String? ?? '문장을 고칠 수 있어요',
      message: json['message'] as String?,
      nextChapterId: json['next_chapter_id'] as String?,
    );
  }

  ChapterReview copyWith({
    String? status,
    int? version,
    List<String>? paragraphs,
    List<ReviewMedia>? media,
    ReviewPermissions? permissions,
    String? editHint,
    String? message,
    String? nextChapterId,
  }) =>
      ChapterReview(
        chapterId: chapterId,
        chapterOrder: chapterOrder,
        chapterTitle: chapterTitle,
        status: status ?? this.status,
        version: version ?? this.version,
        paragraphs: paragraphs ?? this.paragraphs,
        media: media ?? this.media,
        permissions: permissions ?? this.permissions,
        editHint: editHint ?? this.editHint,
        message: message ?? this.message,
        nextChapterId: nextChapterId ?? this.nextChapterId,
      );
}

class ReviewMedia {
  const ReviewMedia({
    required this.id,
    required this.url,
    required this.paragraphIndex,
    required this.source,
    this.caption,
  });

  final String id;

  /// 상대 경로 — Dio로 바이트 조회
  final String url;
  final int paragraphIndex;

  /// user_upload | ai_generated | system
  final String source;

  /// G3 사용자 작성 사진 설명
  final String? caption;

  factory ReviewMedia.fromJson(Map<String, dynamic> json) => ReviewMedia(
        id: json['id'] as String,
        url: json['url'] as String? ?? '',
        paragraphIndex: json['paragraph_index'] as int? ?? 0,
        source: json['source'] as String? ?? 'user_upload',
        caption: json['caption'] as String?,
      );
}

class ReviewPermissions {
  const ReviewPermissions({
    this.manualPhoto = false,
    this.aiPhoto = true,
    this.aiPhotoRegen = false,
    this.aiPhotoRegenRemaining = 0,
    this.aiRewrite = false,
    this.editBody = true,
  });

  final bool manualPhoto;

  /// 챕터 AI 사진 첫 생성 가능
  final bool aiPhoto;

  /// T3/T4 재생성 가능
  final bool aiPhotoRegen;
  final int aiPhotoRegenRemaining;
  final bool aiRewrite;
  final bool editBody;

  factory ReviewPermissions.fromJson(Map<String, dynamic> json) =>
      ReviewPermissions(
        manualPhoto: json['manual_photo'] as bool? ?? false,
        aiPhoto: json['ai_photo'] as bool? ?? true,
        aiPhotoRegen: json['ai_photo_regen'] as bool? ?? false,
        aiPhotoRegenRemaining:
            json['ai_photo_regen_remaining'] as int? ?? 0,
        aiRewrite: json['ai_rewrite'] as bool? ?? false,
        editBody: json['edit_body'] as bool? ?? true,
      );
}

/// GET /books/{id}/chapters/{id}/completion — api-spec §5.9
class ChapterCompletion {
  const ChapterCompletion({
    required this.chapterId,
    required this.chapterOrder,
    required this.chapterTitle,
    required this.questionCount,
    required this.answeredCount,
    required this.skippedCount,
    this.reviewStatus,
    this.nextChapter,
    this.canReview = false,
    this.canHub = true,
  });

  final String chapterId;
  final int chapterOrder;
  final String chapterTitle;
  final int questionCount;
  final int answeredCount;
  final int skippedCount;

  /// null이면 아직 리뷰 전
  final String? reviewStatus;
  final ChapterCompletionNext? nextChapter;
  final bool canReview;
  final bool canHub;

  bool get needsReview => reviewStatus == null && canReview;
  bool get hasNextChapter => nextChapter != null;

  factory ChapterCompletion.fromJson(Map<String, dynamic> json) {
    final next = json['next_chapter'];
    final actions = json['actions'] as Map<String, dynamic>? ?? const {};
    return ChapterCompletion(
      chapterId: json['chapter_id'] as String,
      chapterOrder: json['chapter_order'] as int? ?? 0,
      chapterTitle: json['chapter_title'] as String? ?? '',
      questionCount: json['question_count'] as int? ?? 0,
      answeredCount: json['answered_count'] as int? ?? 0,
      skippedCount: json['skipped_count'] as int? ?? 0,
      reviewStatus: json['review_status'] as String?,
      nextChapter: next is Map<String, dynamic>
          ? ChapterCompletionNext.fromJson(next)
          : null,
      canReview: actions['review'] as bool? ?? false,
      canHub: actions['hub'] as bool? ?? true,
    );
  }
}

class ChapterCompletionNext {
  const ChapterCompletionNext({
    required this.id,
    required this.order,
    required this.title,
  });

  final String id;
  final int order;
  final String title;

  factory ChapterCompletionNext.fromJson(Map<String, dynamic> json) =>
      ChapterCompletionNext(
        id: json['id'] as String,
        order: json['order'] as int? ?? 0,
        title: json['title'] as String? ?? '',
      );
}

/// GET /books/{id}/photos — 책 사진첩
class BookPhotosResponse {
  const BookPhotosResponse({required this.chapters});

  final List<ChapterPhotoGroup> chapters;

  factory BookPhotosResponse.fromJson(Map<String, dynamic> json) =>
      BookPhotosResponse(
        chapters: (json['chapters'] as List?)
                ?.map(
                  (e) =>
                      ChapterPhotoGroup.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      );
}

class ChapterPhotoGroup {
  const ChapterPhotoGroup({
    required this.chapterId,
    required this.chapterOrder,
    required this.chapterTitle,
    required this.photoCount,
    required this.photos,
  });

  final String chapterId;
  final int chapterOrder;
  final String chapterTitle;
  final int photoCount;
  final List<ChapterPhotoItem> photos;

  factory ChapterPhotoGroup.fromJson(Map<String, dynamic> json) =>
      ChapterPhotoGroup(
        chapterId: json['chapter_id'] as String,
        chapterOrder: json['chapter_order'] as int? ?? 0,
        chapterTitle: json['chapter_title'] as String? ?? '',
        photoCount: json['photo_count'] as int? ?? 0,
        photos: (json['photos'] as List?)
                ?.map(
                  (e) =>
                      ChapterPhotoItem.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      );
}

class ChapterPhotoItem {
  const ChapterPhotoItem({
    required this.id,
    required this.url,
    this.caption,
    required this.paragraphIndex,
    required this.source,
  });

  final String id;
  final String url;
  final String? caption;
  final int paragraphIndex;
  final String source;

  factory ChapterPhotoItem.fromJson(Map<String, dynamic> json) =>
      ChapterPhotoItem(
        id: json['id'] as String,
        url: json['url'] as String? ?? '',
        caption: json['caption'] as String?,
        paragraphIndex: json['paragraph_index'] as int? ?? 0,
        source: json['source'] as String? ?? 'user_upload',
      );
}

/// GET /books/{id}/photos/{chapterId} — 장 사진 상세 + 원고
class ChapterPhotosDetail {
  const ChapterPhotosDetail({
    required this.chapterId,
    required this.chapterOrder,
    required this.chapterTitle,
    required this.body,
    required this.paragraphs,
    required this.photos,
  });

  final String chapterId;
  final int chapterOrder;
  final String chapterTitle;
  final String body;
  final List<String> paragraphs;
  final List<ChapterPhotoItem> photos;

  factory ChapterPhotosDetail.fromJson(Map<String, dynamic> json) =>
      ChapterPhotosDetail(
        chapterId: json['chapter_id'] as String,
        chapterOrder: json['chapter_order'] as int? ?? 0,
        chapterTitle: json['chapter_title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        paragraphs: (json['paragraphs'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        photos: (json['photos'] as List?)
                ?.map(
                  (e) =>
                      ChapterPhotoItem.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            const [],
      );
}
