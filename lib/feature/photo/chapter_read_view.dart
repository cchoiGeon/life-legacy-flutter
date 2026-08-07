import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/service/services.dart';

/// 장 원고 조회 — 읽기 전용으로 문단+사진 표시 (TTS/수정/저장 없음)
class ChapterReadAlbumView extends StatefulWidget {
  const ChapterReadAlbumView({super.key});

  @override
  State<ChapterReadAlbumView> createState() => _ChapterReadAlbumViewState();
}

class _ChapterReadAlbumViewState extends State<ChapterReadAlbumView> {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('원고 보기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (isLoading.value) return const Center(child: AppSpinner());
        final d = detail.value;
        if (d == null) {
          return const Center(child: Text('원고를 불러오지 못했어요'));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppDimens.gutter, 12, AppDimens.gutter, 24),
          children: [
            // 제목
            Text(
              '제${d.chapterOrder}장 · ${d.chapterTitle}',
              style: AppTypography.titleScreen.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 20),
            // 문단 + 사진
            for (var pi = 0; pi < d.paragraphs.length; pi++) ...[
              if (pi > 0) const SizedBox(height: 22),
              Text(
                d.paragraphs[pi],
                style: AppTypography.bookBody.copyWith(height: 30 / 16, letterSpacing: -0.2),
              ),
              ...d.photos
                  .where((p) => p.paragraphIndex == pi)
                  .map((photo) => Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _PhotoBlock(
                          bookId: _bookId,
                          chapterId: _chapterId,
                          photo: photo,
                        ),
                      )),
            ],
          ],
        );
      }),
    );
  }
}

class _PhotoBlock extends StatelessWidget {
  const _PhotoBlock({
    required this.bookId,
    required this.chapterId,
    required this.photo,
  });

  final String bookId;
  final String chapterId;
  final ChapterPhotoItem photo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusBase),
          child: _AwaitBytes(
            future: Get.find<ApiClient>().fetchReviewMediaBytes(
              bookId: bookId,
              chapterId: chapterId,
              placementId: photo.id,
            ),
            builder: (data) {
              if (data == null || data.isEmpty) {
                return Container(
                  height: 180,
                  color: AppColors.cream,
                  child: const Center(child: AppSpinner()),
                );
              }
              return Image.memory(data, fit: BoxFit.contain, width: double.infinity);
            },
          ),
        ),
        if (photo.caption != null && photo.caption!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            photo.caption!,
            style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ],
    );
  }
}

/// Uint8List를 Future로 받는 단순화된 FutureBuilder
class _AwaitBytes extends StatelessWidget {
  const _AwaitBytes({
    required this.future,
    required this.builder,
  });

  final Future<List<int>> future;
  final Widget Function(Uint8List? data) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: future,
      builder: (context, snap) {
        final data = snap.data;
        if (data == null || data.isEmpty) return builder(null);
        return builder(Uint8List.fromList(data));
      },
    );
  }
}