import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/network/api_client.dart';
import 'package:life_legacy/core/network/mock_api_client.dart';
import 'package:life_legacy/core/route/app_pages.dart';

import 'question_edit_sheet.dart';
import 'write_controller.dart';

/// D1~D5가 공유하는 머리 부분 — Figma 341:647.
///
/// `←` · 장 제목 · `⋯` / 전체폭 진행바 / "질문 3 / 6".
/// 다섯 화면이 모두 이 세 줄로 시작하므로 한 곳에 모아 뒀다 — 예전에는
/// 단계마다 따로 그려서 여백이 조금씩 달랐다.
class WriteHeader extends GetView<WriteController> {
  const WriteHeader({super.key, this.showProgressLabel = true});

  /// D4·D5는 진행바 아래에 "질문 3 / 6" 대신 제목이 온다.
  final bool showProgressLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTopBar(
          title: controller.headerTitle,
          // ⚠️ `Get.back()`을 쓰면 **앱이 꺼진다.** 탭 전환이 `offNamed`라
          //    작성 화면이 홈을 갈아 끼운 상태여서 스택에 돌아갈 곳이 없다.
          //    작성에는 탭바도 없으니(시안 D1~D5) 나가는 길은 이 화살표뿐이다.
          onBack: () {
            // 키보드를 먼저 내린다 — 올라온 채로 넘어가면 다음 화면이
            // 짧은 본문으로 그려진다(홈 뼈대가 46px 넘쳤던 원인).
            FocusManager.instance.primaryFocus?.unfocus();
            Get.offNamed(AppRoutes.home);
          },
          trailing: _MoreButton(),
        ),
        Obx(
          () => AppProgressBar(
            value: controller.chapterProgress,
            height: 4,
            rounded: false,
          ),
        ),
        if (showProgressLabel)
          Padding(
            // 시안 341:653 — 진행바(100~104) 아래 10.
            padding: const EdgeInsets.fromLTRB(AppDimens.gutter, 10, 0, 0),
            child: Obx(
              () => Text(controller.progressLabel, style: AppTypography.metaLabel),
            ),
          ),
      ],
    );
  }
}

/// `⋯` — 이 질문에 대해 할 수 있는 나머지 동작.
class _MoreButton extends GetView<WriteController> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '더 보기',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showMenu(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Text(
            '⋯',
            style: AppTypography.weight(
              AppTypography.titlePage,
              AppTypography.bold,
            ).copyWith(
              fontSize: 22,
              height: 1.0,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    final api = Get.find<ApiClient>();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusSheet),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 꼬리질문 단계에서는 뺀다 — 그 질문에는 이미 답을 했고,
            // 지금 문구를 바꾸면 곧 저장될 답과 어긋난다.
            if (controller.canEditQuestion)
              AppSettingRow(
                title: '질문 문구 고치기',
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final next = await showQuestionEditSheet(
                    context,
                    question: controller.displayQuestion,
                  );
                  if (next != null) await controller.editQuestionText(next);
                },
              ),
            AppSettingRow(
              title: '이 질문 건너뛰기',
              onTap: () {
                Navigator.of(sheetContext).pop();
                controller.skip();
              },
            ),
            // ⚠️ 목업 전용. 실패 화면 둘을 손으로 확인하려고 둔 것이다.
            //    실제 API가 붙으면 이 두 줄과 `MockApiClient`의 같은 이름
            //    스위치를 함께 지운다.
            //
            //    두 실패는 **결과가 다르다** — 저장 실패(D5)는 적은 글이
            //    살아 있어 버튼만 다시 누르면 되지만, 꼬리질문 실패(D8)는
            //    서버가 1차 답변을 버려서 질문부터 다시 답해야 한다.
            if (api is MockApiClient) ...[
              AppSettingRow(
                title: '목업 · 다음 저장을 실패시키기 (D5)',
                onTap: () {
                  api.failNextSave = true;
                  Navigator.of(sheetContext).pop();
                },
              ),
              AppSettingRow(
                title: '목업 · 다음 꼬리질문을 실패시키기 (D8)',
                onTap: () {
                  api.failNextFollowup = true;
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
