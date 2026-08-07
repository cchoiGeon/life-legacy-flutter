import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/core/route/app_pages.dart';

import 'photo_attach_controller.dart';

/// G4 · 첨부 완료 — 업로드 진행 후 리뷰/홈으로 이동.
class G4DoneView extends StatelessWidget {
  const G4DoneView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PhotoAttachController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // 완료 아이콘
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.brand,
              size: 64,
            ),
            const SizedBox(height: 20),
            // 메시지
            Text(
              '사진을 첨부했어요',
              style: AppTypography.titleScreen,
            ),
            const SizedBox(height: 12),
            Text(
              '책에 사진이 함께 실립니다.\n언제든지 수정하고 바꿀 수 있어요.',
              style: AppTypography.subtitle,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            // CTA
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
                      onPressed: () => _done(c),
                      child: Text(c.returnTo == 'home' ? '홈으로 이동' : '리뷰로 돌아가기'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _done(PhotoAttachController c) async {
    // 업로드
    final ok = await c.uploadAll();
    if (!ok) return;
    if (c.returnTo == 'home') {
      Get.offNamed(AppRoutes.bookDetail, arguments: {'bookId': c.bookId});
    } else {
      Get.offNamed(AppRoutes.bookReview, arguments: {
        'bookId': c.bookId,
        'chapterId': c.chapterId,
      });
    }
  }
}
