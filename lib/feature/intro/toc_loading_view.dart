import 'package:flutter/material.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

/// B6 목차 준비 중 — Figma 347:768.
///
/// 뒤로가기를 막는다. 생성이 끝나면 [TocController]가 알아서 B7로 넘긴다.
///
/// ⚠️ 문구에 이름을 넣지 않는다. 예전에는 "영희 님의 이야기를…"이었지만
///    시안은 "말씀해주신 내용으로 5개 장을 준비하고 있어요"로 바뀌었다 —
///    이름을 못 받은 경우(건너뛴 사용자)에 문장이 어색해지던 문제도 같이 없어진다.
class TocLoadingView extends StatelessWidget {
  const TocLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppWaitingRing(),
                const SizedBox(height: 34),
                // 시안 347:776 — 명조 25 / 36. D7·D8과 같은 값을 쓴다.
                Text(
                  '목차를 만들고 있어요',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleSerifSm.copyWith(
                    fontSize: 25,
                    height: 36 / 25,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '말씀해주신 내용으로\n5개 장을 준비하고 있어요',
                  textAlign: TextAlign.center,
                  style: AppTypography.subtitle.copyWith(
                    height: 28 / 16,
                    color: AppColors.textStrong,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
