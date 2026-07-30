import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// E1 나의 자서전 · 목차 — Figma 341:670.
class BookController extends GetxController {
  BookController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final RxList<Chapter> chapters = <Chapter>[].obs;
  final Rxn<Book> book = Rxn<Book>();
  final RxBool isLoading = true.obs;

  /// 전체 진행률 — 답변한 질문 수 / 전체 질문 수.
  double get progress {
    final total = chapters.fold<int>(0, (sum, c) => sum + c.questionCount);
    if (total == 0) return 0;
    final done = chapters.fold<int>(0, (sum, c) => sum + c.answeredCount);
    return done / total;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      chapters.value = await _api.chapters();
      book.value = await _api.book();
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// "5장 중 2장 완성 · 전체 42%" (시안 341:675)
  String get summaryCaption {
    final done = chapters.where((c) => c.status == ChapterStatus.done).length;
    return '${chapters.length}장 중 $done장 완성 · 전체 ${(progress * 100).round()}%';
  }

  /// 지금 이어서 쓸 장. 없으면(전부 끝냈으면) null.
  Chapter? get currentChapter =>
      chapters.where((c) => c.status == ChapterStatus.writing).firstOrNull;

  /// "제2장 이어서 쓰기" — 이어 쓸 장이 없으면 미리보기로 문구가 바뀐다.
  String get ctaLabel {
    final c = currentChapter;
    return c == null ? '책 미리보기' : '제${c.order}장 이어서 쓰기';
  }

  void onCtaPressed() =>
      currentChapter == null ? openPreview() : continueWriting();

  void continueWriting() => Get.offNamed(AppRoutes.write);

  /// 완성됐으면 완성 화면(21), 아니면 미리보기(20)로 보낸다.
  void openPreview() => Get.toNamed(
    (book.value?.isComplete ?? false)
        ? AppRoutes.bookComplete
        : AppRoutes.bookPreview,
  );

  /// 장 카드를 눌렀을 때. 상태마다 갈 곳이 다르다.
  ///
  /// 끝낸 장은 **읽으러**(미리보기), 쓰는 중인 장은 **쓰러** 간다.
  /// 시안 E1에 미리보기 버튼이 따로 없고 E2 제목이 "1장 미리보기"인 걸 보면
  /// 완성된 장을 눌러 들어가는 흐름이다.
  void openChapter(Chapter chapter) {
    switch (chapter.status) {
      case ChapterStatus.locked:
        _toast.show('${chapter.order - 1}장을 마치면 열려요');
      case ChapterStatus.done:
        Get.toNamed(AppRoutes.bookPreview, arguments: chapter);
      case ChapterStatus.writing:
        // 장을 골라 그 장부터 쓰는 흐름은 시안에 없다. 작성 탭이 정한
        // "다음 질문"으로 간다.
        Get.offNamed(AppRoutes.write);
    }
  }
}
