import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 문장 단위 하이라이트용 인덱스 (전역 문장 순번).
class ReviewSentence {
  const ReviewSentence({
    required this.globalIndex,
    required this.paragraphIndex,
    required this.text,
  });

  final int globalIndex;
  final int paragraphIndex;
  final String text;
}

/// 05 챕터 리뷰 — 종합 원고 읽기·편집·사진·문장 TTS.
class ReviewController extends GetxController {
  ReviewController(this._api, this._toast, this._voice);

  final ApiClient _api;
  final ToastService _toast;
  final VoicePlayerService _voice;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxBool isSaved = false.obs;
  final RxBool isSpeaking = false.obs;
  final RxBool isEditing = false.obs;
  final RxBool isUploadingPhoto = false.obs;
  final RxBool isGeneratingAiPhoto = false.obs;
  final Rxn<ChapterReview> review = Rxn<ChapterReview>();
  final RxInt highlightSentence = (-1).obs;
  final RxMap<String, Uint8List> mediaBytes = <String, Uint8List>{}.obs;

  late final String bookId;
  late final String chapterId;
  late final TextEditingController bodyEditor;

  final ScrollController scrollController = ScrollController();
  final Map<int, GlobalKey> sentenceKeys = {};

  bool _stopRequested = false;

  @override
  void onInit() {
    super.onInit();
    bodyEditor = TextEditingController();
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
    _stopRequested = true;
    _voice.stop();
    bodyEditor.dispose();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      var result = await _api.chapterReview(bookId, chapterId);
      result ??= await _api.synthesizeReview(bookId, chapterId);
      review.value = result;
      bodyEditor.text = result.bodyText;
      await _prefetchMedia(result.media);
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _prefetchMedia(List<ReviewMedia> items) async {
    for (final m in items) {
      if (mediaBytes.containsKey(m.id)) continue;
      try {
        final bytes = await _api.fetchReviewMediaBytes(
          bookId: bookId,
          chapterId: chapterId,
          placementId: m.id,
        );
        if (bytes.isNotEmpty) {
          mediaBytes[m.id] = Uint8List.fromList(bytes);
        }
      } on ApiException {
        // 개별 실패는 무시 — 자리만 비움
      }
    }
    mediaBytes.refresh();
  }

  List<ReviewSentence> get sentences {
    final r = review.value;
    if (r == null) return const [];
    final out = <ReviewSentence>[];
    var global = 0;
    for (var pi = 0; pi < r.paragraphs.length; pi++) {
      for (final s in splitSentences(r.paragraphs[pi])) {
        out.add(
          ReviewSentence(
            globalIndex: global,
            paragraphIndex: pi,
            text: s,
          ),
        );
        global++;
      }
    }
    return out;
  }

  List<ReviewMedia> mediaAfter(int paragraphIndex) {
    final r = review.value;
    if (r == null) return const [];
    return r.media.where((m) => m.paragraphIndex == paragraphIndex).toList();
  }

  void toggleEdit() {
    if (!canEdit) return;
    if (isSpeaking.value) stopTts();
    if (isEditing.value) {
      // 편집 취소 — 원고로 되돌림
      bodyEditor.text = review.value?.bodyText ?? '';
      isEditing.value = false;
    } else {
      bodyEditor.text = review.value?.bodyText ?? '';
      isEditing.value = true;
    }
  }

  bool get canEdit => review.value?.permissions.editBody ?? true;

  bool get canAddPhoto => review.value?.permissions.manualPhoto ?? false;

  bool get canGenerateAiPhoto => review.value?.permissions.aiPhoto ?? false;

  bool get canRegenAiPhoto => review.value?.permissions.aiPhotoRegen ?? false;

  int get aiPhotoRegenRemaining =>
      review.value?.permissions.aiPhotoRegenRemaining ?? 0;

  bool get hasAiPhoto =>
      review.value?.media.any((m) => m.source == 'ai_generated') ?? false;

  Future<void> generateAiPhoto({bool regenerate = false}) async {
    if (isGeneratingAiPhoto.value) return;
    if (regenerate && !canRegenAiPhoto) {
      _toast.show('재생성은 T3·T4에서만 가능해요');
      return;
    }
    if (!regenerate && !canGenerateAiPhoto) {
      _toast.show('이미 AI 사진이 있어요');
      return;
    }

    isGeneratingAiPhoto.value = true;
    try {
      final result = await _api.generateReviewAiPhoto(
        bookId: bookId,
        chapterId: chapterId,
        regenerate: regenerate,
      );
      final current = review.value;
      if (current != null) {
        final withoutOldAi = current.media
            .where((m) => m.source != 'ai_generated')
            .toList();
        final nextMedia = [...withoutOldAi, result.media];
        review.value = current.copyWith(
          media: nextMedia,
          permissions: ReviewPermissions(
            manualPhoto: current.permissions.manualPhoto,
            aiPhoto: false,
            aiPhotoRegen: result.canRegenerate,
            aiPhotoRegenRemaining: result.regenRemaining,
            aiRewrite: current.permissions.aiRewrite,
            editBody: current.permissions.editBody,
          ),
        );
      }
      // 이전 AI 바이트 정리
      final stale = mediaBytes.keys
          .where((id) =>
              review.value?.media.every((m) => m.id != id) ?? true)
          .toList();
      for (final id in stale) {
        mediaBytes.remove(id);
      }
      await _prefetchMedia([result.media]);
      _toast.show(regenerate ? '다른 컨셉으로 다시 만들었어요' : 'AI 사진을 만들었어요');
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isGeneratingAiPhoto.value = false;
    }
  }

  Future<void> save({bool markReviewed = true}) async {
    final current = review.value;
    if (current == null || isSaving.value) return;
    isSaving.value = true;
    try {
      final edited = isEditing.value
          ? bodyEditor.text.trim()
          : current.bodyText;
      if (edited.isEmpty) {
        _toast.show('본문이 비어 있어요');
        return;
      }
      final saved = await _api.saveReview(
        bookId: bookId,
        chapterId: chapterId,
        version: current.version,
        body: edited,
        status: markReviewed ? 'reviewed' : current.status,
      );
      review.value = saved;
      bodyEditor.text = saved.bodyText;
      isEditing.value = false;
      isSaved.value = markReviewed;
      _toast.show(saved.message ?? '저장했어요');
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> addPhoto(int paragraphIndex) async {
    if (!canAddPhoto || isUploadingPhoto.value) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) return;

    isUploadingPhoto.value = true;
    try {
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      final contentType = name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      final media = await _api.uploadReviewMedia(
        bookId: bookId,
        chapterId: chapterId,
        paragraphIndex: paragraphIndex,
        bytes: bytes,
        filename: file.name,
        contentType: contentType,
      );
      final current = review.value;
      if (current != null) {
        review.value = current.copyWith(media: [...current.media, media]);
      }
      mediaBytes[media.id] = Uint8List.fromList(bytes);
      mediaBytes.refresh();
      _toast.show('사진을 넣었어요');
    } on ApiException catch (e) {
      _toast.showError(e);
    } finally {
      isUploadingPhoto.value = false;
    }
  }

  Future<void> removePhoto(String placementId) async {
    try {
      await _api.deleteReviewMedia(
        bookId: bookId,
        chapterId: chapterId,
        placementId: placementId,
      );
      final current = review.value;
      if (current != null) {
        review.value = current.copyWith(
          media: current.media.where((m) => m.id != placementId).toList(),
        );
      }
      mediaBytes.remove(placementId);
      mediaBytes.refresh();
      _toast.show('사진을 지웠어요');
    } on ApiException catch (e) {
      _toast.showError(e);
    }
  }

  String get headerTitle {
    final r = review.value;
    if (r == null) return '리뷰';
    return '제${r.chapterOrder}장 · ${r.chapterTitle}';
  }

  String get saveDoneMessage => review.value?.message ?? '저장했어요';

  void goHub() {
    Get.offNamed(AppRoutes.bookDetail, arguments: {'bookId': bookId});
  }

  void goBookHub() => goHub();

  void goWrite() {
    Get.offNamed(AppRoutes.write, arguments: {'bookId': bookId});
  }

  void stopTts() {
    _stopRequested = true;
    _voice.stop();
    isSpeaking.value = false;
    highlightSentence.value = -1;
  }

  /// 문장별로 읽어 주며 하이라이트한다.
  Future<void> playTts() async {
    if (isSpeaking.value) {
      stopTts();
      return;
    }
    if (isEditing.value) {
      _toast.show('편집을 마친 뒤 읽어 주세요');
      return;
    }
    final list = sentences;
    if (list.isEmpty) return;

    _stopRequested = false;
    isSpeaking.value = true;
    try {
      for (final s in list) {
        if (_stopRequested) break;
        highlightSentence.value = s.globalIndex;
        _scrollToSentence(s.globalIndex);
        final audio = await _api.synthesizeSpeech(text: s.text);
        if (_stopRequested) break;
        await _voice.playMpeg(audio.bytes);
      }
    } on ApiException catch (e) {
      _toast.showError(e);
    } on Exception {
      _toast.show('음성을 재생하지 못했어요', description: '원고는 화면에서 읽으실 수 있어요');
    } finally {
      isSpeaking.value = false;
      highlightSentence.value = -1;
      _stopRequested = false;
    }
  }

  void _scrollToSentence(int index) {
    final list = sentences;
    if (index < 0 || index >= list.length) return;
    final paraKey = controllerSentenceKey(list[index].paragraphIndex);
    final ctx = paraKey?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.35,
    );
  }

  GlobalKey? controllerSentenceKey(int paragraphIndex) =>
      sentenceKeys[-1 - paragraphIndex];
}

/// 한국어·영문 문장 분리 (마침표·물음표·느낌표 기준).
List<String> splitSentences(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];
  final out = <String>[];
  final buf = StringBuffer();
  for (final unit in trimmed.runes) {
    final ch = String.fromCharCode(unit);
    buf.write(ch);
    if ('.。!?！？'.contains(ch)) {
      final s = buf.toString().trim();
      if (s.isNotEmpty) out.add(s);
      buf.clear();
    }
  }
  final rest = buf.toString().trim();
  if (rest.isNotEmpty) out.add(rest);
  return out;
}
