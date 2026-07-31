import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 큰 원형 녹음 버튼 — Figma 341:660 (대기) · 350:889 (녹음 중).
///
/// ⚠️ 색은 **두 상태 모두 브랜드 브라운**이다. 예전에는 녹음 중에 청록으로
///    바뀌었지만, 새 시안은 색을 그대로 두고 **글리프만** 마이크 → 정지 사각으로
///    바꾼다.
///
/// "지금 듣고 있다"는 **버튼 둘레를 도는 원형 파형**이 알려준다. 예전에는 그
/// 일을 버튼 위 막대 파형과 아래 "듣고 있어요 · 0:23"이 나눠 맡았는데, 세로로
/// 자리를 두 군데나 먹어서 작은 화면이 깨졌다. 둘 다 걷어내고 신호를 버튼
/// 하나에 모았다.
class AppMicButton extends StatelessWidget {
  const AppMicButton({
    super.key,
    required this.recording,
    required this.onTap,
    this.size = 160,
  });

  /// 원형 파형을 테스트·디버깅에서 집어내는 손잡이.
  static const ringKey = ValueKey('mic-ring');

  final bool recording;
  final VoidCallback onTap;

  /// 시안 실측 160. 이 화면의 유일한 조작이라 크게 잡는다.
  final double size;

  /// 파형이 버튼 밖으로 번지는 거리(한쪽).
  ///
  /// 자리를 차지하지 않으므로, 위에 있는 화면 요소가 이만큼 비켜 줘야
  /// 파형이 겹치지 않는다. 작성 화면이 이 값을 읽어 간격을 잡는다.
  static const bloom = 26.0;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.brand,
          shape: BoxShape.circle,
          boxShadow: AppShadows.md,
        ),
        child: recording
            ? Container(
                // 시안 350:909 — 160 안에 정지 사각 46, 반경 10
                width: size * 46 / 160,
                height: size * 46 / 160,
                decoration: BoxDecoration(
                  color: AppColors.brandFg,
                  borderRadius: BorderRadius.circular(size * 10 / 160),
                ),
              )
            : CustomPaint(
                size: Size(size, size),
                painter: _MicGlyphPainter(scale: size / 160),
              ),
      ),
    );

    return Semantics(
      button: true,
      label: recording ? '녹음 끝내기' : '눌러서 시작하세요',
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // ⚠️ 파형은 버튼 밖으로 번지지만 **자리는 차지하지 않는다.**
          //    `Positioned.fill` + `OverflowBox`라 Stack 크기는 버튼이 정한다 —
          //    자리를 먹으면 녹음을 시작하는 순간 마이크가 손 밑에서 밀려난다.
          if (recording)
            Positioned.fill(
              child: IgnorePointer(
                child: OverflowBox(
                  maxWidth: size + bloom * 2,
                  maxHeight: size + bloom * 2,
                  child: _MicRing(
                    key: ringKey,
                    diameter: size + bloom * 2,
                    innerRadius: size / 2 + 8,
                  ),
                ),
              ),
            ),
          button,
        ],
      ),
    );
  }
}

/// 버튼 둘레를 도는 원형 파형.
///
/// ⚠️ 실제 오디오 레벨이 아니다. `speech_to_text`가 음량을 주지 않기 때문이다.
///    레벨을 받을 수 있게 되면 [_MicRingPainter]의 amp 계산만 갈아 끼우면 된다.
class _MicRing extends StatefulWidget {
  const _MicRing({
    super.key,
    required this.diameter,
    required this.innerRadius,
  });

  final double diameter;

  /// 막대가 시작하는 반지름. 버튼 가장자리에서 조금 떨어뜨린다.
  final double innerRadius;

  @override
  State<_MicRing> createState() => _MicRingState();
}

class _MicRingState extends State<_MicRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 기기에서 애니메이션을 꺼 둔 사용자에게는 돌리지 않는다. 멈춘 파형이라도
    // 녹음 중이라는 건 정지 사각이 알려준다.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 0.25;
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
  Widget build(BuildContext context) => SizedBox(
    width: widget.diameter,
    height: widget.diameter,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        size: Size.square(widget.diameter),
        painter: _MicRingPainter(t: _c.value, innerRadius: widget.innerRadius),
      ),
    ),
  );
}

