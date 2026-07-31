import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Figma에서 내보낸 아이콘 에셋 목록.
///
/// 직접 Path로 옮겨 그리면 시안과 미세하게 어긋나므로 전부 에셋을 쓴다.
/// 파일은 `assets/icons/`에 있고, 새 아이콘이 생기면 여기 한 줄만 늘린다.
enum AppIcons {
  chevronLeft('chevron_left'),
  moreVertical('more_vertical'),
  speaker('speaker'),
  mic('mic'),
  keyboard('keyboard'),
  bell('bell'),
  tabHome('tab_home'),
  tabWrite('tab_write'),
  tabBook('tab_book'),
  tabSettings('tab_settings');

  const AppIcons(this.file);

  final String file;

  String get path => 'assets/icons/$file.svg';
}

/// 아이콘 하나를 그린다.
///
/// ⚠️ 에셋의 획 색은 내보낸 시점의 색이 박혀 있다. 같은 아이콘을 다른 색으로
///    써야 하면(탭바 활성/비활성) [color]를 넘겨 덧칠한다. null이면 에셋
///    원본 색을 그대로 쓴다.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, required this.size, this.color});

  final AppIcons icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    icon.path,
    width: size,
    height: size,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}
