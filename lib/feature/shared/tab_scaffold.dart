import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/route/app_pages.dart';

/// 탭 4개가 공유하는 껍데기.
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

  static const _routes = {
    AppTab.home: AppRoutes.home,
    AppTab.write: AppRoutes.write,
    AppTab.book: AppRoutes.book,
    AppTab.settings: AppRoutes.settings,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      body: body,
      bottomNavigationBar: AppTabBar(
        current: tab,
        onSelect: (next) {
          if (next == tab) return;
          // `offNamed` — 탭끼리는 쌓이지 않게 한다. 뒤로가기를 눌렀을 때
          // 지나온 탭을 되짚는 건 이 앱의 흐름과 맞지 않는다.
          Get.offNamed(_routes[next]!);
        },
      ),
    );
  }
}
