import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'toc_controller.dart';

/// B7 목차 제안 확인 — Figma 347:790.
///
/// 뒤로가기가 없다. 목차 생성 화면이 `offNamed`로 들어와 돌아갈 곳이 없다.
class TocView extends GetView<TocController> {
  const TocView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // `bottom: false` — 아래 여백을 시안(58)대로 화면 바닥 기준으로 잡는다.
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppDimens.gutter,
                30,
                AppDimens.gutter,
                0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: AppScreenHeading(
                  title: '이런 순서로\n써볼까요?',
                  subtitle: '나중에 바꿀 수 있어요',
                ),
              ),
            ),
            const SizedBox(height: 33),
            Expanded(child: _ChapterList(controller: controller)),
            Padding(
              // 시안 347:816 — "순서 바꾸기"가 786에서 끝나고 아래로 58이 남는다.
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutter,
                AppDimens.space4,
                AppDimens.gutter,
                58,
              ),
              child: Column(
                children: [
                  Obx(
                    () => AppButton(
                      label: '이대로 시작하기',
                      size: AppButtonSize.lg,
                      block: true,
                      loading: controller.isConfirming.value,
                      onPressed: controller.confirm,
                    ),
                  ),
                  const SizedBox(height: AppDimens.space4),
                  Obx(
                    () => Semantics(
                      button: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: controller.toggleReorder,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            controller.isReordering.value
                                ? '다 바꿨어요'
                                : '순서 바꾸기',
                            style: AppTypography.weight(
                              AppTypography.bodyBase,
                              AppTypography.bold,
                            ).copyWith(
                              color: AppColors.brand,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 제안된 장 목록.
///
/// 평소에는 그냥 목록이고, "순서 바꾸기"를 누르면 끌어 옮길 수 있게 바뀐다.
/// 두 경우가 같은 [_ChapterCard]를 그리므로 모드가 바뀌어도 카드가 튀지 않는다.
class _ChapterList extends StatelessWidget {
  const _ChapterList({required this.controller});

  final TocController controller;

  static const _padding = EdgeInsets.symmetric(horizontal: AppDimens.gutter);
  static const _gap = 9.0;

  /// ⚠️ Obx는 **여기 안**에 있어야 한다. 바깥에서 `Obx(() => _ChapterList(...))`
  ///    로 감싸면 Obx 클로저는 위젯을 만들기만 하고 실제 Rx 읽기는 이 build에서
  ///    일어난다 — 관찰 대상이 없다며 GetX 오류 화면이 뜬다.
  @override
  Widget build(BuildContext context) => Obx(_build);

  Widget _build() {
    final chapters = controller.chapters;

    if (!controller.isReordering.value) {
      return ListView.separated(
        padding: _padding,
        itemCount: chapters.length,
        separatorBuilder: (_, _) => const SizedBox(height: _gap),
        itemBuilder: (_, i) =>
            _ChapterCard(number: i + 1, chapter: chapters[i], draggable: false),
      );
    }

    return ReorderableListView.builder(
      padding: _padding,
      itemCount: chapters.length,
      // `onReorder`(구식)와 달리 newIndex가 이미 보정돼서 넘어온다.
      onReorderItem: controller.reorder,
      // 기본 그림자 대신 카드를 살짝 띄우기만 한다 — 크림 카드 위에 회색
      // 그림자가 지면 색이 탁해 보인다.
      proxyDecorator: (child, _, animation) => AnimatedBuilder(
        animation: animation,
        builder: (_, _) => Transform.scale(
          scale: 1 + 0.03 * animation.value,
          child: child,
        ),
      ),
      itemBuilder: (_, i) => Padding(
        key: ValueKey(chapters[i].id),
        padding: const EdgeInsets.only(bottom: _gap),
        child: _ChapterCard(number: i + 1, chapter: chapters[i], draggable: true),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.number,
    required this.chapter,
    required this.draggable,
  });

  final int number;
  final Chapter chapter;
  final bool draggable;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AppTypography.weight(
                AppTypography.bodySm,
                AppTypography.bold,
              ).copyWith(
                fontSize: 13,
                height: 1.2,
                color: AppColors.brandFg,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              chapter.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.weight(
                AppTypography.bodyBase,
                AppTypography.bold,
              ).copyWith(fontSize: 17, height: 1.3, letterSpacing: -0.2),
            ),
          ),
          if (draggable) const Icon(Icons.drag_handle, color: AppColors.stone400),
        ],
      ),
    );
  }
}
