import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

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
  final Rxn<EbookExportResult> export = Rxn<EbookExportResult>();
  final RxBool isLoading = true.obs;
  final RxBool isDownloading = false.obs;

  /// [pages] 안에서의 위치 (0부터). 책 전체 쪽번호와 다르다.
  final RxInt index = 0.obs;

  /// 어느 장을 보러 들어왔는지. null이면 책 전체를 처음부터 본다.
  Chapter? _chapter;

  int? includedCount;
  int? pendingChapters;

  BookPage? get page => index.value < pages.length ? pages[index.value] : null;

  bool get hasPrev => index.value > 0;
  bool get hasNext => index.value + 1 < pages.length;

  /// "1장 미리보기" · 장을 안 고르고 들어왔으면 "책 미리보기"
  String get title {
    if (_chapter != null) return '${_chapter!.order}장 미리보기';
    final n = includedCount ?? export.value?.chapterSnapshot.length;
    if (n != null && n > 0) return '전자책 미리보기 · $n장';
    return '책 미리보기';
  }

  /// "12 / 34쪽" — 앞은 **책 전체에서의 쪽번호**, 뒤는 책 전체 쪽수다.
  String get pageLabel {
    final p = page;
    return p == null ? '' : '${p.pageNumber} / ${p.totalPages}쪽';
  }

  String get scopeCaption {
    final pending = pendingChapters;
    if (pending == null) return '';
    if (pending <= 0) return '리뷰를 마친 장을 모두 담았어요';
    return '리뷰를 마친 장만 담겨 있어요 · $pending개 장이 더 남았어요';
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
    if (args is Chapter) {
      _chapter = args;
    } else if (args is Map) {
      final chapter = args['chapter'];
      if (chapter is Chapter) _chapter = chapter;
      if (args['includedCount'] is int) {
        includedCount = args['includedCount'] as int;
      }
      if (args['pendingChapters'] is int) {
        pendingChapters = args['pendingChapters'] as int;
      }
    }
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final bookId = _requireBookId();
      book.value = await _api.book(bookId);
      final all = await _api.bookPages(bookId);
      final chapter = _chapter;
      pages.value = chapter == null
          ? all
          : all.where((p) => p.chapterOrder == chapter.order).toList();
      index.value = 0;
      try {
        export.value = await _api.generateEbook(bookId);
        includedCount ??= export.value?.chapterSnapshot.length;
      } on ApiException {
        // 쪽 미리보기는 유지 — PDF 생성 실패는 다운로드 때 다시 알린다
      }
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

  Future<void> downloadPdf() async {
    if (isDownloading.value) return;
    isDownloading.value = true;
    try {
      final bookId = _requireBookId();
      export.value = await _api.generateEbook(bookId);
      final bytes = await _api.downloadEbookFile(bookId);
      if (bytes.isEmpty) {
        _toast.show('전자책 파일이 비어 있어요');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/lifelegacy-${bookId.substring(0, 8)}.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        _toast.show('파일을 저장했어요', description: file.path);
      }
    } on ApiException catch (e) {
      _toast.showError(e);
    } catch (_) {
      _toast.show('전자책을 열지 못했어요. 다시 시도해 주세요');
    } finally {
      isDownloading.value = false;
    }
  }

  void share() => downloadPdf();

  Future<void> suggestTitles() async {
    try {
      final titles = await _api.suggestEbookTitles(_requireBookId());
      if (titles.isEmpty) {
        _toast.show('추천 제목이 없어요');
        return;
      }
      final selected = await Get.bottomSheet<String>(
        Container(
          color: Get.theme.scaffoldBackgroundColor,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('제목 추천', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                for (final t in titles)
                  ListTile(
                    title: Text(t),
                    onTap: () => Get.back(result: t),
                  ),
              ],
            ),
          ),
        ),
      );
      if (selected == null || selected.isEmpty) return;
      await _api.updateEbookMetadata(_requireBookId(), title: selected);
      book.value = await _api.book(_requireBookId());
      _toast.show('제목을 바꿨어요');
    } on ApiException catch (e) {
      _toast.showError(e);
    }
  }

  void orderPrint() => _toast.show('인쇄본 신청은 준비 중이에요');

  void sendToFamily() => _toast.show('가족에게 보내기는 준비 중이에요');

  String _requireBookId() {
    final fromArgs = Get.arguments;
    if (fromArgs is Map && fromArgs['bookId'] is String) {
      return fromArgs['bookId'] as String;
    }
    final stored = Storage.currentBookId;
    if (stored != null) return stored;
    throw const ApiException('책을 선택해 주세요');
  }
}
