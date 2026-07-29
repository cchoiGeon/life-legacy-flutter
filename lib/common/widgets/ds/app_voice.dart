import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/typography.dart';

import 'app_icon.dart';

/// 큰 원형 녹음 버튼 — 시안 07·13·14번의 중심 요소.
///
/// 대기 상태는 브랜드 브라운, 녹음 중은 청록(accent-soft)으로 바뀌고
/// 바깥으로 퍼지는 링이 돈다. 시니어 사용자가 "지금 듣고 있다"를 색과 움직임
/// 두 가지로 알 수 있게 한 것이다.
class AppMicButton extends StatefulWidget {
  const AppMicButton({
    super.key,
    required this.recording,
    required this.onTap,
    this.size = 116,
  });

  final bool recording;
  final VoidCallback onTap;
  final double size;

  @override
  State<AppMicButton> createState() => _AppMicButtonState();
}

class _AppMicButtonState extends State<AppMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.recording) _pulse.repeat();
  }

  @override
  void didUpdateWidget(AppMicButton old) {
    super.didUpdateWidget(old);
    if (widget.recording && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.recording && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.recording ? AppColors.accentSoft : AppColors.brand;

    return Semantics(
      button: true,
      label: widget.recording ? '녹음 멈추기' : '누르고 말씀하세요',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.size * 1.5,
          height: widget.size * 1.5,
          child: Center(
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => CustomPaint(
                painter: _PulsePainter(
                  progress: widget.recording ? _pulse.value : null,
                  color: color,
                  radius: widget.size / 2,
                ),
                child: child,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: widget.size,
                height: widget.size,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                // 시안 148:203 — 원 112 안에 아이콘 40 (비율 0.357)
                child: AppIcon(
                  AppIcons.mic,
                  size: widget.size * 40 / 112,
                  color: AppColors.brandFg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 녹음 중 바깥으로 퍼지는 링. [progress]가 null이면 아무것도 그리지 않는다.
class _PulsePainter extends CustomPainter {
  const _PulsePainter({
    required this.progress,
    required this.color,
    required this.radius,
  });

  final double? progress;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    if (t == null) return;

    final center = Offset(size.width / 2, size.height / 2);
    // 링 두 개를 반 주기 어긋나게 띄워서 끊김 없이 이어지게 한다.
    for (final offset in [0.0, 0.5]) {
      final p = (t + offset) % 1.0;
      canvas.drawCircle(
        center,
        radius + p * radius * 0.55,
        Paint()
          ..color = color.withValues(alpha: (1 - p) * 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.progress != progress;
}

/// 녹음 중 파형 — 시안 14번의 막대 그래프.
///
/// 실제 오디오 레벨이 아니라 사인파를 시간으로 흘려 만든 **가짜 파형**이다.
/// 마이크 입력이 붙으면 [levels]에 실측값을 넣도록 바꾸면 된다.
class AppWaveform extends StatefulWidget {
  const AppWaveform({super.key, this.barCount = 24, this.height = 32});

  final int barCount;
  final double height;

  @override
  State<AppWaveform> createState() => _AppWaveformState();
}

class _AppWaveformState extends State<AppWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _WavePainter(t: _c.value, bars: widget.barCount),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.t, required this.bars});

  final double t;
  final int bars;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final gap = size.width / bars;
    for (var i = 0; i < bars; i++) {
      final phase = t * 2 * math.pi + i * 0.7;
      // 두 주파수를 겹쳐서 규칙적으로 보이지 않게 한다.
      final amp =
          (math.sin(phase).abs() * 0.7 + math.sin(phase * 0.37).abs() * 0.3);
      final barHeight = size.height * (0.15 + amp * 0.85);
      final x = gap * (i + 0.5);
      canvas.drawLine(
        Offset(x, (size.height - barHeight) / 2),
        Offset(x, (size.height + barHeight) / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
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
