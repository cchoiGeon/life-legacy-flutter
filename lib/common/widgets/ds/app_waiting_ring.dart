import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/widgets/ds/app_card.dart';

/// 브랜드 마크를 감싸고 도는 점선 링 — Figma 347:770(B6) · 398:8(D7·D8).
///
/// 서버가 AI를 부르는 동안 뜨는 화면들이 공유한다. 목차 생성(B6), 꼬리질문
/// 준비(D7), 이야기 정리(D8)가 모두 같은 그림이어야 사용자가 "또 그 기다리는
/// 화면"으로 알아본다.
///
/// 시안 실측:
///   · 링 116 · 점선 stroke `btnMuted` 4 · 대시 30 / 빈칸 16
///   · 안쪽 브랜드 마크 76
///
/// 시안은 정지 그림이지만 여기서는 **돌린다** — 몇십 초 걸리는 작업이라
/// 아무것도 움직이지 않으면 멈춘 화면으로 보인다.
class AppWaitingRing extends StatefulWidget {
  const AppWaitingRing({super.key, this.size = 116});

  final double size;

  @override
  State<AppWaitingRing> createState() => _AppWaitingRingState();
}

class _AppWaitingRingState extends State<AppWaitingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              size: Size.square(widget.size),
              painter: _DashRingPainter(turns: _c.value),
            ),
          ),
          // 시안 398:10 — 링 116 안에 마크 76.
          AppBrandMark(size: widget.size * 76 / 116),
        ],
      ),
    );
  }
}

class _DashRingPainter extends CustomPainter {
  const _DashRingPainter({required this.turns});

  final double turns;

  /// 시안의 대시 30 / 빈칸 16을 둘레에 맞춰 옮긴 값.
  ///
  /// 지름 116, 선 굵기 4면 획 중심의 둘레가 약 352다. 한 주기(30+16=46)로
  /// 나누면 7.6 — 8조각이면 시안과 같은 성김이 된다.
  static const _dashes = 8;
  static const _dutyCycle = 30 / 46;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 4.0;
    final paint = Paint()
      ..color = AppColors.btnMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    const step = 2 * math.pi / _dashes;
    final start = turns * 2 * math.pi;

    for (var i = 0; i < _dashes; i++) {
      canvas.drawArc(rect, start + i * step, step * _dutyCycle, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashRingPainter old) => old.turns != turns;
}
