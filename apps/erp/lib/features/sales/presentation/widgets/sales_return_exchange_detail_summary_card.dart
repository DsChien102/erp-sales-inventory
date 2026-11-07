import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/return_exchange_order/sales_return_exchange_detail_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';

class SalesReturnExchangeDetailSummaryCard extends StatelessWidget {
  const SalesReturnExchangeDetailSummaryCard({
    super.key,
    required this.detail,
  });

  final SalesReturnExchangeDetailVm detail;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final plan = detail.settlementPlan;
    final valuation = detail.valuation;

    final diffMinor = plan.netDifferenceMinor.abs();

    return VCard(
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VText(
            'Tóm tắt đổi/trả',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const VGap.md(),
          _buildSummaryRow(
            colors,
            label: 'Giá trị hàng trả',
            amountText: MoneyFormatter.format(
              amountMinor: valuation.returnValue.amountMinor,
              currencyCode: valuation.returnValue.currencyCode,
            ),
          ),
          const VGap.sm(),
          _buildSummaryRow(
            colors,
            label: 'Giá trị hàng đổi',
            amountText: MoneyFormatter.format(
              amountMinor: valuation.exchangeValue.amountMinor,
              currencyCode: valuation.exchangeValue.currencyCode,
            ),
          ),
          const VGap.md(),
          VCard(
            backgroundColor: colors.successBg,
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space3,
              vertical: VSpacing.space3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const VText(
                  'Chênh lệch',
                  variant: VTextVariant.bodyDefault,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                VText(
                  MoneyFormatter.formatMinor(diffMinor),
                  variant: VTextVariant.bodyDefault,
                  color: colors.success,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    dynamic colors, {
    required String label,
    required String amountText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
        VText(
          amountText,
          variant: VTextVariant.bodyDefault,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
