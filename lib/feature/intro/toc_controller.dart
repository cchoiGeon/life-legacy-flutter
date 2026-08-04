import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// B6 목차 준비 중 · B7 목차 확인·편집 · 저장 완료.
class TocController extends GetxController {
  TocController(this._api, this._auth, this._toast);

  final ApiClient _api;
  final AuthService _auth;
  final ToastService _toast;

  final RxList<Chapter> chapters = <Chapter>[].obs;
  final RxBool isGenerating = false.obs;
  final RxBool isConfirming = false.obs;
  final RxBool isSavingDraft = false.obs;
  final RxBool isEditing = false.obs;
  final RxBool isSaved = false.obs;
  final RxBool draftDirty = false.obs;
  final RxString name = ''.obs;
  final RxnString bookId = RxnString();
  final RxnString firstQuestionId = RxnString();

  int _tmpSeq = 0;

  @override
  void onInit() {
    super.onInit();
    applyArguments(Get.arguments);
  }

  @visibleForTesting
  void applyArguments(Object? args) {
    if (args is List<IntroAnswerSubmission>) {
      name.value = _auth.displayName;
      generate(args);
    } else if (args is Map<String, String>) {
      name.value = (args['i1'] ?? Storage.phone ?? '').trim();
      if (name.value.isEmpty) name.value = _auth.displayName;
      generate([
        for (final e in args.entries)
          IntroAnswerSubmission(questionId: e.key, value: e.value),
      ]);
    } else if (args is TocGenerateResult) {
      bookId.value = args.bookId;
      chapters.value = args.chapters;
    } else if (args is List<Chapter>) {
      chapters.value = args;
      bookId.value = Storage.currentBookId;
    }
  }

  Future<void> generate(List<IntroAnswerSubmission> answers) async {
    isGenerating.value = true;
    try {
      final result = await _api.generateToc(answers);
      bookId.value = result.bookId;
      await Storage.saveCurrentBookId(result.bookId);
      chapters.value = result.chapters;
      Get.offNamed(AppRoutes.toc, arguments: result);
    } on ApiException catch (e) {
      _toast.showError(e);
      Get.back();
    } finally {
      isGenerating.value = false;
    }
  }

  void enterEdit() {
    isEditing.value = true;
  }

  Future<void> exitEdit() async {
    if (draftDirty.value) {
      final ok = await saveDraft();
      if (!ok) return;
    }
    isEditing.value = false;
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex == oldIndex) return;
    final moved = chapters.removeAt(oldIndex);
    chapters.insert(newIndex, moved);
    draftDirty.value = true;
  }

  void rename(int index, String title) {
    final t = title.trim();
    if (t.isEmpty) return;
    chapters[index] = chapters[index].copyWith(title: t);
    chapters.refresh();
    draftDirty.value = true;
  }

  void removeAt(int index) {
    if (chapters.length <= 1) {
      _toast.showError(const ApiException('장은 하나 이상 있어야 해요'));
      return;
    }
    chapters.removeAt(index);
    draftDirty.value = true;
  }

  void addFromCatalog(List<CatalogChapter> selected) {
    for (final c in selected) {
      if (c.alreadyAdded) continue;
      if (chapters.any((x) => x.templateId == c.id || x.title == c.title)) {
        continue;
      }
      _tmpSeq++;
      chapters.add(
        Chapter(
          id: 'tpl_${c.id}_$_tmpSeq',
          order: chapters.length + 1,
          title: c.title,
          status: ChapterStatus.locked,
          answeredCount: 0,
          questionCount: c.questionCount,
          sourceType: ChapterSource.template,
          templateId: c.id,
        ),
      );
    }
    draftDirty.value = true;
  }

  void addCustom(String title) {
    final t = title.trim();
    if (t.isEmpty) return;
    _tmpSeq++;
    chapters.add(
      Chapter(
        id: 'tmp_$_tmpSeq',
        order: chapters.length + 1,
        title: t,
        status: ChapterStatus.locked,
        answeredCount: 0,
        questionCount: 0,
        sourceType: ChapterSource.custom,
      ),
    );
    draftDirty.value = true;
  }

  Future<List<CatalogChapter>> loadCatalog() async {
    final id = bookId.value ?? Storage.currentBookId;
    if (id == null) return const [];
    return _api.catalogChapters(id);
  }

  List<TocDraftChapter> _toDraftPayload() => [
        for (final c in chapters)
          if (c.id.startsWith('tpl_') && c.templateId != null)
            TocDraftChapter.fromTemplate(templateId: c.templateId!)
          else if (c.id.startsWith('tmp_'))
            TocDraftChapter.custom(title: c.title)
          else
            TocDraftChapter.existing(id: c.id, title: c.title),
      ];

  Future<bool> saveDraft() async {
    final id = bookId.value ?? Storage.currentBookId;
    if (id == null) {
      _toast.showError(const ApiException('책 정보가 없어요. 다시 시작해 주세요'));
      return false;
    }
    if (isSavingDraft.value) return false;
    isSavingDraft.value = true;
    try {
      final next = await _api.saveTocDraft(
        bookId: id,
        chapters: _toDraftPayload(),
      );
      chapters.value = next;
      draftDirty.value = false;
      return true;
    } on ApiException catch (e) {
      _toast.showError(e);
      return false;
    } finally {
      isSavingDraft.value = false;
    }
  }

  /// 기본·편집 공통 — 초안을 서버에 맞춘 뒤 확정.
  Future<void> confirm() async {
    if (isConfirming.value || isSaved.value) return;
    final id = bookId.value ?? Storage.currentBookId;
    if (id == null) {
      _toast.showError(const ApiException('책 정보가 없어요. 다시 시작해 주세요'));
      return;
    }

    if (draftDirty.value || chapters.any((c) => c.isLocalDraft)) {
      final ok = await saveDraft();
      if (!ok) return;
    }

    isConfirming.value = true;
    try {
      final result = await _api.confirmToc(bookId: id, chapters: chapters);
      await Storage.saveCurrentBookId(result.bookId);
      await Storage.markIntroDone();
      await _auth.reload();
      bookId.value = result.bookId;
      firstQuestionId.value = result.firstQuestionId;
      chapters.value = result.chapters;
      isEditing.value = false;
      isSaved.value = true;
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isConfirming.value = false;
    }
  }

  void goWrite() {
    final id = bookId.value ?? Storage.currentBookId;
    Get.offAllNamed(AppRoutes.write, arguments: {'bookId': id});
  }

  void goBookHub() {
    final id = bookId.value ?? Storage.currentBookId;
    Get.offAllNamed(AppRoutes.bookDetail, arguments: {'bookId': id});
  }

  int displayNumber(int index) => index + 1;
}
