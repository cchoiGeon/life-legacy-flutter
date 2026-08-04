import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 05 챕터 리뷰 — 읽기 전용 종합 원고 + Clova TTS 청크 재생.
class ReviewController extends GetxController {
  ReviewController(this._api, this._toast, this._voice);

  final ApiClient _api;
  final ToastService _toast;
  final VoicePlayerService _voice;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool isSaved = false.obs;
  final RxBool isSpeaking = false.obs;
  final Rxn<ChapterReview> review = Rxn<ChapterReview>();

  late final String bookId;
  late final String chapterId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is! Map ||
        args['bookId'] is! String ||
        args['chapterId'] is! String) {
      _toast.showError(const ApiException('장 정보가 없어요'));
      isLoading.value = false;
      return;
    }
    bookId = args['bookId'] as String;
    chapterId = args['chapterId'] as String;
    load();
  }

  @override
  void onClose() {
    _voice.stop();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      var result = await _api.chapterReview(bookId, chapterId);
      result ??= await _api.synthesizeReview(bookId, chapterId);
      review.value = result;
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> save() async {
    final current = review.value;
    if (current == null || isSaving.value) return;
    isSaving.value = true;
    try {
      final saved = await _api.saveReview(
        bookId: bookId,
        chapterId: chapterId,
        version: current.version,
      );
      review.value = saved;
      isSaved.value = true;
      _toast.show(saved.message ?? '저장했어요');
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isSaving.value = false;
    }
  }

  String get headerTitle {
    final r = review.value;
    if (r == null) return '리뷰';
    return '제${r.chapterOrder}장 · ${r.chapterTitle}';
  }

  String get saveDoneMessage =>
      review.value?.message ?? '저장했어요';

  void goHub() {
    Get.offNamed(AppRoutes.bookDetail, arguments: {'bookId': bookId});
  }

  void goBookHub() => goHub();

  void goWrite() {
    Get.offNamed(AppRoutes.write, arguments: {'bookId': bookId});
  }

  /// 원고를 문단 청크로 순서대로 읽어 준다 (§9.4).
  Future<void> playTts() async {
    if (isSpeaking.value || review.value == null) return;
    isSpeaking.value = true;
    try {
      var from = 0;
      while (true) {
        final chunk = await _api.reviewTts(
          bookId: bookId,
          chapterId: chapterId,
          fromParagraph: from,
          chunkSize: 2,
        );
        if (chunk.bytes.isEmpty) break;
        await _voice.playMpeg(chunk.bytes);
        if (!chunk.hasMore) break;
        from = chunk.nextParagraph!;
      }
    } on ApiException catch (e) {
      _toast.showError(e);
    } on Exception {
      _toast.show('음성을 재생하지 못했어요', description: '원고는 화면에서 읽으실 수 있어요');
    } finally {
      isSpeaking.value = false;
    }
  }
}
