import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 20 책 미리보기 · 21 완성.
class BookPreviewController extends GetxController {
  BookPreviewController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  final RxList<BookPage> pages = <BookPage>[].obs;
  final Rxn<Book> book = Rxn<Book>();
  final RxBool isLoading = true.obs;

  /// 현재 보고 있는 쪽 (0부터)
  final RxInt index = 0.obs;

  BookPage? get page => index.value < pages.length ? pages[index.value] : null;

  bool get hasPrev => index.value > 0;
  bool get hasNext => index.value + 1 < pages.length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      book.value = await _api.book();
      pages.value = await _api.bookPages();
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void prev() {
    if (hasPrev) index.value--;
  }

  void next() {
    if (hasNext) index.value++;
  }

  /// 아래 셋은 시안에 화면이 없는 액션이다. 붙는 자리만 만들어 뒀다.
  void share() => _toast.show('공유는 준비 중이에요');

  void orderPrint() => _toast.show('인쇄본 신청은 준비 중이에요');

  void sendToFamily() => _toast.show('전자책 보내기는 준비 중이에요');
}
