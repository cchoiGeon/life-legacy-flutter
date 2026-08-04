import 'chapter.dart';

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

/// GET /books/{id} 상세 허브 (api-spec §6.2).
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.authorName,
    required this.status,
    required this.progress,
    required this.chapterDone,
    required this.chapterTotal,
    required this.chapters,
    required this.entitlements,
    this.currentQuestion,
    this.questionCount = 0,
    this.pageCount = 0,
    this.photoCount = 0,
  });

  final String id;

  /// 표지 제목 — 시안 352:954는 "나의 이야기"
  final String title;

  /// 표지 아래 이름 — "김영희"
  final String authorName;

  /// draft | writing | completed (completed = 전 장 reviewed)
  final String status;

  final double progress;
  final int chapterDone;
  final int chapterTotal;

  final BookCurrentQuestion? currentQuestion;
  final List<Chapter> chapters;
  final BookEntitlements entitlements;

  /// 책에 실린 질문 수(건너뛴 것 제외) — 완성 화면 문구용
  final int questionCount;
  final int pageCount;
  final int photoCount;

  int get chapterCount => chapterTotal;

  /// 모든 장이 reviewed면 true (api-spec §6.3)
  bool get isComplete => status == 'completed';

  /// "전체 34쪽 · 5장 · 사진 12장" (시안 352:961)
  String get summary => [
    '전체 $pageCount쪽',
    '$chapterCount장',
    if (photoCount > 0) '사진 $photoCount장',
  ].join(' · ');

  /// "5장 · 질문 40개를 모두 답하셨어요" (시안 352:951)
  String get completionCaption =>
      '$chapterCount장 · 질문 $questionCount개를 모두 답하셨어요';

  factory Book.fromJson(Map<String, dynamic> json) {
    final chaptersJson = json['chapters'] as List? ?? const [];
    return Book(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      status: json['status'] as String? ??
          ((json['is_complete'] as bool? ?? false) ? 'completed' : 'writing'),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      chapterDone: json['chapter_done'] as int? ?? 0,
      chapterTotal:
          json['chapter_total'] as int? ?? json['chapter_count'] as int? ?? 0,
      currentQuestion: json['current_question'] is Map<String, dynamic>
          ? BookCurrentQuestion.fromJson(
              json['current_question'] as Map<String, dynamic>,
            )
          : null,
      chapters: chaptersJson
          .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList(),
      entitlements: json['entitlements'] is Map<String, dynamic>
          ? BookEntitlements.fromJson(
              json['entitlements'] as Map<String, dynamic>,
            )
          : BookEntitlements.defaults,
      questionCount: json['question_count'] as int? ?? 0,
      pageCount: json['page_count'] as int? ?? 0,
      photoCount: json['photo_count'] as int? ?? 0,
    );
  }
}

class BookCurrentQuestion {
  const BookCurrentQuestion({
    required this.id,
    required this.chapterId,
    required this.chapterTitle,
    required this.order,
    required this.text,
  });

  final String id;
  final String chapterId;
  final String chapterTitle;
  final int order;
  final String text;

  factory BookCurrentQuestion.fromJson(Map<String, dynamic> json) =>
      BookCurrentQuestion(
        id: json['id'] as String,
        chapterId: json['chapter_id'] as String? ?? '',
        chapterTitle: json['chapter_title'] as String? ?? '',
        order: json['order'] as int? ?? 0,
        text: json['text'] as String? ?? '',
      );
}

class BookEntitlements {
  const BookEntitlements({
    required this.ebook,
    required this.audiobook,
    required this.storybook,
  });

  final BookEntitlementFlag ebook;
  final BookEntitlementFlag audiobook;
  final BookEntitlementFlag storybook;

  static const defaults = BookEntitlements(
    ebook: BookEntitlementFlag(allowed: true),
    audiobook: BookEntitlementFlag(allowed: false, reason: 'PLAN_REQUIRED'),
    storybook: BookEntitlementFlag(allowed: false, reason: 'WEB_ONLY'),
  );

  factory BookEntitlements.fromJson(Map<String, dynamic> json) =>
      BookEntitlements(
        ebook: BookEntitlementFlag.fromJson(
          json['ebook'] as Map<String, dynamic>? ?? const {},
        ),
        audiobook: BookEntitlementFlag.fromJson(
          json['audiobook'] as Map<String, dynamic>? ?? const {},
        ),
        storybook: BookEntitlementFlag.fromJson(
          json['storybook'] as Map<String, dynamic>? ?? const {},
        ),
      );
}

class BookEntitlementFlag {
  const BookEntitlementFlag({required this.allowed, this.reason});

  final bool allowed;
  final String? reason;

  factory BookEntitlementFlag.fromJson(Map<String, dynamic> json) =>
      BookEntitlementFlag(
        allowed: json['allowed'] as bool? ?? false,
        reason: json['reason'] as String?,
      );
}

