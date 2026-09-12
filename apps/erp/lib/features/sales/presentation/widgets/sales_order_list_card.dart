import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/sales_order/sales_order_list_item_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';
/// Order card layout matching Figma SG-07:
/// name + lifecycle badge → phone · store → total → #code + time.
class SalesOrderListCard extends StatelessWidget {
  const SalesOrderListCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final SalesOrderListItemVm item;
  final VoidCallback onTap;

  String _formatTime(DateTime value) => VDateTime.time(value);

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final meta = item.metaLine;

    return VCard(
      key: Key('card_sales_order_${item.salesOrderId}'),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      item.customerLabel,
                      style: VTypography.headingH4.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (meta != null) ...[
                      const VGap.xs(),
                      VText(
                        meta,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const VGap.sm(),
                    VText(
                      MoneyFormatter.format(amountMinor: item.total.amountMinor, currencyCode: item.total.currencyCode),
                      style: VTypography.bodyDefaultMono.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const VGap.horizontalSm(),
              VBadge(
                label: item.lifecycleLabel,
                tone: item.isCancelled ? VComponentTone.danger : VComponentTone.success,
              ),
            ],
          ),
          const VGap.sm(),
          Row(
            children: [
              Expanded(
                child: VText(
                  item.orderNumber,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ),
              VText(
                _formatTime(item.completedAt),
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
