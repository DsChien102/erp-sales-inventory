import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/logic/sales_order_detail_state.dart';
import '../models/sales_order_settlement/sales_order_payment_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';
class SalesOrderDetailPaymentSummaryCard extends StatelessWidget {
  const SalesOrderDetailPaymentSummaryCard({
    super.key,
    required this.status,
    required this.onTap,
    required this.onRetry,
    this.data,
    this.errorMessage,
  });

  final SalesOrderDetailSectionStatus status;
  final SalesOrderDetailPaymentDisplayData? data;
  final String? errorMessage;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  bool get _enabled => data?.enabled ?? true;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return switch (status) {
      SalesOrderDetailSectionStatus.idle || SalesOrderDetailSectionStatus.loading => VCard(
        enabled: _enabled,
        padding: const EdgeInsets.all(VSpacing.space3),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            VGap.horizontalCozy(),
            Expanded(
              child: VText(
                'Đang tải thanh toán & công nợ…',
                variant: VTextVariant.bodySmall,
              ),
            ),
          ],
        ),
      ),
      SalesOrderDetailSectionStatus.blocked => _messageCard(
        colors: colors,
        message: errorMessage ?? 'Bạn không có quyền xem thanh toán của đơn này.',
        showRetry: false,
      ),
      SalesOrderDetailSectionStatus.projectionPending => _messageCard(
        colors: colors,
        message: errorMessage ?? 'Thanh toán đang đồng bộ. Thử lại sau.',
        showRetry: true,
      ),
      SalesOrderDetailSectionStatus.error => _messageCard(
        colors: colors,
        message: errorMessage ?? 'Không tải được thanh toán & công nợ.',
        showRetry: true,
      ),
      SalesOrderDetailSectionStatus.loaded => _loadedCard(colors),
    };
  }

  Widget _loadedCard(dynamic colors) {
    final display = data;
    if (display == null) {
      return _messageCard(
        colors: colors,
        message: 'Không tải được thanh toán & công nợ.',
        showRetry: true,
      );
    }

    final enabled = display.enabled;

    return VCard(
      key: const Key('wgt_sg08_payment'),
      onTap: onTap,
      enabled: enabled,
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Row(
        children: [
          VIcon(
            icon: VIcons.banknoteArrowDown,
            size: 22,
            color: enabled ? colors.textPrimary : colors.textSecondary,
          ),
          const VGap.horizontalCozy(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Thanh toán & công nợ',
                  variant: VTextVariant.bodyDefault,
                  color: enabled ? colors.textPrimary : colors.textSecondary,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap(VSpacing.space1),
                VText(
                  'Đã thanh toán ${MoneyFormatter.formatMinor(display.paidMinor)}',
                  variant: VTextVariant.bodySmall,
                  color: enabled ? colors.warning : colors.textSecondary,
                  style: TextStyle(
                    fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const VGap(VSpacing.space1),
                VText(
                  'Còn phải thu ${MoneyFormatter.formatMinor(display.outstandingMinor)}',
                  variant: VTextVariant.bodySmall,
                  color: enabled ? colors.warning : colors.textMuted,
                  style: TextStyle(
                    fontWeight: enabled ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const VGap.horizontalSm(),
          VIcon(
            icon: VIcons.chevronRight,
            size: 20,
            color: colors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required dynamic colors,
    required String message,
    required bool showRetry,
  }) {
    final enabled = _enabled;
    return VCard(
      padding: const EdgeInsets.all(VSpacing.space3),
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Thanh toán & công nợ',
            variant: VTextVariant.bodyDefault,
            color: enabled ? colors.textPrimary : colors.textSecondary,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const VGap(VSpacing.space1),
          VText(
            message,
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          if (showRetry) ...[
            const VGap(VSpacing.space1),
            VButton(
              label: 'Thử lại',
              onPressed: onRetry,
              variant: VButtonVariant.secondary,
              size: VButtonSize.small,
            ),
          ],
        ],
      ),
    );
  }
}
