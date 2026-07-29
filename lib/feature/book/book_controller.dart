import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 19 나의 자서전 · 목차/진행 — Figma 153:260.
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

  void continueWriting() => Get.offNamed(AppRoutes.write);

  /// 완성됐으면 완성 화면(21), 아니면 미리보기(20)로 보낸다.
  void openPreview() => Get.toNamed(
    (book.value?.isComplete ?? false)
        ? AppRoutes.bookComplete
        : AppRoutes.bookPreview,
  );

  void openChapter(Chapter chapter) {
    if (chapter.status == ChapterStatus.locked) {
      _toast.show('아직 잠겨 있어요', description: '앞 장을 먼저 끝내면 열려요');
      return;
    }
    // 장을 골라서 그 장부터 쓰는 흐름은 시안에 없다. 지금은 작성 탭이
    // 정한 "다음 질문"으로 간다.
    Get.offNamed(AppRoutes.write);
  }
}
