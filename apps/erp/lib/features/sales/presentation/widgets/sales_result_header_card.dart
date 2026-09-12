import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/sales_order/sales_transaction_result_state.dart';

class SalesResultHeaderCard extends StatelessWidget {
  const SalesResultHeaderCard({
    super.key,
    required this.state,
    required this.onViewOrderDetail,
  });

  final SalesTransactionResultState state;
  final VoidCallback onViewOrderDetail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VIconBox(
            icon: VIcons.success,
            iconColor: colors.success,
            size: 22,
            iconSize: 22,
            isCircular: true,
          ),
          const VGap.sm(),
          const VText(
            'Đã hoàn tất đơn',
            variant: VTextVariant.headingH3,
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const VGap.xs(),
          VText(
            'Đơn ${state.order?.order.orderNumber ?? state.checkout?.salesOrderId ?? '-'}',
            variant: VTextVariant.headingH4,
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const VGap.xs(),
          VText(
            _metaText(state),
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
            textAlign: TextAlign.center,
          ),
          const VGap.sm(),
          VButton(
            key: const Key('btn_sg06_view_detail'),
            label: 'Xem chi tiết đơn',
            variant: VButtonVariant.tertiary,
            foregroundColor: colors.success,
            size: VButtonSize.small,
            onPressed: onViewOrderDetail,
          ),
        ],
      ),
    );
  }

  String _metaText(SalesTransactionResultState state) {
    final soldAt = state.order?.committedAt;
    final datePart = soldAt == null
        ? 'Đang đồng bộ'
        : VDateTime.dateTime(soldAt);

    final original = state.payment?.originalOrder;
    final String methodText;
    if (original != null) {
      if (original.paidCash.amountMinor > 0 && original.paidBank.amountMinor > 0) {
        methodText = 'Tiền mặt + chuyển khoản';
      } else if (original.paidBank.amountMinor > 0) {
        methodText = 'Chuyển khoản';
      } else if (original.paidCash.amountMinor > 0) {
        methodText = 'Tiền mặt';
      } else {
        methodText = 'Chưa thanh toán';
      }
    } else {
      final paidTotal = state.payment?.paidTotal.amountMinor ?? 0;
      if (state.payment != null && paidTotal == 0) {
        methodText = 'Chưa thanh toán';
      } else {
        methodText = 'Tiền mặt';
      }
    }

    return '$datePart · $methodText';
  }
}
