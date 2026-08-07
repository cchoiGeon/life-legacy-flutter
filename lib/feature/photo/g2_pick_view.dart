import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/app_bar.dart';
import 'package:life_legacy/core/route/app_pages.dart';

import 'photo_attach_controller.dart';

/// G2 · 사진 고르기 — 갤러리 그리드 + 사진 찍기
class G2PickView extends StatefulWidget {
  const G2PickView({super.key});

  @override
  State<G2PickView> createState() => _G2PickViewState();
}

class _G2PickViewState extends State<G2PickView> {
  final _picker = ImagePicker();
  final RxList<GalleryPhoto> _galleryPhotos = <GalleryPhoto>[].obs;
  final Set<int> _selectedIndices = {};
  late PhotoAttachController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.find<PhotoAttachController>();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    // 최근 사진 로드 (image_picker는 다중 선택 API가 제한적이므로
    // 시스템 갤러리 pickMultiImage를 먼저 시도)
    final files = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
      limit: _c.maxSelectable,
    );
    if (files.isEmpty) return;
    final photos = <GalleryPhoto>[];
    for (final f in files) {
      final bytes = await f.readAsBytes();
      final name = f.name.toLowerCase();
      final contentType = name.endsWith('.png')
          ? 'image/png'
          : name.endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';
      photos.add(GalleryPhoto(bytes: bytes, filename: f.name, contentType: contentType));
    }
    _galleryPhotos.value = photos;
    // 모든 사진을 자동 선택
    _selectedIndices.addAll(List.generate(photos.length, (i) => i));
    _saveToDrafts();
  }

  void _saveToDrafts() {
    for (final i in _selectedIndices) {
      if (i >= _galleryPhotos.length) continue;
      final p = _galleryPhotos[i];
      _c.selectedSources.add(PhotoSource(
        bytes: p.bytes,
        filename: p.filename,
        contentType: p.contentType,
      ));
      _c.drafts.add(PhotoDraft(
        bytes: p.bytes,
        filename: p.filename,
        contentType: p.contentType,
        paragraphIndex: _c.preferredParagraphIndex,
      ));
    }
  }

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final name = file.name.toLowerCase();
    final contentType = name.endsWith('.png')
        ? 'image/png'
        : name.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
    final idx = _galleryPhotos.length;
    _galleryPhotos.add(GalleryPhoto(bytes: bytes, filename: file.name, contentType: contentType));
    _selectedIndices.add(idx);
    _c.selectedSources.add(PhotoSource(bytes: bytes, filename: file.name, contentType: contentType));
    _c.drafts.add(PhotoDraft(
      bytes: bytes,
      filename: file.name,
      contentType: contentType,
      paragraphIndex: _c.preferredParagraphIndex,
    ));
  }

  void _goToNext() {
    if (_c.drafts.isEmpty) return;
    Get.toNamed(AppRoutes.bookPhotoCaption);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더 + 선택 수
            AppTopBar(
              onBack: () => Get.back(),
              trailing: Obx(
                () => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${_c.drafts.length}장 선택',
                    style: AppTypography.label.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // "최근 사진"
            Padding(
              padding: const EdgeInsets.only(left: AppDimens.gutter, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '최근 사진',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
            // 그리드
            Expanded(
              child: Obx(() {
                if (_galleryPhotos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt, color: AppColors.brand),
                          label: Text(
                            '사진 찍기',
                            style: AppTypography.label.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _loadGallery,
                          icon: const Icon(Icons.photo_library, color: AppColors.brand),
                          label: Text(
                            '갤러리에서 선택',
                            style: AppTypography.label.copyWith(
                              color: AppColors.brand,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  itemCount: _galleryPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = _galleryPhotos[index];
                    final selected = _selectedIndices.contains(index);
                    return GestureDetector(
                      onTap: () {
                        if (selected) {
                          _selectedIndices.remove(index);
                          // remove from drafts too
                          _c.drafts.removeWhere(
                            (d) => d.bytes == photo.bytes,
                          );
                          _c.selectedSources.removeWhere(
                            (s) => s.bytes == photo.bytes,
                          );
                        } else if (_c.canSelectMore) {
                          _selectedIndices.add(index);
                          _c.selectedSources.add(PhotoSource(
                            bytes: photo.bytes,
                            filename: photo.filename,
                            contentType: photo.contentType,
                          ));
                          _c.drafts.add(PhotoDraft(
                            bytes: photo.bytes,
                            filename: photo.filename,
                            contentType: photo.contentType,
                            paragraphIndex: _c.preferredParagraphIndex,
                          ));
                        }
                        // force refresh
                        (context as Element).markNeedsBuild();
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppDimens.radiusBase),
                            child: Image.memory(
                              photo.bytes,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          if (selected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppColors.brand,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check,
                                    color: AppColors.onPrimary,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            // 하단 CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutter,
                8,
                AppDimens.gutter,
                22,
              ),
              child: Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: AppDimens.buttonCta,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.buttonCta / 2),
                      ),
                    ),
                    onPressed: _c.drafts.isEmpty ? null : _goToNext,
                    child: Text(
                      '${_c.drafts.length}장 첨부하기',
                      style: AppTypography.label.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                        color: _c.drafts.isEmpty ? AppColors.textTertiary : AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryPhoto {
  const GalleryPhoto({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });

  final Uint8List bytes;
  final String filename;
  final String contentType;
}
