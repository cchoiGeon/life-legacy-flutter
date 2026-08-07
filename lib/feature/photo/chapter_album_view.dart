import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 장별 G4 · 1장 사진 모아보기 — 2열 그리드 + 캡션 + 편집 + 더 넣기
class ChapterAlbumView extends StatefulWidget {
  const ChapterAlbumView({super.key});

  @override
  State<ChapterAlbumView> createState() => _ChapterAlbumViewState();
}

class _ChapterAlbumViewState extends State<ChapterAlbumView> {
  final RxBool isLoading = true.obs;
  final Rx<ChapterPhotosDetail?> detail = Rx<ChapterPhotosDetail?>(null);
  late String _bookId;
  late String _chapterId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _bookId = args['bookId'] as String;
    _chapterId = args['chapterId'] as String;
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final api = Get.find<ApiClient>();
      detail.value = await api.chapterPhotosDetail(_bookId, _chapterId);
    } on ApiException catch (e) {
      Get.find<ToastService>().showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final chapterTitle = args['chapterTitle'] as String? ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${chapterTitle} 사진'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 편집 — 삭제 모드
            },
            child: Text(
              '편집',
              style: AppTypography.label.copyWith(color: AppColors.brand),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (isLoading.value) return const Center(child: AppSpinner());
        final d = detail.value;
        if (d == null || d.photos.isEmpty) {
          return const Center(child: Text('이 장에 첨부된 사진이 없어요'));
        }
        return Column(
          children: [
            // "어린 시절에 넣은 사진 N장"
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.gutter, 8, AppDimens.gutter, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${chapterTitle}에 넣은 사진 ${d.photos.length}장',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            // 2열 사진 그리드
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: d.photos.length,
                itemBuilder: (context, i) {
                  final photo = d.photos[i];
                  return GestureDetector(
                    onTap: () => Get.toNamed(
                      AppRoutes.bookChapterRead,
                      arguments: {
                        'bookId': _bookId,
                        'chapterId': _chapterId,
                        'chapterTitle': chapterTitle,
                      },
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 사진
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _PhotoFutureBuilder(
                              future: Get.find<ApiClient>().fetchReviewMediaBytes(
                                bookId: _bookId,
                                chapterId: _chapterId,
                                placementId: photo.id,
                              ),
                              builder: (data) {
                                if (data == null || data.isEmpty) {
                                  return Container(
                                    color: AppColors.cream,
                                    child: const Center(child: AppSpinner()),
                                  );
                                }
                                return Image.memory(
                                  Uint8List.fromList(data),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 캡션
                        Text(
                          photo.caption ?? '',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 사진 더 넣기 CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(AppDimens.gutter, 8, AppDimens.gutter, 22),
              child: SizedBox(
                width: double.infinity,
                height: AppDimens.buttonCard,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.brand, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Get.toNamed(AppRoutes.bookPhotoSuggest, arguments: {
                      'bookId': _bookId,
                      'chapterId': _chapterId,
                      'chapterTitle': chapterTitle,
                      'returnTo': 'album',
                    });
                  },
                  child: Text(
                    '사진 더 넣기',
                    style: AppTypography.label.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// 단순화된 FutureBuilder
class _PhotoFutureBuilder extends StatelessWidget {
  const _PhotoFutureBuilder({
    required this.future,
    required this.builder,
  });

  final Future<List<int>> future;
  final Widget Function(List<int>? data) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: future,
      builder: (context, snap) => builder(snap.data),
    );
  }
}