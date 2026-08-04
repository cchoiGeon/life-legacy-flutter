import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'toc_controller.dart';

/// 목차 확인 · 편집 · 저장 완료 — 03-1.
class TocView extends GetView<TocController> {
  const TocView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.isSaved.value) {
            return const _SavedBody();
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  30,
                  AppDimens.gutter,
                  0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: AppScreenHeading(
                    title: controller.isEditing.value
                        ? '목차를\n수정할까요?'
                        : '이런 순서로\n써볼까요?',
                    subtitle: controller.isEditing.value
                        ? '이름 바꾸기 · 삭제 · 추가 · 순서 변경'
                        : '나중에 바꿀 수 있어요',
                  ),
                ),
              ),
              const SizedBox(height: 33),
              Expanded(child: _ChapterList(controller: controller)),
              if (controller.isEditing.value)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.gutter,
                    0,
                    AppDimens.gutter,
                    8,
                  ),
                  child: AppButton(
                    label: '추가하기',
                    size: AppButtonSize.md,
                    block: true,
                    variant: AppButtonVariant.outline,
                    onPressed: () => _openAddSheet(context),
                  ),
                ),
              Padding(
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
                        label: '저장하기',
                        size: AppButtonSize.lg,
                        block: true,
                        loading: controller.isConfirming.value ||
                            controller.isSavingDraft.value,
                        onPressed: controller.confirm,
                      ),
                    ),
                    const SizedBox(height: AppDimens.space4),
                    Obx(
                      () => Semantics(
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            if (controller.isEditing.value) {
                              await controller.exitEdit();
                            } else {
                              controller.enterEdit();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              controller.isEditing.value ? '다 바꿨어요' : '수정하기',
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
          );
        }),
      ),
    );
  }

  Future<void> _openAddSheet(BuildContext context) async {
    final catalog = await controller.loadCatalog();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddSheet(
        catalog: catalog,
        onAdd: (picked, customTitle) {
          if (picked.isNotEmpty) controller.addFromCatalog(picked);
          if (customTitle != null && customTitle.trim().isNotEmpty) {
            controller.addCustom(customTitle);
          }
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class _SavedBody extends GetView<TocController> {
  const _SavedBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        80,
        AppDimens.gutter,
        58,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppScreenHeading(
            title: '에디션 1 목차가\n저장되었습니다',
            subtitle: '이제 이야기를 적어 볼 수 있어요',
          ),
          const Spacer(),
          AppButton(
            label: '자서전 작성하러 가기',
            size: AppButtonSize.lg,
            block: true,
            onPressed: controller.goWrite,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: '홈으로 가기',
            size: AppButtonSize.lg,
            block: true,
            variant: AppButtonVariant.outline,
            onPressed: controller.goBookHub,
          ),
        ],
      ),
    );
  }
}

class _ChapterList extends StatelessWidget {
  const _ChapterList({required this.controller});

  final TocController controller;

  static const _padding = EdgeInsets.symmetric(horizontal: AppDimens.gutter);
  static const _gap = 9.0;

  @override
  Widget build(BuildContext context) => Obx(_build);

  Widget _build() {
    final chapters = controller.chapters;
    final editing = controller.isEditing.value;

    if (!editing) {
      return ListView.separated(
        padding: _padding,
        itemCount: chapters.length,
        separatorBuilder: (_, _) => const SizedBox(height: _gap),
        itemBuilder: (_, i) => _ChapterCard(
          number: i + 1,
          chapter: chapters[i],
          editing: false,
          onRename: null,
          onDelete: null,
        ),
      );
    }

    return ReorderableListView.builder(
      padding: _padding,
      itemCount: chapters.length,
      onReorderItem: controller.reorder,
      proxyDecorator: (child, _, animation) => AnimatedBuilder(
        animation: animation,
        builder: (_, _) => Transform.scale(
          scale: 1 + 0.03 * animation.value,
          child: child,
        ),
      ),
      itemBuilder: (context, i) => Padding(
        key: ValueKey(chapters[i].id),
        padding: const EdgeInsets.only(bottom: _gap),
        child: _ChapterCard(
          number: i + 1,
          chapter: chapters[i],
          editing: true,
          onRename: () => _promptRename(context, i),
          onDelete: () => controller.removeAt(i),
        ),
      ),
    );
  }

  Future<void> _promptRename(BuildContext context, int index) async {
    final current = controller.chapters[index].title;
    final field = TextEditingController(text: current);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('목차 이름'),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: const InputDecoration(hintText: '장 제목'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, field.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    field.dispose();
    if (next != null) controller.rename(index, next);
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.number,
    required this.chapter,
    required this.editing,
    required this.onRename,
    required this.onDelete,
  });

  final int number;
  final Chapter chapter;
  final bool editing;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

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
            child: GestureDetector(
              onTap: onRename,
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
          ),
          if (editing) ...[
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close, color: AppColors.stone400),
              visualDensity: VisualDensity.compact,
            ),
            const Icon(Icons.drag_handle, color: AppColors.stone400),
          ],
        ],
      ),
    );
  }
}

class _AddSheet extends StatefulWidget {
  const _AddSheet({required this.catalog, required this.onAdd});

  final List<CatalogChapter> catalog;
  final void Function(List<CatalogChapter> picked, String? customTitle) onAdd;

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _picked = <String>{};
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '목차 추가',
            style: AppTypography.weight(
              AppTypography.bodyBase,
              AppTypography.bold,
            ).copyWith(fontSize: 20),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final c in widget.catalog)
                  CheckboxListTile(
                    value: _picked.contains(c.id),
                    onChanged: c.alreadyAdded
                        ? null
                        : (v) => setState(() {
                              if (v == true) {
                                _picked.add(c.id);
                              } else {
                                _picked.remove(c.id);
                              }
                            }),
                    title: Text(c.title),
                    subtitle: Text(
                      c.alreadyAdded
                          ? '이미 추가됨'
                          : '질문 ${c.questionCount}개',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _custom,
            decoration: const InputDecoration(
              labelText: '새로운 목차 만들기',
              hintText: '예: 군대 이야기',
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: '넣기',
            size: AppButtonSize.lg,
            block: true,
            onPressed: () {
              final selected = widget.catalog
                  .where((c) => _picked.contains(c.id))
                  .toList();
              widget.onAdd(selected, _custom.text);
            },
          ),
        ],
      ),
    );
  }
}