class _MicRingPainter extends CustomPainter {
  const _MicRingPainter({required this.t, required this.innerRadius});

  final double t;
  final double innerRadius;

  /// 둘레를 도는 막대 수. 36이면 10도마다 하나다.
  static const _bars = 36;
  static const _minLength = 4.0;
  static const _maxLength = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = AppColors.warm
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < _bars; i++) {
      final angle = 2 * math.pi * i / _bars;
      final phase = t * 2 * math.pi + i * 0.7;
      // 두 주파수를 겹쳐서 규칙적으로 보이지 않게 한다 — 막대 파형과 같은 식.
      final amp =
          math.sin(phase).abs() * 0.7 + math.sin(phase * 0.37).abs() * 0.3;
      final length = _minLength + amp * (_maxLength - _minLength);

      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * innerRadius,
        center + dir * (innerRadius + length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MicRingPainter old) =>
      old.t != t || old.innerRadius != innerRadius;
}

/// 마이크 글리프 — 시안 341:661~663의 사각형 셋을 그대로 옮긴 것.
///
/// `assets/icons/mic.svg`를 쓰지 않는 이유: 그 아이콘은 24px 격자에 맞춰 그려져
/// 있어 160px로 키우면 획이 굵어 보인다. 시안은 이 크기 전용으로 비율을 다시
/// 잡았다(몸통 23×38 · 대 4×10 · 받침 29×4).
class _MicGlyphPainter extends CustomPainter {
  const _MicGlyphPainter({required this.scale});

  /// 160 기준 좌표에 곱할 배율
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.brandFg;
    Rect at(double l, double t, double w, double h) =>
        Rect.fromLTWH(l * scale, t * scale, w * scale, h * scale);

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(at(68.5, 51, 23, 38), Radius.circular(11.5 * scale)),
        paint,
      )
      ..drawRect(at(78, 91, 4, 10), paint)
      ..drawRRect(
        RRect.fromRectAndRadius(at(65.5, 102, 29, 4), Radius.circular(2 * scale)),
        paint,
      );
  }

  @override
  bool shouldRepaint(_MicGlyphPainter old) => old.scale != scale;
}

/// 잠금 자물쇠 — 목차 목록의 잠긴 장(시안 19번).
class AppLockIcon extends StatelessWidget {
  const AppLockIcon({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _LockPainter(color: color ?? AppColors.stone400),
  );
}

class _LockPainter extends CustomPainter {
  const _LockPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTRB(w * 0.28, h * 0.1, w * 0.72, h * 0.62),
      math.pi,
      math.pi,
      false,
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.16, h * 0.44, w * 0.84, h * 0.92),
        Radius.circular(w * 0.12),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_LockPainter old) => old.color != color;
}

/// 완료 체크 — 목차 목록의 끝난 장(시안 19번).
class AppCheckBadge extends StatelessWidget {
  const AppCheckBadge({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: AppColors.accentSoft,
      shape: BoxShape.circle,
    ),
    child: CustomPaint(
      size: Size(size * 0.55, size * 0.55),
      painter: const _CheckPainter(color: AppColors.brandFg),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.1, size.height * 0.52)
        ..lineTo(size.width * 0.4, size.height * 0.82)
        ..lineTo(size.width * 0.9, size.height * 0.2),
      p,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}

/// 원 안의 장 번호 — 목차 목록 왼쪽(시안 10·19번).
class AppChapterBadge extends StatelessWidget {
  const AppChapterBadge({
    super.key,
    required this.number,
    this.active = true,
    this.size = 32,
  });

  final int number;

  /// 진행 중이거나 완료된 장이면 브랜드 채움, 잠긴 장이면 크림 채움.
  final bool active;

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: active ? AppColors.brand : AppColors.cream,
      shape: BoxShape.circle,
    ),
    child: Text(
      '$number',
      style: AppTypography.weight(
        AppTypography.caption,
        AppTypography.medium,
      ).copyWith(color: active ? AppColors.brandFg : AppColors.stone500),
    ),
  );
}
