import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../models/sales_order/sales_order_detail_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'sales_order_detail_grouped_surface.dart';

class SalesOrderDetailProductsSection extends StatelessWidget {
  const SalesOrderDetailProductsSection({
    super.key,
    required this.items,
  });

  final List<SalesOrderDetailItemVm> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VText(
          'Sản phẩm',
          variant: VTextVariant.bodyDefault,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const VGap.sm(),
        SalesOrderDetailGroupedSurface(
          key: const Key('wgt_sg08_products_grouped'),
          children: items.map((item) => _ProductLineRow(item: item)).toList(),
        ),
      ],
    );
  }
}

class _ProductLineRow extends StatelessWidget {
  const _ProductLineRow({required this.item});

  final SalesOrderDetailItemVm item;

  VIcons _resolveProductIcon(String unitName) {
    final unit = unitName.trim().toLowerCase();
    if (unit.contains('chai') ||
        unit.contains('lọ') ||
        unit.contains('lo') ||
        unit.contains('ống') ||
        unit.contains('ong') ||
        unit.contains('tuýp') ||
        unit.contains('tuyp')) {
      return VIcons.tag;
    }
    return VIcons.inventory;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space3,
          vertical: VSpacing.space2,
        ),
        child: Row(
          children: [
            VIconBox(
              icon: _resolveProductIcon(item.unitName),
              size: 40,
              iconSize: 20,
              backgroundColor: colors.surfaceAlt,
              iconColor: colors.textPrimary,
              borderRadius: VRadius.card,
            ),
            const VGap.horizontalSm(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VText(
                    item.productName,
                    variant: VTextVariant.bodyDefault,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const VGap.xs(),
                  _CompactPriceLine(item: item),
                ],
              ),
            ),
            const VGap.horizontalSm(),
            VText(
              MoneyFormatter.formatMinor(item.totalAmountMinor),
              variant: VTextVariant.bodyDefaultMono,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactPriceLine extends StatelessWidget {
  const _CompactPriceLine({required this.item});

  final SalesOrderDetailItemVm item;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final hasDiscount = item.originalUnitPriceMinor != null &&
        item.originalUnitPriceMinor != item.unitPriceMinor;

    final children = <Widget>[
      VText(
        '${item.quantity} ${item.unitName} × ',
        variant: VTextVariant.bodySmall,
        color: colors.textSecondary,
      ),
    ];

    if (hasDiscount) {
      children.addAll([
        VText(
          MoneyFormatter.formatMinor(item.originalUnitPriceMinor!),
          variant: VTextVariant.bodySmall,
          color: colors.textMuted,
          style: const TextStyle(decoration: TextDecoration.lineThrough),
        ),
        const VGap.horizontalXs(),
        VText(
          MoneyFormatter.formatMinor(item.unitPriceMinor),
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
      ]);
    } else {
      children.addAll([
        VText(
          MoneyFormatter.formatMinor(item.unitPriceMinor),
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
      ]);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
    );
  }
}
