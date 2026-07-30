import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// E2 책 미리보기 · E3 완성.
///
/// ⚠️ 넘김 단위가 **쪽**이다. 예전에는 장 단위였다 — 시안 하단이
///    "12 / 34쪽"으로 바뀌면서 한 장 안에서도 쪽을 넘길 수 있어야 한다.
class BookPreviewController extends GetxController {
  BookPreviewController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  /// 지금 보고 있는 쪽들. 특정 장으로 들어왔으면 그 장의 쪽만 담긴다.
  final RxList<BookPage> pages = <BookPage>[].obs;

  final Rxn<Book> book = Rxn<Book>();
  final RxBool isLoading = true.obs;

  /// [pages] 안에서의 위치 (0부터). 책 전체 쪽번호와 다르다.
  final RxInt index = 0.obs;

  /// 어느 장을 보러 들어왔는지. null이면 책 전체를 처음부터 본다.
  Chapter? _chapter;

  BookPage? get page => index.value < pages.length ? pages[index.value] : null;

  bool get hasPrev => index.value > 0;
  bool get hasNext => index.value + 1 < pages.length;

  /// "1장 미리보기" · 장을 안 고르고 들어왔으면 "책 미리보기"
  String get title =>
      _chapter == null ? '책 미리보기' : '${_chapter!.order}장 미리보기';

  /// "12 / 34쪽" — 앞은 **책 전체에서의 쪽번호**, 뒤는 책 전체 쪽수다.
  /// 한 장만 보고 있어도 책 어디쯤인지 알 수 있어야 한다.
  String get pageLabel {
    final p = page;
    return p == null ? '' : '${p.pageNumber} / ${p.totalPages}쪽';
  }

  @override
  void onInit() {
    super.onInit();
    applyArguments(Get.arguments);
    load();
  }

  /// 라우트 인자 해석. 테스트에서 GetX 라우팅 없이 쓰려고 분리해 뒀다.
  @visibleForTesting
  void applyArguments(Object? args) {
    if (args is Chapter) _chapter = args;
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      book.value = await _api.book();
      final all = await _api.bookPages();
      final chapter = _chapter;
      pages.value = chapter == null
          ? all
          : all.where((p) => p.chapterOrder == chapter.order).toList();
      index.value = 0;
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

  /// 아래 셋은 시안에 대응 화면이 없는 액션이다. 붙는 자리만 만들어 뒀다.
  void share() => _toast.show('보내기는 준비 중이에요');

  void orderPrint() => _toast.show('인쇄본 신청은 준비 중이에요');

  void sendToFamily() => _toast.show('가족에게 보내기는 준비 중이에요');
}
