import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/route/app_pages.dart';

import 'photo_attach_controller.dart';

/// G1 · 사진 첨부 제안 — "사진도 함께 남기시겠어요?"
class G1SuggestView extends StatelessWidget {
  const G1SuggestView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<PhotoAttachController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            AppTopBar(
              onBack: () => Get.back(),
            ),
            const SizedBox(height: 14),
            // 본문
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      '사진도 함께\n남기시겠어요?',
                      style: AppTypography.titleScreen,
                    ),
                    const SizedBox(height: 16),
                    // 설명
                    Text(
                      '그때 사진이 있으면 책에 함께 실어드려요.\n없으면 그냥 넘어가셔도 됩니다.',
                      style: AppTypography.subtitle,
                    ),
                    const SizedBox(height: 40),
                    // 사진 예시 (폴라로이드 스타일)
                    SizedBox(
                      height: 236,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 왼쪽 사진 (약간 회전)
                          Transform.rotate(
                            angle: 0.12,
                            child: _PolaroidPlaceholder(
                              width: 132,
                              height: 158,
                              gradientColors: const [Color(0xFFD9C7A9), Color(0xFFA88A62)],
                            ),
                          ),
                          // 오른쪽 사진 (약간 회전)
                          Transform.rotate(
                            angle: -0.14,
                            child: _PolaroidPlaceholder(
                              width: 126,
                              height: 150,
                              gradientColors: const [Color(0xFFE2D6C4), Color(0xFFB9A487)],
                            ),
                          ),
                          // 중앙 사진 (거의 정면)
                          Transform.rotate(
                            angle: 0.02,
                            child: _PolaroidPlaceholder(
                              width: 138,
                              height: 166,
                              gradientColors: const [Color(0xFFCDB795), Color(0xFF8F7451)],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                    // 사진 고르기 CTA
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
                        onPressed: () => Get.toNamed(AppRoutes.bookPhotoPick),
                        child: const Text('사진 고르기'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 건너뛰기
                    Center(
                      child: TextButton(
                        onPressed: () => _exit(c),
                        child: Text(
                          '사진 없이 넘어가기',
                          style: AppTypography.label.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exit(PhotoAttachController c) {
    if (c.returnTo == 'home') {
      Get.offNamed(AppRoutes.bookDetail, arguments: {'bookId': c.bookId});
    } else {
      Get.back();
    }
  }
}

class _PolaroidPlaceholder extends StatelessWidget {
  const _PolaroidPlaceholder({
    required this.width,
    required this.height,
    required this.gradientColors,
  });

  final double width;
  final double height;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E5E4)),
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.all(7),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}
