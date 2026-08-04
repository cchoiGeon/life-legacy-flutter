import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 06 책 허브 — `GET /books` 목록 · 가로 카드.
class BookController extends GetxController {
  BookController(this._api, this._toast, this._auth);

  final ApiClient _api;
  final ToastService _toast;
  final AuthService _auth;

  final RxList<BookListItem> books = <BookListItem>[].obs;
  final RxBool isLoading = true.obs;

  List<BookListItem> get writingBooks =>
      books.where((b) => b.status != 'completed').toList();

  List<BookListItem> get completedBooks =>
      books.where((b) => b.status == 'completed').toList();

  String get userName => _auth.user.value?.name ?? '';

  int get writingCount => writingBooks.length;

  int get completedCount => completedBooks.length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      books.value = await _api.books();
      if (_auth.user.value == null) {
        await _auth.reload();
      }
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openBook(BookListItem item) async {
    await Storage.saveCurrentBookId(item.id);
    Get.toNamed(AppRoutes.bookDetail, arguments: {'bookId': item.id});
  }

  String progressLabel(BookListItem item) {
    final pct = (item.progress * 100).round();
    return '${item.chapterDone}/${item.chapterCount}장 · $pct%';
  }

  String statusLabel(BookListItem item) {
    return switch (item.status) {
      'completed' => '제작 완료',
      'draft' => '준비 중',
      _ => '제작 중',
    };
  }
}
