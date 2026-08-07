import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/core/route/app_pages.dart';
import 'package:life_legacy/data/data_manager.dart';
import 'package:life_legacy/feature/purchase/purchase_content.dart';
import 'package:life_legacy/feature/purchase/purchase_flow.dart';

/// 종이책 신청 완료.
class PrintOrderSuccessView extends StatelessWidget {
  const PrintOrderSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    PrintOrderResult? order;
    String bookTitle = '나의 자서전';
    Address? address;
    if (args is Map) {
      if (args['order'] is PrintOrderResult) {
        order = args['order'] as PrintOrderResult;
      }
      if (args['bookTitle'] is String) bookTitle = args['bookTitle'] as String;
      if (args['address'] is Address) address = args['address'] as Address;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.gutter,
            40,
            AppDimens.gutter,
            AppDimens.space6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppColors.warm,
              ),
              const SizedBox(height: 20),
              Text(
                '종이책 신청이 접수됐어요',
                textAlign: TextAlign.center,
                style: AppTypography.titlePage,
              ),
              const SizedBox(height: 12),
              Text(
                '결제는 웹사이트에서 이어서 진행해 주세요.\n'
                '신청 내용이 맞는지 확인해 주세요.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyBase.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Row('책', bookTitle),
                    if (order != null) ...[
                      const SizedBox(height: 10),
                      _Row('부수', '${order.quantity}권'),
                      const SizedBox(height: 10),
                      _Row('신청번호', order.id.substring(0, 8)),
                    ],
                    if (address != null) ...[
                      const SizedBox(height: 10),
                      _Row('받는 분', address.recipient),
                      const SizedBox(height: 10),
                      _Row('주소', address.oneLine),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: PurchaseContent.openWebsiteLabel,
                size: AppButtonSize.lg,
                block: true,
                onPressed: () => PurchaseFlow.openWebsiteForPurchase(context),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: '확인',
                size: AppButtonSize.lg,
                block: true,
                variant: AppButtonVariant.outline,
                onPressed: () => Get.until(
                  (route) =>
                      route.settings.name == AppRoutes.bookComplete ||
                      route.settings.name == AppRoutes.home ||
                      route.settings.name == AppRoutes.book ||
                      route.isFirst,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySm.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}
