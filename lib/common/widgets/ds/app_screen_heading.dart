import 'package:flutter/widgets.dart';

import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';

/// 화면 맨 위의 제목 한 덩어리 — Figma A·B·F 전 화면이 같은 자리에 쓴다.
///
/// 시안 좌표: 제목 y124 · 부제 y222. 상단 바(높이 56)가 y100에서 끝나므로
/// 제목까지 24, 제목(두 줄 84)에서 부제까지 14다.
///
/// ⚠️ 제목만 **명조**다. 시안이 "읽는 영역"과 "누르는 영역"을 서체로 가르기
///    때문에 여기에 고딕을 쓰면 화면 성격이 달라진다.
class AppScreenHeading extends StatelessWidget {
  const AppScreenHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.compact = false,
  });

  /// 줄바꿈(`\n`)은 시안이 끊은 자리를 그대로 쓴다.
  final String title;

  final String? subtitle;

  /// 진행바 아래에서 시작하는 화면(D4·D5)은 한 단계 작은 제목을 쓴다.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: compact
              ? AppTypography.titleSerifSm
              : AppTypography.titleScreen,
        ),
        if (subtitle != null) ...[
          SizedBox(height: compact ? AppDimens.space1 : 14),
          Text(subtitle!, style: AppTypography.subtitle),
        ],
      ],
    );
  }
}
