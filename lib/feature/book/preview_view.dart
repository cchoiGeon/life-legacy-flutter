import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/shared/tab_scaffold.dart';

import 'preview_controller.dart';

/// E2 책 미리보기 — Figma 352:894.
///
/// ⚠️ 색이 뒤집혔다. 예전에는 크림 배경 위에 흰 종이를 얹었는데, 시안은
///    **흰 배경 위에 크림 종이**다. 실제 책 종이가 흰색이 아니라 미색이라
///    이쪽이 인쇄본에 가깝다.
class BookPreviewView extends GetView<BookPreviewController> {
  const BookPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return TabScaffold(
      tab: AppTab.book,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: AppSpinner());
        }
        final page = controller.page;
        return Column(
          children: [
            AppTopBar(
              title: controller.title,
              trailing: AppTextAction(
                label: '보내기',
                onTap: controller.share,
              ),
            ),
            Expanded(
              child: page == null
                  ? const _EmptyBook()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimens.gutter,
                        AppDimens.space3,
                        AppDimens.gutter,
                        AppDimens.space4,
                      ),
                      child: _Paper(page: page),
                    ),
            ),
            if (page != null) const _PageNav(),
          ],
        );
      }),
    );
  }
}

/// 종이 한 장 — 크림 바탕에 명조 (시안 352:898).
class _Paper extends StatelessWidget {
  const _Paper({required this.page});

  final BookPage page;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 22),
      decoration: BoxDecoration(
        color: AppColors.cream,
        // 반경 6 — 카드(16)보다 훨씬 작다. 종이는 모서리가 거의 각지다.
        borderRadius: BorderRadius.circular(6),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        children: [
          Text(
            '제 ${page.chapterOrder} 장',
            style: AppTypography.weight(
              AppTypography.label,
              AppTypography.medium,
            ).copyWith(
              fontSize: 11,
              letterSpacing: 2.4,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            page.chapterTitle,
            textAlign: TextAlign.center,
            style: AppTypography.bookTitle.copyWith(
              fontSize: 23,
              height: 1.3,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Container(width: 44, height: 1, color: AppColors.btnMuted),
          const SizedBox(height: 22),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, p) in page.paragraphs.indexed) ...[
                    // 문단 사이는 빈 줄 하나 — 시안이 판면에 빈 행을 넣었다.
                    if (i > 0) const SizedBox(height: 29),
                    Text(
                      p,
                      style: AppTypography.bookBody.copyWith(
                        fontSize: 15,
                        height: 29 / 15,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space4),
          Text(
            '${page.pageNumber}',
            style: AppTypography.bookBody.copyWith(
              fontSize: 12,
              height: 1.4,
              letterSpacing: 0.6,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "← 이전   12 / 34쪽   다음 →" (시안 352:908).
class _PageNav extends GetView<BookPreviewController> {
  const _PageNav();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutter,
        0,
        AppDimens.gutter,
        AppDimens.space4,
      ),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            _NavAction(
              label: '← 이전',
              enabled: controller.hasPrev,
              onTap: controller.prev,
            ),
            const Spacer(),
            Text(
              controller.pageLabel,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const Spacer(),
            _NavAction(
              label: '다음 →',
              enabled: controller.hasNext,
              onTap: controller.next,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavAction extends StatelessWidget {
  const _NavAction({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              // 끝 쪽에서는 흐려진다 — 눌러도 아무 일이 없는 걸 미리 알린다.
              color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBook extends StatelessWidget {
  const _EmptyBook();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.gutter),
      child: Text(
        '아직 완성된 장이 없어요.\n질문에 답하시면 여기에 실려요.',
        textAlign: TextAlign.center,
        style: AppTypography.subtitle,
      ),
    ),
  );
}
