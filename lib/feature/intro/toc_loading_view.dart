import 'dart:math' as math;

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
                const _WaitingRing(),
                const SizedBox(height: 34),
                const Text('목차를 만들고 있어요', style: AppTypography.titleSerifSm),
                const SizedBox(height: 14),
                Text(
                  '말씀해주신 내용으로\n5개 장을 준비하고 있어요',
                  textAlign: TextAlign.center,
                  style: AppTypography.subtitle.copyWith(height: 28 / 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 브랜드 마크를 감싸고 도는 점선 링 (시안 347:770).
///
/// 시안은 정지 그림이지만 여기서는 돌린다 — 목차 생성은 몇 초 걸리는 작업이라
/// 아무것도 움직이지 않으면 멈춘 화면으로 보인다.
class _WaitingRing extends StatefulWidget {
  const _WaitingRing();

  @override
  State<_WaitingRing> createState() => _WaitingRingState();
}

class _WaitingRingState extends State<_WaitingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              size: const Size(116, 116),
              painter: _DashRingPainter(turns: _c.value),
            ),
          ),
          const AppBrandMark(size: 76),
        ],
      ),
    );
  }
}

class _DashRingPainter extends CustomPainter {
  const _DashRingPainter({required this.turns});

  final double turns;

  /// 점선 조각 수 — 시안의 링과 같은 성김이다.
  static const _dashes = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.warm
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3);
    const step = 2 * math.pi / _dashes;
    final start = turns * 2 * math.pi;

    for (var i = 0; i < _dashes; i++) {
      // 조각과 빈칸을 반씩 나눈다.
      canvas.drawArc(rect, start + i * step, step * 0.5, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashRingPainter old) => old.turns != turns;
}
