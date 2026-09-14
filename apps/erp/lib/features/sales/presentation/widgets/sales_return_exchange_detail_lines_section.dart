import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';

import 'package:erp/core/formatting/money_formatter.dart';
class SalesReturnExchangeDetailLinesSection extends StatelessWidget {
  const SalesReturnExchangeDetailLinesSection({
    super.key,
    required this.returnLines,
    required this.exchangeLines,
  });

  final List<ReturnExchangeDetailLineDto> returnLines;
  final List<ReturnExchangeDetailLineDto> exchangeLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (returnLines.isNotEmpty) ...[
          const VText(
            'Hàng trả',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const VGap.xs(),
          for (final line in returnLines) ...[
            _buildLineCard(
              context,
              line: line,
              icon: VIcons.inventory,
            ),
            const VGap.xs(),
          ],
        ],
        if (exchangeLines.isNotEmpty) ...[
          const VGap.sm(),
          const VText(
            'Hàng đổi',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const VGap.xs(),
          for (final line in exchangeLines) ...[
            _buildLineCard(
              context,
              line: line,
              icon: VIcons.store,
            ),
            const VGap.xs(),
          ],
        ],
      ],
    );
  }

  Widget _buildLineCard(
    BuildContext context, {
    required ReturnExchangeDetailLineDto line,
    required VIcons icon,
  }) {
    final colors = context.vColors;
    final qty = line.quantity.quantityMicros ~/ QuantityDto.scale;

    return VCard(
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Row(
        children: [
          VIconBox(
            icon: icon,
            size: 40,
            iconSize: 20,
            backgroundColor: colors.surfaceAlt,
            iconColor: colors.textSecondary,
            borderRadius: VRadius.r8,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  line.product.displayName,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.xs(),
                VText(
                  '$qty ${line.unit.unitName} × ${MoneyFormatter.format(amountMinor: line.unitPrice.amountMinor, currencyCode: line.unitPrice.currencyCode)}',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const VGap.horizontalSm(),
          VText(
            MoneyFormatter.format(amountMinor: line.lineTotal.amountMinor, currencyCode: line.lineTotal.currencyCode),
            variant: VTextVariant.bodyDefault,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
