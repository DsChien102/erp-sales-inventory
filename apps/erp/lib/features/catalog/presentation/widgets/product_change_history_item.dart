import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductChangeHistoryItem extends StatelessWidget {
  const ProductChangeHistoryItem({
    super.key,
    required this.entry,
  });

  final ProductChangeHistoryEntryDto entry;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final dateStr = entry.occurredAt.toString().substring(0, 16); // YYYY-MM-DD HH:MM
    
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  entry.summary,
                  style: VTypography.bodyDefault.copyWith(
                    fontWeight: FontWeight.bold,
                    color: dynamicColors.textPrimary,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: VTypography.bodySmall.copyWith(
                  color: dynamicColors.textSecondary,
                ),
              ),
            ],
          ),
          if (valueDescription.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              valueDescription,
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'bởi ${entry.actorDisplayName}',
            style: VTypography.bodySmall.copyWith(
              color: dynamicColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
