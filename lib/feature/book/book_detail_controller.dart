import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/purchase/purchase_flow.dart';
import 'package:life_legacy/service/services.dart';

/// 6-1 책 상세 허브 — GET /books/{id} §6.2.
class BookDetailController extends GetxController {
  BookDetailController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final Rxn<Book> book = Rxn<Book>();
  final RxBool isLoading = true.obs;
  final RxBool dismissQuestionCard = false.obs;

  List<Chapter> get chapters => book.value?.chapters ?? const [];

  BookCurrentQuestion? get currentQuestion =>
      dismissQuestionCard.value ? null : book.value?.currentQuestion;

  double get progress => book.value?.progress ?? 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final bookId = _requireBookId();
      await Storage.saveCurrentBookId(bookId);
      book.value = await _api.book(bookId);
      dismissQuestionCard.value = false;
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  String _requireBookId() {
    final fromArgs = Get.arguments;
    if (fromArgs is Map && fromArgs['bookId'] is String) {
      return fromArgs['bookId'] as String;
    }
    final stored = Storage.currentBookId;
    if (stored != null) return stored;
    throw const ApiException('책을 선택해 주세요');
  }

  String get summaryCaption {
    final b = book.value;
    if (b == null) return '';
    return '${b.chapterTotal}장 중 ${b.chapterDone}장 완성 · 전체 ${(progress * 100).round()}%';
  }

  Chapter? get currentChapter =>
      chapters.where((c) => c.status == ChapterStatus.writing).firstOrNull;

  String get ctaLabel {
    final c = currentChapter;
    return c == null ? '책 미리보기' : '제${c.order}장 이어서 쓰기';
  }

  void dismissCurrentQuestion() => dismissQuestionCard.value = true;

  void answerCurrentQuestion() {
    final q = book.value?.currentQuestion;
    final id = _requireBookId();
    _openWrite(bookId: id, questionId: q?.id, chapterOrder: null);
  }

  void onCtaPressed() =>
      currentChapter == null ? openPreview() : continueWriting();

  Future<void> continueWriting() async {
    final q = book.value?.currentQuestion;
    final chapter = currentChapter;
    final id = _requireBookId();
    await _openWrite(
      bookId: id,
      questionId: q?.id,
      chapterOrder: chapter?.order,
    );
  }

  Future<void> _openWrite({
    required String bookId,
    String? questionId,
    int? chapterOrder,
  }) async {
    final order = chapterOrder ??
        chapters
            .where((c) => c.status == ChapterStatus.writing)
            .map((c) => c.order)
            .firstOrNull;
    if (order != null &&
        !await PurchaseFlow.allowChapter(
          api: _api,
          bookId: bookId,
          chapterOrder: order,
        )) {
      return;
    }
    Get.offNamed(
      AppRoutes.write,
      arguments: {
        'bookId': bookId,
        if (questionId != null) 'questionId': questionId,
      },
    );
  }

  Future<void> openPreview() async {
    final id = _requireBookId();
    final entitlements = book.value?.entitlements;
    if (entitlements != null && !entitlements.ebook.allowed) {
      _toast.show('전자책 미리보기를 열 수 없어요');
      return;
    }
    try {
      final eligibility = await _api.ebookEligibility(id);
      if (!eligibility.allowed) {
        final firstDone = chapters
            .where((c) => c.order == 1 && c.status == ChapterStatus.done)
            .firstOrNull;
        _toast.show(
          '챕터 리뷰를 저장하면 전자책을 확인할 수 있어요',
          description: firstDone != null && !firstDone.isReviewed
              ? '챕터 1 리뷰부터 시작해 주세요'
              : null,
        );
        if (firstDone != null && !firstDone.isReviewed) {
          Get.toNamed(
            AppRoutes.bookReview,
            arguments: {'bookId': id, 'chapterId': firstDone.id},
          );
        }
        return;
      }
      Get.toNamed(
        (book.value?.isComplete ?? false)
            ? AppRoutes.bookComplete
            : AppRoutes.bookPreview,
        arguments: {
          'bookId': id,
          'includedCount': eligibility.includedChapters.length,
          'pendingChapters': eligibility.pendingChapters,
        },
      );
    } on ApiException catch (e) {
      _toast.showError(e);
    }
  }

  void openAudiobook() {
    Get.toNamed(
      AppRoutes.bookAudiobook,
      arguments: {'bookId': _requireBookId()},
    );
  }

  void openStorybook() {
    final flag = book.value?.entitlements.storybook;
    if (flag == null || !flag.allowed) {
      PurchaseFlow.openPlan('T2');
      return;
    }
  }

  void openPhotoAlbum() {
    Get.toNamed(
      AppRoutes.bookPhotos,
      arguments: {'bookId': _requireBookId()},
    );
  }

  Future<void> openChapter(Chapter chapter) async {
    switch (chapter.status) {
      case ChapterStatus.locked:
        // 1장을 이미 마쳤는데 다음 장이 잠긴 것처럼 보이면 구매 유도.
        final prevDone = chapters.any(
          (c) => c.order == chapter.order - 1 && c.status == ChapterStatus.done,
        );
        if (prevDone && chapter.order > 1) {
          final ok = await PurchaseFlow.allowChapter(
            api: _api,
            bookId: _requireBookId(),
            chapterOrder: chapter.order,
          );
          if (!ok) return;
        }
        _toast.show('${chapter.order - 1}장을 마치면 열려요');
      case ChapterStatus.done:
        Get.toNamed(
          AppRoutes.bookReview,
          arguments: {
            'bookId': _requireBookId(),
            'chapterId': chapter.id,
          },
        );
      case ChapterStatus.writing:
        final ok = await PurchaseFlow.allowChapter(
          api: _api,
          bookId: _requireBookId(),
          chapterOrder: chapter.order,
        );
        if (!ok) return;
        continueWriting();
    }
  }
}
