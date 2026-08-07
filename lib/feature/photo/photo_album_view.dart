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

/// 책 사진첩 — 장별 카드 목록
class PhotoAlbumView extends StatefulWidget {
  const PhotoAlbumView({super.key});

  @override
  State<PhotoAlbumView> createState() => _PhotoAlbumViewState();
}

class _PhotoAlbumViewState extends State<PhotoAlbumView> {
  final RxBool isLoading = true.obs;
  final Rx<BookPhotosResponse?> response = Rx<BookPhotosResponse?>(null);
  late String _bookId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _bookId = args['bookId'] as String;
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final api = Get.find<ApiClient>();
      response.value = await api.bookPhotos(_bookId);
    } on ApiException catch (e) {
      Get.find<ToastService>().showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('사진첩'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (isLoading.value) return const Center(child: AppSpinner());
        final resp = response.value;
        if (resp == null || resp.chapters.isEmpty) {
          return const Center(child: Text('첨부한 사진이 없어요'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppDimens.gutter),
          itemCount: resp.chapters.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final ch = resp.chapters[i];
            return InkWell(
              onTap: () => Get.toNamed(
                AppRoutes.bookPhotosChapter,
                arguments: {
                  'bookId': _bookId,
                  'chapterId': ch.chapterId,
                  'chapterTitle': ch.chapterTitle,
                  'chapterOrder': ch.chapterOrder,
                },
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusCard),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: const Color(0xFFE7E5E4)),
                ),
                child: Row(
                  children: [
                    // 첫 번째 사진 썸네일
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: ch.photos.isNotEmpty
                            ? _PhotoThumb(photo: ch.photos.first)
                            : Container(color: AppColors.cream),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '제${ch.chapterOrder}장 · ${ch.chapterTitle}',
                            style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '사진 ${ch.photoCount}장',
                            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo});
  final ChapterPhotoItem photo;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: Get.find<ApiClient>().fetchReviewMediaBytes(
        bookId: Get.arguments['bookId'] as String,
        chapterId: Get.arguments['chapterId'] as String,
        placementId: photo.id,
      ),
      builder: (context, snap) {
        if (snap.data == null || snap.data!.isEmpty) {
          return Container(color: AppColors.cream);
        }
        return Image.memory(
          Uint8List.fromList(snap.data!),
          fit: BoxFit.cover,
          width: 64,
          height: 64,
        );
      },
    );
  }
}