/// GET /books/{id}/entitlements — api-spec §11
class PlanEntitlements {
  const PlanEntitlements({
    required this.planCode,
    required this.features,
  });

  final String planCode;
  final Map<String, PlanFeatureEntitlement> features;

  PlanFeatureEntitlement? feature(String key) => features[key];

  bool isAllowed(String key) => feature(key)?.allowed ?? false;

  factory PlanEntitlements.fromJson(Map<String, dynamic> json) {
    final raw = json['features'] as Map<String, dynamic>? ?? const {};
    return PlanEntitlements(
      planCode: json['plan_code'] as String? ?? 'free',
      features: raw.map(
        (k, v) => MapEntry(
          k,
          PlanFeatureEntitlement.fromJson(
            v is Map<String, dynamic> ? v : const {},
          ),
        ),
      ),
    );
  }
}

class PlanFeatureEntitlement {
  const PlanFeatureEntitlement({
    required this.allowed,
    this.reason,
    this.remainingGenerations,
  });

  final bool allowed;
  final String? reason;

  /// null = 한도 없음
  final int? remainingGenerations;

  factory PlanFeatureEntitlement.fromJson(Map<String, dynamic> json) =>
      PlanFeatureEntitlement(
        allowed: json['allowed'] as bool? ?? false,
        reason: json['reason'] as String?,
        remainingGenerations: json['remaining_generations'] as int?,
      );
}

/// GET /books/{id}/ebook/eligibility
class EbookEligibility {
  const EbookEligibility({
    required this.allowed,
    required this.includedChapters,
    required this.pendingChapters,
    required this.coverKind,
    required this.downloadable,
    required this.titleSuggestAvailable,
    required this.progress,
    this.reason,
  });

  final bool allowed;
  final String? reason;
  final List<EbookIncludedChapter> includedChapters;
  final int pendingChapters;
  final String coverKind;
  final bool downloadable;
  final bool titleSuggestAvailable;
  final double progress;

  factory EbookEligibility.fromJson(Map<String, dynamic> json) =>
      EbookEligibility(
        allowed: json['allowed'] as bool? ?? false,
        reason: json['reason'] as String?,
        includedChapters: (json['included_chapters'] as List? ?? const [])
            .map((e) => EbookIncludedChapter.fromJson(e as Map<String, dynamic>))
            .toList(),
        pendingChapters: json['pending_chapters'] as int? ?? 0,
        coverKind: json['cover_kind'] as String? ?? 'default',
        downloadable: json['downloadable'] as bool? ?? false,
        titleSuggestAvailable:
            json['title_suggest_available'] as bool? ?? false,
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
      );
}

class EbookIncludedChapter {
  const EbookIncludedChapter({
    required this.id,
    required this.order,
    required this.title,
    required this.version,
  });

  final String id;
  final int order;
  final String title;
  final int version;

  factory EbookIncludedChapter.fromJson(Map<String, dynamic> json) =>
      EbookIncludedChapter(
        id: json['id'] as String,
        order: json['order'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        version: json['version'] as int? ?? 1,
      );
}

/// POST /books/{id}/ebook/generate
class EbookExportResult {
  const EbookExportResult({
    required this.exportId,
    required this.status,
    required this.chapterSnapshot,
  });

  final String exportId;
  final String status;
  final List<EbookSnapshotChapter> chapterSnapshot;

  factory EbookExportResult.fromJson(Map<String, dynamic> json) =>
      EbookExportResult(
        exportId: json['export_id'] as String,
        status: json['status'] as String? ?? 'completed',
        chapterSnapshot: (json['chapter_snapshot'] as List? ?? const [])
            .map(
              (e) => EbookSnapshotChapter.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );
}

class EbookSnapshotChapter {
  const EbookSnapshotChapter({
    required this.chapterId,
    required this.version,
  });

  final String chapterId;
  final int version;

  factory EbookSnapshotChapter.fromJson(Map<String, dynamic> json) =>
      EbookSnapshotChapter(
        chapterId: json['chapter_id'] as String,
        version: json['version'] as int? ?? 1,
      );
}

/// GET /books/{id}/audiobook
class AudiobookOverview {
  const AudiobookOverview({
    required this.bookTitle,
    required this.allowed,
    required this.chapters,
    this.reason,
    this.planCode,
    this.totalCharCount = 0,
    this.estimatedDurationMs = 0,
  });

  final String bookTitle;
  final bool allowed;
  final String? reason;
  final String? planCode;
  final int totalCharCount;
  final int estimatedDurationMs;
  final List<AudiobookChapterStatus> chapters;

