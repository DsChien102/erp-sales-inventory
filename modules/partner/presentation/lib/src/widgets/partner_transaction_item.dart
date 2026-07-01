import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_partner_application/application.dart';
import '../utils/partner_detail_helpers.dart';

class PartnerTransactionItem extends StatelessWidget {
  final PartnerTransactionHistoryItemDto transaction;

  const PartnerTransactionItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    final typeLabel = switch (transaction.transactionType.toLowerCase()) {
      'sales' || 'sales_order' => 'Đơn bán hàng',
      'return' || 'return_order' => 'Phiếu đổi/trả',
      'purchase' ||
      'purchase_order' ||
      'import' ||
      'goods_receipt' =>
        'Phiếu nhập hàng',
      'invoice' || 'sales_invoice' => 'Hóa đơn bán hàng',
      _ => transaction.transactionType,
    };

    final typeIcon = switch (transaction.transactionType.toLowerCase()) {
      'sales' || 'sales_order' => Icons.shopping_cart_outlined,
      'return' || 'return_order' => Icons.assignment_return_outlined,
      'purchase' ||
      'purchase_order' ||
      'import' ||
      'goods_receipt' =>
        Icons.inventory_2_outlined,
      'invoice' || 'sales_invoice' => Icons.receipt_outlined,
      _ => Icons.description_outlined,
    };

    final statusLabel = switch ((transaction.status ?? '').toLowerCase()) {
      'done' || 'completed' || 'hoanthat' => 'Đã hoàn tất',
      'delivered' || 'giaohang' => 'Đã giao hàng',
      'draft' || 'new' => 'Nhập',
      'cancelled' || 'cancel' || 'huy' => 'Đã hủy',
      _ => transaction.status ?? '',
    };

    final statusBadge = switch ((transaction.status ?? '').toLowerCase()) {
      'done' || 'completed' => VBadgeStatus.completed,
      'delivered' => VBadgeStatus.success,
      'draft' || 'new' => VBadgeStatus.info,
      'cancelled' || 'cancel' => VBadgeStatus.cancelled,
      _ => VBadgeStatus.locked,
    };

    final isNegative =
        transaction.amountMinor != null && transaction.amountMinor! < 0;

    return GestureDetector(
      onTap: () {
        // FR-04: Navigate to source transaction detail (fallback developed preview)
        showVConfirmDialog(
          context: context,
          title: 'Thông báo',
          message: 'Chi tiết giao dịch đang được phát triển.',
          cancelLabel: 'Đóng',
          actionLabel: 'Xác nhận',
          onAction: () {},
        );
      },
      child: VCard(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Icon box, Title & Code, Chevron Right
              Row(
                children: [
                  VIconBox(
                    iconData: typeIcon,
                    backgroundColor: dynamicColors.primary.withValues(
                      alpha: 0.08,
                    ),
                    iconColor: dynamicColors.primary,
                  ),
                  const SizedBox(width: VSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeLabel,
                          style: VTypography.headingH4.copyWith(
                            color: dynamicColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          transaction.transactionCode ?? transaction.id,
                          style: VTypography.bodySmall2.copyWith(
                            color: dynamicColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: VSpacing.space2),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: dynamicColors.textMuted,
                  ),
                ],
              ),
              // Divider Line
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: VSpacing.space2,
                ),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: dynamicColors.borderDefault.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              // Row 2: Date & Time, Status Badge & Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Date with Calendar Icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: dynamicColors.textMuted,
                      ),
                      const SizedBox(width: VSpacing.space1),
                      Text(
                        formatDate(transaction.occurredAt),
                        style: VTypography.bodySmall.copyWith(
                          color: dynamicColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Right: Status badge & Amount
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VBadge(
                        label: statusLabel,
                        status: statusBadge,
                        isSmall: true,
                      ),
                      const SizedBox(width: VSpacing.space2),
                      Text(
                        formatCurrency(transaction.amountMinor),
                        style: VTypography.monoNumeric.copyWith(
                          color: isNegative ? VColors.danger : VColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
