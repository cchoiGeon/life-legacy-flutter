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
/// 음성 화면([tall])은 질문을 가운데 크게(명조 28) 놓고 "다시 들려주기"를
/// 붙이지만, 글자 입력 화면은 입력칸에 자리를 내주려고 작게(명조 20) 왼쪽
/// 정렬로 줄인다. 크기는 설정의 질문 글자 크기를 따른다.
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
  ///
  /// 꼬리질문은 요약 + 공감 + 질문이 한 덩어리로 와서 원래 질문의 서너 배다.
  /// 크기와 높이를 그대로 두면 화면 밖으로 넘친다.
  ///
  /// ⚠️ 예전에는 "이어서 여쭤볼게요" 배지를 붙여 두고 그 유무로 판단했다.
  ///    배지를 걷어내면서 판단 근거를 이 값으로 옮겼다.
  final bool isFollowup;

  bool get _isLong => isFollowup;

  /// 좁은 화면(글자 입력)에 남길 글.
  ///
  /// 꼬리질문은 `[요약·공감]` 빈 줄 `[질문]` 꼴로 온다. 입력칸에 자리를
  /// 내주려고 **앞에서부터** 잘라 내면 정작 물어보는 문장이 사라진다 —
  /// 실제로 그렇게 만들었더니 화면에 공감 문구만 남았다.
  /// 전문은 바로 앞 화면(음성 대기)에서 이미 읽고 넘어온다.
  String get _compactQuestion {
    if (!_isLong) return question;
    final split = question.lastIndexOf('\n\n');
    if (split < 0) return question;
    return question.substring(split + 2).trim();
  }

  TextStyle _questionStyle(double size) => AppTypography.titleScreen.copyWith(
        fontSize: size,
        height: (size * 1.5) / size,
        letterSpacing: size >= 28 ? -0.5 : -0.3,
      );

  @override
  Widget build(BuildContext context) {
    final prefs = Get.find<PrefsService>();

    if (!tall) {
      return Obx(() {
        final size = prefs.questionCompactSize;
        return Container(
          width: double.infinity,
          color: AppColors.cream,
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 빈 줄이 없어 잘라 낼 수 없는 꼬리질문은 통째로 두되 4줄로 막는다.
              Text(
                keepAll(_compactQuestion),
                maxLines: _isLong ? 4 : null,
                overflow: _isLong ? TextOverflow.ellipsis : null,
                style: _questionStyle(size),
              ),
            ],
          ),
        );
      });
    }

    return Container(
      width: double.infinity,
      // 꼬리질문은 길이를 미리 알 수 없어 높이를 고정하지 않는다. 시안의
      // 244는 최소 높이로 남겨 1차 질문일 때 지금까지와 똑같이 보이게 한다.
      //
      // 348은 아래 마이크 영역을 밀어내지 않는 선에서 최대치다 —
      // 844 화면에서 머리(148) + 판(348) + 누르는 영역(344) = 840.
      // ⚠️ **위쪽 상한을 두지 않는다.** 얼마나 커질 수 있는지는 부모가 정한다 —
      //    화면에서 마이크 영역을 뺀 나머지가 곧 이 판의 최대 높이다.
      //    예전에는 348을 박아 뒀는데, 큰 기기에서는 남는 자리를 두고도 글이
      //    스크롤에 갇혔고 작은 기기에서는 마이크를 밀어냈다.
      //
      //    시안의 244는 **최소** 높이로 남긴다 — 짧은 1차 질문에서 크림 띠가
      //    지금까지와 같은 두께로 보이게 한다.
      constraints: const BoxConstraints(minHeight: 244),
      color: AppColors.cream,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
      // 덩어리(글 + "다시 들려주기")가 판 한가운데에 온다. 남는 높이가 있으면
      // 위아래로 고르게 나뉜다.
      child: Column(
        // 내용만큼만 크고, 모자라면 위 minHeight가 받쳐 준다.
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ⚠️ **스크롤하는 건 글뿐이다.** "다시 들려주기"까지 스크롤 안에
          //    넣으면 긴 꼬리질문에 밀려 판 밖으로 잘려 나간다 — 실기기에서
          //    실제로 그렇게 보였다. [Flexible]이라 글이 짧으면 그만큼만
          //    차지하고, 길면 남은 높이까지만 쓰고 안에서 스크롤한다.
          Flexible(
            child: SingleChildScrollView(
              child: Obx(() {
                // 꼬리질문은 원래 질문의 서너 배라 기본 크기를 그대로 쓰면
                // 마지막 줄이 판 밖으로 밀린다. compact 단계를 쓴다.
                final size = _isLong
                    ? prefs.questionCompactSize
                    : prefs.questionPrimarySize;
                return Text(
                  keepAll(question),
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
