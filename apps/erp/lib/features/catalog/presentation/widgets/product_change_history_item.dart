import 'package:flutter/material.dart';
import '../../data/models.dart';
import 'package:vet45_design_system/design_system.dart';

import '../utils/product_change_history_formatters.dart';
import 'product_price_band_history_change.dart';

class ProductChangeHistoryItem extends StatelessWidget {
  const ProductChangeHistoryItem({
    super.key,
    required this.entry,
  });

  final ProductChangeHistoryEntryDto entry;

  @override
  Widget build(BuildContext context) {
    final priceBandChange = entry.priceBandChange;
    if (!entry.isSensitiveMasked && priceBandChange != null) {
      return ProductPriceBandHistoryChange(
        change: priceBandChange,
        occurredAt: entry.occurredAt,
        actorDisplayName: entry.actorDisplayName,
      );
    }

    final dynamicColors = context.vColors;
    final dateStr = formatProductChangeHistoryDateTime(entry.occurredAt);
    final summaryText = formatProductChangeHistorySummary(
      summary: entry.summary,
      changeType: entry.changeType,
    );

    // Mask sensitive values
    final showMasked = entry.isSensitiveMasked;
    final beforeText = showMasked ? '***' : entry.valueBefore;
    final afterText = showMasked ? '***' : entry.valueAfter;

    String valueDescription = '';
    if (beforeText != null && afterText != null) {
      valueDescription = '$beforeText — $afterText';
    } else if (beforeText != null) {
      valueDescription = beforeText;
    } else if (afterText != null) {
      valueDescription = afterText;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: VSpacing.space3),
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: dynamicColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: VText(
                  summaryText,
                  variant: VTextVariant.bodyDefault,
                  color: dynamicColors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              VText(
                dateStr,
                variant: VTextVariant.bodySmall,
                color: dynamicColors.textSecondary,
              ),
            ],
          ),
          if (valueDescription.isNotEmpty) ...[
            const SizedBox(height: VSpacing.space1),
            VText(
              valueDescription,
              variant: VTextVariant.bodyDefault,
              color: dynamicColors.textSecondary,
            ),
          ],
          if (entry.reason != null && entry.reason!.isNotEmpty) ...[
            const SizedBox(height: VSpacing.space1),
            VText(
              'Lý do: ${entry.reason}',
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: VSpacing.space1),
          VText(
            'bởi ${entry.actorDisplayName}',
            variant: VTextVariant.bodySmall,
            color: dynamicColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
