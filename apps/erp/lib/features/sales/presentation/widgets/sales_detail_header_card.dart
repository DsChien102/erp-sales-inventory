import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import '../models/sales_order/sales_order_detail_vm.dart';
import 'sales_amount_highlight_row.dart';

class SalesDetailHeaderCard extends StatelessWidget {
  const SalesDetailHeaderCard({
    super.key,
    required this.vm,
    this.totalAmountMinor,
    this.showTotal = true,
  });

  final SalesOrderDetailVm vm;
  final int? totalAmountMinor;
  final bool showTotal;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final displayOrderNumber = vm.orderNumber.startsWith('#')
        ? vm.orderNumber
        : '#${vm.orderNumber}';

    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: #OrderNumber + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VText(
                    displayOrderNumber,
                    variant: VTextVariant.headingH3Mono,
                    style: const TextStyle(fontWeight: FontWeight.w400),
                  ),
                  const VGap.xs(),
                  VText(
                    vm.createdAtFormatted,
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                  const VGap.sm(),
                ],
              ),
              _buildStatusBadge(context),
            ],
          ),

          VText(
            vm.customerName,
            variant: VTextVariant.bodyDefault,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const VGap.xs(),
          VText(
            vm.customerPhone.isEmpty ? 'Không có số điện thoại' : vm.customerPhone,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),

          if (showTotal) ...[
            const VGap.md(),

            // Row 4: Highlight box for Tổng đơn
            SalesAmountHighlightRow(
              label: 'Tổng đơn',
              amountMinor: totalAmountMinor ?? vm.totalAmountMinor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    switch (vm.lifecycleStatus) {
      case SalesOrderLifecycleStatus.committed:
        return const VBadge(
          label: 'Hoàn tất',
          tone: VComponentTone.success,
        );
      case SalesOrderLifecycleStatus.cancelled:
        return const VBadge(
          label: 'Đã hủy',
          tone: VComponentTone.danger,
        );
      case SalesOrderLifecycleStatus.draft:
        return const VBadge(
          label: 'Đơn nháp',
        );
    }
  }
}
