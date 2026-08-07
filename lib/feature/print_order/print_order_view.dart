import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:life_legacy/common/constants/colors.dart';
import 'package:life_legacy/common/constants/dimens.dart';
import 'package:life_legacy/common/constants/typography.dart';
import 'package:life_legacy/common/widgets/ds/ds.dart';
import 'package:life_legacy/data/data_manager.dart';

import 'print_order_controller.dart';

/// 종이책 주문 — 배송지 · 부수 · 신청 (결제 없음).
class PrintOrderView extends GetView<PrintOrderController> {
  const PrintOrderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const AppTopBar(title: '종이책 주문'),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: AppSpinner());
              }
              final book = controller.book.value;
              final address = controller.address.value;
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutter,
                  12,
                  AppDimens.gutter,
                  AppDimens.space8,
                ),
                children: [
                  Text(
                    book?.title ?? '나의 자서전',
                    style: AppTypography.titlePage,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '앱에서는 신청만 접수해요. 결제는 웹사이트에서 진행됩니다.',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '배송지',
                    style: AppTypography.weight(
                      AppTypography.bodyBase,
                      AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AddressCard(
                    address: address,
                    onEdit: controller.openAddressEditor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '부수 (4권부터)',
                    style: AppTypography.weight(
                      AppTypography.bodyBase,
                      AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(() {
                    final q = controller.quantity.value;
                    return Row(
                      children: [
                        _QtyButton(
                          icon: Icons.remove_rounded,
                          onTap: () => controller.setQuantity(q - 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            '$q권',
                            style: AppTypography.weight(
                              AppTypography.titleSection,
                              AppTypography.bold,
                            ),
                          ),
                        ),
                        _QtyButton(
                          icon: Icons.add_rounded,
                          onTap: () => controller.setQuantity(q + 1),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                  Text(
                    '요청사항 (선택)',
                    style: AppTypography.weight(
                      AppTypography.bodyBase,
                      AppTypography.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller.noteController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: '배송 시 요청사항을 적어 주세요',
                      hintStyle: AppTypography.bodySm.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      filled: true,
                      fillColor: AppColors.cream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8C96A)),
                    ),
                    child: Text(
                      '실물책 신청 후에는 내용 수정·사진 추가·신청 정보 수정이 불가능해요.\n'
                      '결제는 웹에서 진행되며, 여기서는 신청만 남겨 둡니다.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimens.gutter,
              8,
              AppDimens.gutter,
              AppInsets.bottom(context, 16),
            ),
            child: Obx(
              () => AppButton(
                label: controller.isSubmitting.value ? '신청 중…' : '신청하기',
                size: AppButtonSize.lg,
                block: true,
                enabled: !controller.isSubmitting.value,
                onPressed: controller.submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.onEdit});

  final Address? address;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final complete = address?.isComplete == true;
    return Material(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: complete
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address!.recipient,
                          style: AppTypography.weight(
                            AppTypography.bodyBase,
                            AppTypography.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '변경',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Address.formatPhone(address!.phone),
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address!.oneLine,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        '배송지를 등록해 주세요',
                        style: AppTypography.bodyBase.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '등록',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppColors.brand),
        ),
      ),
    );
  }
}
