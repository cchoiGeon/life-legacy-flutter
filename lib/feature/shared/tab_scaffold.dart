import 'package:flutter/material.dart';

import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/feature/shared/app_shell.dart';

export 'app_shell.dart' show AppMenuButton, AppShell, AppShellScope;

/// 탭 4개가 공유하는 껍데기 — 하단 탭바 + 오른쪽 메뉴.
///
/// 탭은 각각 독립 라우트다(IndexedStack이 아니다). 시안의 탭 화면들이
/// 서로 다른 배경색·상단바를 쓰고, 탭을 옮길 때 목록을 새로 불러오는 게
/// 자연스러워서다. 대신 탭 전환에는 애니메이션을 주지 않는다.
class TabScaffold extends StatelessWidget {
  const TabScaffold({
    super.key,
    required this.tab,
    required this.body,
    this.backgroundColor,
  });

  final AppTab tab;
  final Widget body;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      tab: tab,
      backgroundColor: backgroundColor,
      body: body,
    );
  }
}
