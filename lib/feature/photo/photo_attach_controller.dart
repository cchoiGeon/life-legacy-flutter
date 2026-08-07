import 'dart:typed_data';

import 'package:get/get.dart';

import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/service/services.dart';

/// 리뷰 저장 후 "사진 첨부" / 리뷰 중 "사진 넣기" 진입 시 공유 상태.
/// G1→G2→G3→G2.5→G4의 사진 선택·설명·배치를 로컬에서 관리하고
/// 마지막에 일괄 업로드한다.
class PhotoAttachController extends GetxController {
  PhotoAttachController(this._api, this._toast);

  final ApiClient _api;
  final ToastService _toast;

  // ── 진입 파라미터 ──────────────────────────────────────────
  late final String bookId;
  late final String chapterId;
  late final String chapterTitle;
  late final int chapterOrder;

  /// 진입 시 추천 문단 인덱스 (리뷰 "이 문단 뒤에 사진 넣기"에서 옴)
  int preferredParagraphIndex = 0;

  /// 저장 후 돌아갈 경로: 'review' | 'home'
  late String returnTo;

  /// 리뷰의 기존 수동 사진 수 (최대 5장 알림용)
  int existingManualPhotoCount = 0;

  // ── 로컬 초안 (업로드 전 로컬 큐) ──────────────────────────
  final RxList<PhotoDraft> drafts = <PhotoDraft>[].obs;
  final RxInt currentDraftIndex = 0.obs;
  final RxBool isUploading = false.obs;

  // ── G2 선택용 ──────────────────────────────────────────────
  final RxList<PhotoSource> selectedSources = <PhotoSource>[].obs;

  int get maxSelectable => 5 - existingManualPhotoCount;
  bool get canSelectMore => selectedSources.length < maxSelectable;

  // ── G2.5 문단 목록 ─────────────────────────────────────────
  List<String>? _paragraphs;

  set paragraphs(List<String> p) => _paragraphs = p;
  List<String> get paragraphs => _paragraphs ?? [];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    bookId = args['bookId'] as String;
    chapterId = args['chapterId'] as String;
    chapterTitle = args['chapterTitle'] as String? ?? '';
    chapterOrder = args['chapterOrder'] as int? ?? 0;
    preferredParagraphIndex = args['preferredParagraphIndex'] as int? ?? 0;
    returnTo = args['returnTo'] as String? ?? 'review';
    existingManualPhotoCount = args['existingManualPhotoCount'] as int? ?? 0;
  }

  /// G2에서 선택된 사진을 drafts에 추가.
  void addPhotoDraft(PhotoSource source) {
    if (drafts.length >= maxSelectable) return;
    drafts.add(PhotoDraft(
      bytes: source.bytes,
      filename: source.filename,
      contentType: source.contentType,
      paragraphIndex: preferredParagraphIndex,
      caption: null,
    ));
    if (!selectedSources.contains(source)) {
      selectedSources.add(source);
    }
  }

  void removePhotoDraft(int index) {
    if (index < 0 || index >= drafts.length) return;
    final removed = drafts[index];
    drafts.removeAt(index);
    // 같은 source를 selectedSources에서도 제거
    selectedSources.removeWhere(
      (s) => s.bytes == removed.bytes,
    );
  }

  /// G3 — 현재 draft의 캡션 업데이트
  void updateCaption(int index, String? caption) {
    if (index < 0 || index >= drafts.length) return;
    drafts[index] = drafts[index].copyWith(caption: caption);
  }

  /// G2.5 — 현재 draft의 문단 인덱스 업데이트
  void updateParagraphIndex(int index, int pi) {
    if (index < 0 || index >= drafts.length) return;
    drafts[index] = drafts[index].copyWith(paragraphIndex: pi);
  }

  /// 모든 draft를 한 번에 업로드
  Future<bool> uploadAll() async {
    if (drafts.isEmpty) return true;
    isUploading.value = true;
    try {
      for (final d in drafts) {
        await _api.uploadReviewMedia(
          bookId: bookId,
          chapterId: chapterId,
          paragraphIndex: d.paragraphIndex,
          bytes: d.bytes,
          filename: d.filename,
          contentType: d.contentType,
          caption: d.caption,
        );
      }
      drafts.clear();
      selectedSources.clear();
      return true;
    } on ApiException catch (e) {
      _toast.showError(e);
      return false;
    } finally {
      isUploading.value = false;
    }
  }
}

/// G2에서 사진 소스 (갤러리에서 선택한 파일)
class PhotoSource {
  const PhotoSource({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;

  @override
  bool operator ==(Object other) =>
      other is PhotoSource &&
      other.bytes == bytes &&
      other.filename == filename;

  @override
  int get hashCode => Object.hash(bytes, filename);
}

/// 업로드 전 로컬 초안
class PhotoDraft {
  const PhotoDraft({
    required this.bytes,
    required this.filename,
    required this.contentType,
    required this.paragraphIndex,
    this.caption,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
  final int paragraphIndex;
  final String? caption;

  PhotoDraft copyWith({
    Uint8List? bytes,
    String? filename,
    String? contentType,
    int? paragraphIndex,
    String? caption,
  }) =>
      PhotoDraft(
        bytes: bytes ?? this.bytes,
        filename: filename ?? this.filename,
        contentType: contentType ?? this.contentType,
        paragraphIndex: paragraphIndex ?? this.paragraphIndex,
        caption: caption ?? this.caption,
      );
}