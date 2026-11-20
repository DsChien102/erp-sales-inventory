import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_cost_rules.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft.dart';

class ReceiptAllocationBlock extends StatelessWidget {
  const ReceiptAllocationBlock({
    super.key,
    required this.lines,
    required this.freightVnd,
    required this.discountVnd,
  });

  final List<ReceiptLineDraft> lines;
  final int freightVnd;
  final int discountVnd;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final inputs = lines.map((l) {
      return ReceiptCostLineInput(
        paidQty: l.paidQuantity,
        freeQty: l.freeQty,
        rate: l.unit.rate,
        unitPriceVnd: l.unitPriceVnd,
        tierPercent: l.tierPercent,
        lotQuantities: l.lots.map((lot) => lot.quantity).toList(),
      );
    }).toList();

    final breakdown = computeReceiptCost(
      inputs,
      freightVnd: freightVnd,
      discountVnd: discountVnd,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isWide = screenWidth >= 900 || constraints.maxWidth >= 700;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VSummaryStrip(
              items: [
                VSummaryItem(
                  'Giá mua',
                  '${MoneyFormatter.formatMinorPlain(breakdown.purchaseTotal)} đ',
                ),
                VSummaryItem(
                  'Chi phí (+)',
                  '${MoneyFormatter.formatMinorPlain(freightVnd)} đ',
                ),
                VSummaryItem(
                  'Chiết khấu (-)',
                  '${MoneyFormatter.formatMinorPlain(discountVnd)} đ',
                ),
                VSummaryItem(
                  'Giá gốc (=)',
                  '${MoneyFormatter.formatMinorPlain(breakdown.landedTotal)} đ',
                ),
              ],
            ),
            if (breakdown.discountTooLarge) ...[
              const SizedBox(height: VSpacing.space2),
              Text(
                'Chiết khấu không được lớn hơn tổng giá mua và chi phí',
                style: VTypography.bodySmall.copyWith(color: colors.danger),
              ),
            ],
            const SizedBox(height: VSpacing.space4),
            if (isWide)
              _buildWideTable(breakdown, context)
            else
              _buildMobileCards(breakdown, context),
          ],
        );
      },
    );
  }

  Widget _buildWideTable(ReceiptCostBreakdown breakdown, BuildContext context) {
    final colors = context.vColors;
    const headers = [
      'Mặt hàng',
      'Giá mua',
      'Giảm bậc',
      'Chi phí',
      'Chiết khấu',
      'Giá gốc',
      'Đơn giá gốc',
    ];

    final tableRows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.borderDefault),
          ),
        ),
        children: [
          for (var i = 0; i < headers.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: VSpacing.space3,
                horizontal: VSpacing.space2,
              ),
              child: Text(
                headers[i],
                style: VTypography.labelDefault.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: i == 0 ? TextAlign.left : TextAlign.right,
              ),
            ),
        ],
      ),
    ];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final cost = i < breakdown.lines.length ? breakdown.lines[i] : null;
      if (cost == null) continue;

      tableRows.add(
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.borderDefault),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: VSpacing.space3,
                horizontal: VSpacing.space2,
              ),
              child: Text('${line.product.name} (${line.unit.name})', style: VTypography.bodyDefault),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: VSpacing.space3,
                horizontal: VSpacing.space2,
              ),
              child: Text(
                '${MoneyFormatter.formatMinorPlain(cost.purchase)} đ',
                textAlign: TextAlign.right,
                style: VTypography.bodyDefault,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: VSpacing.space3,
                horizontal: VSpacing.space2,
              ),
              child: Text(
                cost.tierDiscount > 0
                    ? '-${MoneyFormatter.formatMinorPlain(cost.tierDiscount)} đ'
                    : '-',
                textAlign: TextAlign.right,
                style: VTypography.bodyDefault,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: VSpacing.space3,
                horizontal: VSpacing.space2,
              ),
              child: Text(
                cost.freight > 0 ? '+${MoneyFormatter.formatMinorPlain(cost.freight)} đ' : '0 đ',
                textAlign: TextAlign.right,
                style: VTypography.bodyDefault,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: VSpacing.space3,
                horizontal: VSpacing.space2,
              ),
              child: Text(
                cost.discount > 0 ? '-${MoneyFormatter.formatMinorPlain(cost.discount)} đ' : '0 đ',
                textAlign: TextAlign.right,
                style: VTypography.bodyDefault,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: VSpacing.space3,
                horizontal: VSpacing.space2,
              ),
              child: Text(
                '${MoneyFormatter.formatMinorPlain(cost.landed)} đ',
                textAlign: TextAlign.right,
                style: VTypography.labelDefault.copyWith(color: colors.primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: VSpacing.space3,
                horizontal: VSpacing.space2,
              ),
              child: Text(
                '${MoneyFormatter.formatMinorPlain(cost.landedUnitCost.round())} đ/${line.unit.name}',
                textAlign: TextAlign.right,
                style: VTypography.bodyDefault,
              ),
            ),
          ],
        ),
      );
    }

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: tableRows,
    );
  }

  Widget _buildMobileCards(ReceiptCostBreakdown breakdown, BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: VSpacing.space2),
          _buildMobileCard(i, lines[i], breakdown.lines[i], context),
        ],
      ],
    );
  }

  Widget _buildMobileCard(
    int index,
    ReceiptLineDraft line,
    ReceiptCostLine cost,
    BuildContext context,
  ) {
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${line.product.name} (${line.unit.name})',
            style: VTypography.labelDefault,
          ),
          const SizedBox(height: VSpacing.space1),
          VKeyValueRow(
            label: 'Giá mua',
            value: '${MoneyFormatter.formatMinorPlain(cost.purchase)} đ',
          ),
          if (cost.tierDiscount > 0)
            VKeyValueRow(
              label: 'Giảm bậc',
              value: '-${MoneyFormatter.formatMinorPlain(cost.tierDiscount)} đ',
            ),
          VKeyValueRow(
            label: 'Chi phí (+)',
            value: '+${MoneyFormatter.formatMinorPlain(cost.freight)} đ',
          ),
          VKeyValueRow(
            label: 'Chiết khấu (-)',
            value: '-${MoneyFormatter.formatMinorPlain(cost.discount)} đ',
          ),
          VKeyValueRow(
            label: 'Giá gốc',
            value: '${MoneyFormatter.formatMinorPlain(cost.landed)} đ',
            emphasized: true,
          ),
          VKeyValueRow(
            label: 'Đơn giá gốc',
            value: '${MoneyFormatter.formatMinorPlain(cost.landedUnitCost.round())} đ/${line.unit.name}',
          ),
        ],
      ),
    );
  }
}
