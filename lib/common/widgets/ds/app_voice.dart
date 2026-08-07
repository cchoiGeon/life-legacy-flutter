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
/// "지금 듣고 있다"는 **버튼에서 번져 나가는 파문**과 **바깥 EQ 링**이 알려준다.
/// 파문은 장식 물결이고, EQ는 실제 마이크 음량([level])에 반응한다.
/// 둘 다 자리를 차지하지 않아 녹음 시작 순간 버튼이 밀리지 않는다.
class AppMicButton extends StatelessWidget {
  const AppMicButton({
    super.key,
    required this.recording,
    required this.onTap,
    this.paused = false,
    this.level = 0,
    this.size = 160,
  });

  /// 파문을 테스트·디버깅에서 집어내는 손잡이.
  static const rippleKey = ValueKey('mic-ripple');

  /// EQ 링을 테스트·디버깅에서 집어내는 손잡이.
  static const eqKey = ValueKey('mic-eq');

  final bool recording;
  final VoidCallback onTap;

  /// 일시정지 중이면 파문·EQ를 끈다. 메인 버튼은 여전히 "끝내기"다.
  final bool paused;

  /// 마이크 입력 세기(0..1). [SpeechService.soundLevel]에서 온다.
  final double level;

  /// 시안 실측 160. 이 화면의 유일한 조작이라 크게 잡는다.
  final double size;

  /// 파문이 버튼 밖으로 번져 나가는 거리.
  ///
  /// 자리를 차지하지 않으므로, 위에 있는 화면 요소가 이만큼 비켜 줘야
  /// 파문이 겹치지 않는다. 작성 화면이 이 값을 읽어 간격을 잡는다.
  static const bloom = 26.0;

  @override
  Widget build(BuildContext context) {
    final listening = recording && !paused;
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
          // ⚠️ 파문·EQ는 버튼 밖으로 번지지만 **자리는 차지하지 않는다.**
          //    `Positioned.fill` + `OverflowBox`라 Stack 크기는 버튼이 정한다 —
          //    자리를 먹으면 녹음을 시작하는 순간 마이크가 손 밑에서 밀려난다.
          if (listening)
            Positioned.fill(
              child: IgnorePointer(
                child: OverflowBox(
                  maxWidth: size + bloom * 2,
                  maxHeight: size + bloom * 2,
                  child: _MicRipple(
                    key: rippleKey,
                    diameter: size + bloom * 2,
                    startRadius: size / 2,
                    spread: bloom,
                  ),
                ),
              ),
            ),
          if (listening)
            Positioned.fill(
              child: IgnorePointer(
                child: OverflowBox(
                  maxWidth: size + bloom * 2,
                  maxHeight: size + bloom * 2,
                  child: _MicEqualizer(
                    key: eqKey,
                    diameter: size + bloom * 2,
                    buttonRadius: size / 2,
                    level: level.clamp(0.0, 1.0),
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

/// 버튼에서 번져 나가는 파문.
///
/// 물에 돌을 던졌을 때처럼 원이 밖으로 커지면서 옅어진다. 원 셋이 시차를
/// 두고 이어 나가서 끊기지 않고 계속 번지는 것처럼 보인다.
///
/// 실제 오디오 레벨은 [_MicEqualizer]가 맡는다. 파문은 "듣고 있다"는
/// 지속 신호다.
class _MicRipple extends StatefulWidget {
  const _MicRipple({
    super.key,
    required this.diameter,
    required this.startRadius,
    required this.spread,
  });

  final double diameter;

  /// 파문이 시작하는 반지름 — 버튼 가장자리다.
  final double startRadius;

  /// 얼마나 멀리 번져 나가는지.
  final double spread;

  @override
  State<_MicRipple> createState() => _MicRippleState();
}

class _MicRippleState extends State<_MicRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    // 느긋하게 번져야 물결처럼 보인다. 빠르면 경고등처럼 읽힌다.
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 기기에서 애니메이션을 꺼 둔 사용자에게는 돌리지 않는다. 멈춘 파문이라도
    // 녹음 중이라는 건 정지 사각이 알려준다.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 0.35;
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
        painter: _MicRipplePainter(
          t: _c.value,
          startRadius: widget.startRadius,
          spread: widget.spread,
        ),
      ),
    ),
  );
}

class _MicRipplePainter extends CustomPainter {
  const _MicRipplePainter({
    required this.t,
    required this.startRadius,
    required this.spread,
  });

  final double t;
  final double startRadius;
  final double spread;

  /// 동시에 번지는 원의 수. 셋이면 앞선 원이 사라지기 전에 다음이 출발한다.
  static const _waves = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    for (var i = 0; i < _waves; i++) {
      // 원마다 출발 시각을 어긋나게 둔다.
      final p = (t + i / _waves) % 1.0;

      // 멀어질수록 옅어지고 가늘어진다 — 물결이 잦아드는 모양이다.
      final fade = 1 - p;
      canvas.drawCircle(
        center,
        startRadius + p * spread,
        Paint()
          ..color = AppColors.warm.withValues(alpha: fade * 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1 + fade * 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_MicRipplePainter old) =>
      old.t != t || old.startRadius != startRadius || old.spread != spread;
}

/// 버튼 바깥을 도는 음량 EQ 링.
///
/// 단일 [level]을 막대마다 위상만 다르게 펼친다(진짜 FFT 아님).
/// 파문보다 안쪽에 그려서 물결이 바깥으로 더 멀리 보이게 한다.
class _MicEqualizer extends StatefulWidget {
  const _MicEqualizer({
    super.key,
    required this.diameter,
    required this.buttonRadius,
    required this.level,
  });

  final double diameter;
  final double buttonRadius;
  final double level;

  @override
  State<_MicEqualizer> createState() => _MicEqualizerState();
}

class _MicEqualizerState extends State<_MicEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 0;
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
        painter: _MicEqualizerPainter(
          t: _c.value,
          buttonRadius: widget.buttonRadius,
          level: widget.level,
          frozen: MediaQuery.disableAnimationsOf(context),
        ),
      ),
    ),
  );
}

class _MicEqualizerPainter extends CustomPainter {
  const _MicEqualizerPainter({
    required this.t,
    required this.buttonRadius,
    required this.level,
    required this.frozen,
  });

  final double t;
  final double buttonRadius;
  final double level;
  final bool frozen;

  static const _bars = 24;
  static const _gapFromButton = 6.0;
  static const _minLen = 3.0;
  static const _maxLen = 14.0;
  static const _barWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = AppColors.warm
      ..strokeWidth = _barWidth
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < _bars; i++) {
      final angle = (i / _bars) * math.pi * 2;
      // 단일 레벨을 위상만 다르게 — 침묵이면 거의 최소, 크면 들쭉날쭉.
      final phase = math.sin((t * math.pi * 2) + i * 0.55);
      final wobble = frozen ? 0.35 : 0.55 + 0.45 * phase;
      final len = _minLen + (_maxLen - _minLen) * level * wobble;

      final inner = buttonRadius + _gapFromButton;
      final outer = inner + len;
      final dx = math.cos(angle);
      final dy = math.sin(angle);

      canvas.drawLine(
        Offset(center.dx + dx * inner, center.dy + dy * inner),
        Offset(center.dx + dx * outer, center.dy + dy * outer),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MicEqualizerPainter old) =>
      old.t != t ||
      old.buttonRadius != buttonRadius ||
      old.level != level ||
      old.frozen != frozen;
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
