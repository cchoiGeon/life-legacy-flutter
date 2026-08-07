import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/text/korean_wrap.dart';
import 'package:life_legacy/service/services.dart';

/// 크림 바탕의 질문판 — Figma 341:654 (D1·D2) · 351:881 (D3).
///
/// 시안의 "읽는 영역". 화면 가장자리까지 닿는 크림 띠라 아래 흰 바탕과
/// 확실히 갈린다.
///
/// 음성 화면([tall])은 질문을 가운데 크게 놓고 "다시 들려주기"를 붙인다.
/// 글자 입력 화면은 입력칸에 자리를 내주되, 긴 질문도 잘리지 않게 고정
/// 높이 안에서 스크롤한다. 크기는 설정의 질문 글자 크기를 따르고, 긴
/// 꼬리질문은 compact(또는 더 작게)를 쓴다.
///
/// [question]은 이미 타이핑 애니가 반영된 글일 수 있다
/// ([WriteController.revealedQuestion]). 전문은 컨트롤러의 displayQuestion.
class QuestionPanel extends StatelessWidget {
  const QuestionPanel({
    super.key,
    required this.question,
    this.onReplay,
    this.tall = true,
    this.isFollowup = false,
  });

  final String question;

  /// null이면 "다시 들려주기"가 빠진다.
  final VoidCallback? onReplay;

  final bool tall;

  /// AI가 되물어 온 꼬리질문인지.
  final bool isFollowup;

  bool get _isLong => isFollowup || question.length >= 80;

  TextStyle _questionStyle(double size) => AppTypography.titleScreen.copyWith(
        fontSize: size,
        height: (size * 1.5) / size,
        letterSpacing: size >= 28 ? -0.5 : -0.3,
      );

  double _fontSize(PrefsService prefs) {
    if (!_isLong) return prefs.questionPrimarySize;
    // 꼬리·긴 질문은 compact. 아주 길면 한 단계 더 줄인다.
    final compact = prefs.questionCompactSize;
    if (question.length >= 160) return (compact - 2).clamp(16, compact);
    return compact;
  }

  String get _displayText => formatQuestionText(question);

  @override
  Widget build(BuildContext context) {
    final prefs = Get.find<PrefsService>();

    if (!tall) {
      return Obx(() {
        final size = _fontSize(prefs);
        return Container(
          width: double.infinity,
          color: AppColors.cream,
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 16),
          // 키보드 화면에서도 질문은 고정 띠 + 내부 스크롤.
          constraints: const BoxConstraints(maxHeight: 148),
          child: SingleChildScrollView(
            child: Text(
              _displayText,
              textAlign: TextAlign.center,
              style: _questionStyle(size),
            ),
          ),
        );
      });
    }

    return Container(
      width: double.infinity,
      // 부모가 Expanded로 남은 높이를 넘긴다 — 그 안에서만 커지고
      // 마이크 영역을 밀어내지 않는다.
      color: AppColors.cream,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Obx(() {
                final size = _fontSize(prefs);
                return Text(
                  _displayText,
                  textAlign: TextAlign.center,
                  style: _questionStyle(size),
                );
              }),
            ),
          ),
          if (onReplay != null) ...[
            const SizedBox(height: 18),
            Semantics(
              button: true,
              label: '다시 들려주기',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onReplay,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '다시 들려주기',
                    style: AppTypography.weight(
                      AppTypography.bodyBase,
                      AppTypography.bold,
                    ).copyWith(
                      color: AppColors.brand,
                      letterSpacing: -0.1,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
