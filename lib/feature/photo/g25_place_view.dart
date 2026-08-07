import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/app_bar.dart';
import 'package:life_legacy/core/route/app_pages.dart';

import 'photo_attach_controller.dart';

/// G2.5 · 문단 배치 — 각 사진을 어느 문단 뒤에 넣을지 선택.
/// 장별 리스트에서 "이 문단 뒤"를 고른다.
class G25PlaceView extends StatelessWidget {
  const G25PlaceView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PhotoAttachController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          final idx = c.currentDraftIndex.value;
          if (idx >= c.drafts.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.offNamed(AppRoutes.bookPhotoDone);
            });
            return const SizedBox.shrink();
          }
          final draft = c.drafts[idx];
          final paras = c.paragraphs;

          if (paras.isEmpty) {
            // 문단이 없으면 그냥 넘어감
            c.currentDraftIndex.value = idx + 1;
            Get.offNamed(AppRoutes.bookPhotoCaption);
            return const SizedBox.shrink();
          }

          return Column(
            children: [
              // 헤더
              AppTopBar(onBack: () => Get.back()),
              const SizedBox(height: 8),
              // 사진 미리보기
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusBase),
                  child: Image.memory(
                    draft.bytes,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 160,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // "어느 문단 뒤에 넣을까요?"
              Padding(
                padding: const EdgeInsets.only(left: AppDimens.gutter),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '이 사진을 어느 문단 뒤에 넣을까요?',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 문단 리스트
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
                  itemCount: paras.length,
                  itemBuilder: (context, pi) {
                    final isSelected = draft.paragraphIndex == pi;
                    final text = paras[pi];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          c.updateParagraphIndex(idx, pi);
                        },
                        borderRadius: BorderRadius.circular(AppDimens.radiusBase),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.cream : Colors.white,
                            borderRadius: BorderRadius.circular(AppDimens.radiusBase),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brand
                                  : const Color(0xFFE7E5E4),
                              width: isSelected ? 2 : 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              // 선택 원형 표시
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppColors.brand : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.brand
                                        : AppColors.textTertiary,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: AppColors.onPrimary, size: 16)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              // 문단 미리보기
                              Expanded(
                                child: Text(
                                  text.replaceAll(RegExp(r'\s+'), ' '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodySm.copyWith(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // "이 문단 뒤에 넣기" CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  8,
                  AppDimens.gutter,
                  22,
                ),
                child: SizedBox(
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
                    onPressed: () {
                      // 이 사진 확정 → 다음 사진 설명으로
                      c.currentDraftIndex.value = idx + 1;
                      if (c.currentDraftIndex.value >= c.drafts.length) {
                        Get.offNamed(AppRoutes.bookPhotoDone);
                      } else {
                        Get.offNamed(AppRoutes.bookPhotoCaption);
                      }
                    },
                    child: const Text('이 문단 뒤에 넣기'),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