  factory AudiobookOverview.fromJson(Map<String, dynamic> json) =>
      AudiobookOverview(
        bookTitle: json['book_title'] as String? ?? '',
        allowed: json['allowed'] as bool? ?? false,
        reason: json['reason'] as String?,
        planCode: json['plan_code'] as String?,
        totalCharCount: json['total_char_count'] as int? ?? 0,
        estimatedDurationMs: json['estimated_duration_ms'] as int? ?? 0,
        chapters: (json['chapters'] as List? ?? const [])
            .map(
              (e) =>
                  AudiobookChapterStatus.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );
}

class AudiobookChapterStatus {
  const AudiobookChapterStatus({
    required this.chapterId,
    required this.order,
    required this.title,
    required this.state,
    required this.charCount,
    required this.remainingGenerations,
    this.estimatedDurationMs,
    this.latestJob,
  });

  final String chapterId;
  final int order;
  final String title;

  /// not_ready | ready | processing | completed | failed
  final String state;
  final int charCount;
  final int? estimatedDurationMs;
  final int remainingGenerations;
  final AudiobookLatestJob? latestJob;

  String get stateLabel => switch (state) {
    'not_ready' => '리뷰 필요',
    'ready' => '생성 가능',
    'processing' => '생성 중',
    'completed' => '완료',
    'failed' => '실패',
    _ => state,
  };

  factory AudiobookChapterStatus.fromJson(Map<String, dynamic> json) =>
      AudiobookChapterStatus(
        chapterId: json['chapter_id'] as String,
        order: json['order'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        state: json['state'] as String? ?? 'not_ready',
        charCount: json['char_count'] as int? ?? 0,
        estimatedDurationMs: json['estimated_duration_ms'] as int?,
        remainingGenerations: json['remaining_generations'] as int? ?? 0,
        latestJob: json['latest_job'] is Map<String, dynamic>
            ? AudiobookLatestJob.fromJson(
                json['latest_job'] as Map<String, dynamic>,
              )
            : null,
      );
}

class AudiobookLatestJob {
  const AudiobookLatestJob({
    required this.id,
    required this.status,
    required this.progress,
    required this.stale,
  });

  final String id;
  final String status;
  final int progress;
  final bool stale;

  factory AudiobookLatestJob.fromJson(Map<String, dynamic> json) =>
      AudiobookLatestJob(
        id: json['id'] as String,
        status: json['status'] as String? ?? '',
        progress: json['progress'] as int? ?? 0,
        stale: json['stale'] as bool? ?? false,
      );
}

class AudiobookVoice {
  const AudiobookVoice({
    required this.voiceCode,
    required this.name,
    required this.gender,
    this.age,
    this.pro = false,
    this.isDefault = false,
  });

  final String voiceCode;
  final String name;
  final String gender;
  final String? age;
  final bool pro;
  final bool isDefault;

  factory AudiobookVoice.fromJson(Map<String, dynamic> json) => AudiobookVoice(
        voiceCode: json['voice_code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        gender: json['gender'] as String? ?? '',
        age: json['age'] as String?,
        pro: json['pro'] as bool? ?? false,
        isDefault: json['is_default'] as bool? ?? false,
      );
}

class AudiobookBgmTrack {
  const AudiobookBgmTrack({
    required this.id,
    required this.title,
    this.mood,
  });

  final String id;
  final String title;
  final String? mood;

  factory AudiobookBgmTrack.fromJson(Map<String, dynamic> json) =>
      AudiobookBgmTrack(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        mood: json['mood'] as String?,
      );
}

class AudiobookJobCreated {
  const AudiobookJobCreated({
    required this.jobId,
    required this.status,
    required this.remainingGenerations,
  });

  final String jobId;
  final String status;
  final int remainingGenerations;

  factory AudiobookJobCreated.fromJson(Map<String, dynamic> json) =>
      AudiobookJobCreated(
        jobId: json['job_id'] as String,
        status: json['status'] as String? ?? 'pending',
        remainingGenerations: json['remaining_generations'] as int? ?? 0,
      );
}

class AudiobookJobStatus {
  const AudiobookJobStatus({
    required this.jobId,
    required this.status,
    this.progress = 0,
    this.chapterId,
    this.voiceCode,
    this.errorCode,
  });

  final String jobId;
  final String status;
  final int progress;
  final String? chapterId;
  final String? voiceCode;
  final String? errorCode;

  bool get isDone =>
      status == 'completed' || status == 'failed' || status == 'cancelled';

  factory AudiobookJobStatus.fromJson(Map<String, dynamic> json) =>
      AudiobookJobStatus(
        jobId: (json['job_id'] ?? json['id']) as String,
        status: json['status'] as String? ?? '',
        progress: json['progress'] as int? ?? 0,
        chapterId: json['chapter_id'] as String?,
        voiceCode: json['voice_code'] as String?,
        errorCode: json['error_code'] as String?,
      );
}
