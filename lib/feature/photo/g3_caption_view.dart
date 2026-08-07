import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/app_bar.dart';
import 'package:life_legacy/core/route/app_pages.dart';

import 'photo_attach_controller.dart';

/// G3 · 사진 설명 (말로 입력) — 텍스트만.
/// G3와 G2.5를 사진마다 루프한다.
/// 각 사진: G3 설명화면 → G2.5 문단배치 → 다음 사진
class G3CaptionView extends StatelessWidget {
  const G3CaptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PhotoAttachController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final idx = c.currentDraftIndex.value;
          if (idx >= c.drafts.length) {
            // all done → go to G4
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.offNamed(AppRoutes.bookPhotoDone);
            });
            return const SizedBox.shrink();
          }
          final draft = c.drafts[idx];
          final captionController = TextEditingController(text: draft.caption ?? '');

          return Column(
            children: [
              // 헤더
              AppTopBar(
                onBack: () => Get.back(),
                trailing: Text(
                  '${idx + 1} / ${c.drafts.length}',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              // 사진 미리보기
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusBase),
                  child: Image.memory(
                    draft.bytes,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 240,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // "사진 설명" 라벨
              Padding(
                padding: const EdgeInsets.only(left: AppDimens.gutter),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '사진 설명',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 설명 입력 카드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: captionController,
                        maxLines: 3,
                        maxLength: 200,
                        style: AppTypography.bookBody.copyWith(
                          height: 29 / 17,
                          letterSpacing: -0.2,
                        ),
                        decoration: const InputDecoration(
                          hintText: '사진에 대해 간단히 설명해주세요',
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        onChanged: (v) {
                          c.updateCaption(idx, v.trim().isEmpty ? null : v.trim());
                        },
                      ),
                      const SizedBox(height: 12),
                      // "말로 고치기" 칩 (UI만, STT 미구현)
                      Row(
                        children: [
                          Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.mic, color: AppColors.brand, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '말로 고치기',
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              captionController.clear();
                              c.updateCaption(idx, null);
                            },
                            child: Text(
                              '지우기',
                              style: AppTypography.label.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // 하단 CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  8,
                  AppDimens.gutter,
                  22,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: AppDimens.buttonCta,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.buttonCta / 2),
                          ),
                          textStyle: AppTypography.label.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        onPressed: () => Get.toNamed(AppRoutes.bookPhotoPlace),
                        child: const Text('다음'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        // 건너뛰기 → 문단 배치로
                        Get.toNamed(AppRoutes.bookPhotoPlace);
                      },
                      child: Text(
                        '설명 없이 넘어가기',
                        style: AppTypography.label.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
