import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 카드 — Figma `Card`(130:2171 · 130:2180).
///
/// [warm]이면 크림 배경(`#f5f0e8`), 아니면 흰 카드 + 옅은 테두리.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.warm = false,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final bool warm;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: warm ? AppColors.cream : AppColors.brandFg,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: warm ? AppColors.cream : AppColors.stone100,
          width: AppDimens.borderWidth,
        ),
        boxShadow: AppShadows.sm,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

/// 진행률 바 — 앱의 **유일한** 진행률 표시.
///
/// 시안 실측(홈 11 · 자기소개 07·08 · 작성 13)에서 공통인 것:
///   · 트랙 `#f0ebe3` (bubbleSys) — 세 곳이 모두 같다
///   · 반경 = 높이 / 2
/// 다른 것은 높이와 채움색뿐이라 그 둘만 파라미터로 뺐다.
///
/// ⚠️ 예전에는 자기소개가 5칸 분절 바를 따로 썼다(`AppStepBar`). 한 장의
///    문항 수가 6~8개로 다르고 더 늘어날 수 있어서 분절은 칸이 실처럼
///    얇아진다. 개수는 옆의 "1 / 5" · "질문 3 / 6" 텍스트가 알려주므로
///    연속형 하나로 통일했다.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.fill,
    this.onBrand = false,
    this.rounded = true,
  });

  /// 0.0 ~ 1.0
  final double value;

  /// 시안: 자기소개·작성 상단 4(전체폭) · 홈/자서전 카드 8
  final double height;

  /// 기본은 warm. 홈 카드처럼 강조가 필요하면 brand를 넘긴다.
  final Color? fill;

  /// 브랜드색 배경 위에 얹히는 변형(트랙이 반투명 흰색).
  final bool onBrand;

  /// 시안 345:721처럼 **화면 가장자리까지 닿는** 진행바는 모서리를 굴리지
  /// 않는다. 굴리면 화면 끝에서 바가 떠 보인다.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final radius = rounded
        ? BorderRadius.circular(height / 2)
        : BorderRadius.zero;
    return Semantics(
      value: '${(clamped * 100).round()}%',
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          height: height,
          width: double.infinity,
          color: onBrand
              ? AppColors.progressTrackOnBrand
              : AppColors.progressTrack,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clamped,
            child: AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.standard,
              decoration: BoxDecoration(
                color: onBrand
                    ? AppColors.progressFillOnBrand
                    : (fill ?? AppColors.progressFill),
                borderRadius: radius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 스켈레톤 조각 — Figma `Skeleton`(130:2192).
/// 첫 로딩에서 카드 자리를 잡아준다.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 7,
  });

  const AppSkeleton.circle({super.key, required double size})
    : width = size,
      height = size,
      radius = 999;

  final double width;
  final double height;
  final double radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      // 0.5 ~ 1.0 사이만 오가게 해서 깜빡임이 거슬리지 않게 한다.
      opacity: Tween<double>(begin: 0.5, end: 1).animate(_c),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.stone200,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// 화면 가운데 도는 링 — 시안 09번 "목차를 준비하고 있어요".
class AppSpinner extends StatefulWidget {
  const AppSpinner({super.key, this.size = 64, this.stroke = 5, this.color});

  final double size;
  final double stroke;
  final Color? color;

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

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
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _RingPainter(
            turns: _c.value,
            stroke: widget.stroke,
            color: widget.color ?? AppColors.brand,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.turns,
    required this.stroke,
    required this.color,
  });

  final double turns;
  final double stroke;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    // 3/4 원호. 나머지 1/4이 뚫려 있어 회전이 보인다.
    canvas.drawArc(rect, turns * 2 * 3.1415926, 1.5 * 3.1415926, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.turns != turns;
}

/// 브랜드 원 안에 이름 첫 글자 — Figma `avatar`(130:2238).
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.initial, this.size = 34});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.brand,
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: AppTypography.weight(
          AppTypography.bodyChat,
          AppTypography.medium,
        ).copyWith(color: AppColors.brandFg, fontSize: size * 0.44),
      ),
    );
  }
}

/// "Life Legacy" 워드마크 — 명조 Bold (시안 A1 · A2 · C1).
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.fontSize = 30, this.letterSpacing = 0.3});

  final double fontSize;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) => Text(
    'Life Legacy',
    style: AppTypography.wordmark.copyWith(
      fontSize: fontSize,
      letterSpacing: letterSpacing,
    ),
  );
}

/// 브랜드 마크 — 브랜드색 원 안에 펼친 책 두 쪽 (시안 341:723).
///
/// 예전 로고는 나뭇잎이었다. 새 시안은 **책**이다 — 앱이 만들어 주는 결과물이
/// 무엇인지 심볼만 봐도 알게 한 것이다.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 84});

  final double size;

  @override
  Widget build(BuildContext context) {
    // 시안 84 기준 좌표를 그대로 비율로 쓴다.
    final k = size / 84;
    Widget page({required double left, required double opacity}) => Positioned(
      left: left * k,
      top: 27 * k,
      width: 22 * k,
      height: 30 * k,
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.brandFg,
            borderRadius: BorderRadius.circular(3 * k),
          ),
        ),
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
            ),
          ),
          page(left: 18, opacity: 1),
          // 오른쪽 쪽은 살짝 흐리다 — 펼친 책의 안쪽 면이 진 그늘이다.
          page(left: 44, opacity: 0.72),
        ],
      ),
    );
  }
}
