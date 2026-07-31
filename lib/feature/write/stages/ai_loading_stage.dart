import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';

import '../write_controller.dart';

/// D7 꼬리질문 준비 중 — Figma 398:6
/// D8 이야기 정리 중 — Figma 398:30
///
/// 서버가 AI를 부르는 동안 뜬다. 꼬리질문은 30초, 윤문은 60초까지 걸린다 —
/// 시니어 사용자에게 1분 무반응은 "앱이 멈췄다"로 읽히므로, 지금 무슨 일이
/// 일어나는지를 **문장으로** 알린다. 스피너만 도는 화면은 이유를 설명하지
/// 못한다.
///
/// B6(목차 준비 중)과 **같은 덩어리**다. 링·간격·글자 크기가 어긋나면 두
/// 화면이 미묘하게 달라 보인다 — 숫자는 전부 시안 398:7 실측이다.
///
/// ⚠️ 되돌아가는 길을 두지 않았다. 서버가 이미 이야기를 받아 처리 중인데
///    화면만 빠져나오면 답이 어디로 갔는지 알 수 없는 상태가 된다.
class AiLoadingStage extends GetView<WriteController> {
  const AiLoadingStage({super.key});

  /// 시안 398:7 — 대기 덩어리가 프레임 위에서 274에서 시작한다.
  /// 가운데 정렬이 **아니다**(315 높이면 중앙은 264다).
  static const _blockTop = 274.0;

  /// 시안 398:7의 좌우 여백.
  static const _sideGutter = 40.0;

  @override
  Widget build(BuildContext context) {
    // ⚠️ 작성 화면(D1~D5)은 흰 바탕이지만 대기 화면은 크림이다.
    //    Scaffold 기본색을 그대로 쓰면 흰 화면이 된다.
    //
    // ⚠️ [SizedBox.expand]가 필요하다. [ColoredBox]만 두면 자식(내용만큼만 큰
    //    Column) 크기로 줄어들어 크림이 글자 뒤에만 깔리고, 덩어리도 왼쪽으로
    //    쏠린다 — 실기기에서 화면 왼쪽 위만 크림으로 나왔다.
    return SizedBox.expand(
      child: ColoredBox(
        color: AppColors.cream,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _sideGutter,
            _blockTop,
            _sideGutter,
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppWaitingRing(),
              const SizedBox(height: 34),
              Obx(
                () => Text(
                  controller.loadingTitle,
                  textAlign: TextAlign.center,
                  // 시안 398:14 — 명조 25 / 36 · 자간 -0.5.
                  // titleSerifSm(26/38)과 한 단계 다르다.
                  style: AppTypography.titleSerifSm.copyWith(
                    fontSize: 25,
                    height: 36 / 25,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => Text(
                  controller.loadingSubtitle,
                  textAlign: TextAlign.center,
                  // 시안 398:16 — 16 / 28. subtitle 기본 행간(19)은 한 줄용이라
                  // 두 줄로 쓰는 여기서는 붙어 보인다.
                  style: AppTypography.subtitle.copyWith(
                    height: 28 / 16,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // 말한 내용이 사라지지 않았다는 걸 대기 중에 알려 둔다.
              // 기다리는 동안 가장 큰 걱정이 그것이다.
              Text(
                '말씀해 주신 이야기는 잘 담아 두었어요',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
