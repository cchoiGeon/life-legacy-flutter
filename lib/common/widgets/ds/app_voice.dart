import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 큰 원형 녹음 버튼 — Figma 341:660 (대기) · 350:889 (녹음 중).
///
/// ⚠️ 색은 **두 상태 모두 브랜드 브라운**이다. 예전에는 녹음 중에 청록으로
///    바뀌었지만, 새 시안은 색을 그대로 두고 **글리프만** 마이크 → 정지 사각으로
///    바꾼다. "지금 듣고 있다"는 위에 뜨는 [AppWaveform]과 "듣고 있어요 · 0:23"
///    문구가 알려준다 — 원까지 같이 변하면 화면에서 바뀌는 곳이 셋이 된다.
///
/// 퍼지는 링도 없앴다. 시안에 없고, 파형과 겹쳐 보여서 둘 다 산만해진다.
class AppMicButton extends StatelessWidget {
  const AppMicButton({
    super.key,
    required this.recording,
    required this.onTap,
    this.size = 160,
  });

  final bool recording;
  final VoidCallback onTap;

  /// 시안 실측 160. 이 화면의 유일한 조작이라 크게 잡는다.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: recording ? '녹음 끝내기' : '눌러서 시작하세요',
      child: GestureDetector(
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
      ),
    );
  }
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

/// 녹음 중 파형 — Figma 350:911.
///
/// 막대 12개 · 폭 5 · 간격 4 · 반경 2.5 · 색 `warm`. 시안은 정지 그림이라
/// 높이가 고정돼 있지만, 실제로는 "듣고 있다"는 신호라 움직여야 한다 —
/// 사인파 두 개를 겹쳐 흘린다.
///
/// ⚠️ 실제 오디오 레벨이 아니다. `speech_to_text`가 음량을 주지 않기 때문이다.
///    레벨을 받을 수 있게 되면 [_WavePainter]의 amp 계산만 갈아 끼우면 된다.
class AppWaveform extends StatefulWidget {
  const AppWaveform({super.key, this.barCount = 12, this.height = 34});

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
    // 폭 5 + 간격 4 — 막대 수가 바뀌어도 시안 간격을 유지한다.
    const barWidth = 5.0;
    const gap = 4.0;

    return SizedBox(
      height: widget.height,
      width: widget.barCount * barWidth + (widget.barCount - 1) * gap,
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
    final paint = Paint()..color = AppColors.warm;
    const barWidth = 5.0;
    const gap = 4.0;

    // 시안의 가장 짧은 막대 5, 가장 긴 막대 28.
    const minHeight = 5.0;
    const maxHeight = 28.0;

    for (var i = 0; i < bars; i++) {
      final phase = t * 2 * math.pi + i * 0.7;
      // 두 주파수를 겹쳐서 규칙적으로 보이지 않게 한다.
      final amp =
          math.sin(phase).abs() * 0.7 + math.sin(phase * 0.37).abs() * 0.3;
      final h = minHeight + amp * (maxHeight - minHeight);
      final x = i * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, (size.height - h) / 2, barWidth, h),
          const Radius.circular(2.5),
        ),
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
