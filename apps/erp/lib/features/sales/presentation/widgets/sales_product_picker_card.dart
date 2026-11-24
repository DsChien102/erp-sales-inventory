import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import '../models/shared/sales_sellable_product_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';
class SalesProductPickerCard extends StatelessWidget {
  const SalesProductPickerCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final SalesSellableProductVm product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final blocked = product.isBlocked;
    final price = product.referencePrice;
    final priceLabel = price == null
        ? '—'
        : product.needsUnitPicker
        ? 'Từ ${MoneyFormatter.format(amountMinor: price.amountMinor, currencyCode: price.currencyCode)}'
        : MoneyFormatter.format(amountMinor: price.amountMinor, currencyCode: price.currencyCode);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(VRadius.card),
      child: InkWell(
        key: Key('card_sg03_product_${product.productId}'),
        onTap: blocked ? null : onTap,
        borderRadius: BorderRadius.circular(VRadius.card),
        child: Container(
          padding: const EdgeInsets.all(VSpacing.space3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VRadius.card),
            border: Border.all(
              color: blocked ? colors.danger.withValues(alpha: 0.4) : colors.borderDefault,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VIconBox(
                icon: VIcons.inventory,
                size: 44,
                iconSize: 22,
                backgroundColor: colors.surfaceAlt,
                iconColor: colors.textSecondary,
                borderRadius: VRadius.card,
              ),
              const VGap.horizontalSm(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      product.displayName,
                      variant: VTextVariant.bodyDefault,
                      color: colors.textPrimary,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                    ),
                    const VGap.xs(),
                    VText(
                      product.sku,
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    const VGap.xs(),
                    VText(
                      '${product.unitSummary} · $priceLabel',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    if (product.availabilityLabel != null) ...[
                      const VGap.xs(),
                      VText(
                        product.availabilityLabel!,
                        variant: VTextVariant.bodySmall,
                        color: blocked
                            ? colors.danger
                            : product.warningLabel != null
                            ? colors.warning
                            : colors.textMuted,
                      ),
                    ],
                    if (blocked && product.blockReason != null) ...[
                      const VGap.xs(),
                      VText(
                        product.blockReason!,
                        variant: VTextVariant.bodySmall,
                        color: colors.danger,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
