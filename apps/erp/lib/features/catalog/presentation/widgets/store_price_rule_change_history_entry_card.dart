import 'package:flutter/material.dart';
import '../../data/models.dart';
import 'package:vet45_design_system/design_system.dart';

import '../utils/product_change_history_formatters.dart';

class StorePriceRuleChangeHistoryEntryCard extends StatelessWidget {
  const StorePriceRuleChangeHistoryEntryCard({
    super.key,
    required this.entry,
  });

  final StorePriceRuleChangeHistoryEntryDto entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final dateText = formatProductChangeHistoryDateTime(entry.occurredAt);
    final listPercent = (entry.listMarkupAfter * 100).toStringAsFixed(1);
    final floorPercent = (entry.floorMarkupAfter * 100).toStringAsFixed(1);
    final listDelta = _formatDelta(
      before: entry.listMarkupBefore,
      after: entry.listMarkupAfter,
      prefix: '+',
    );
    final floorDelta = _formatDelta(
      before: entry.floorMarkupBefore,
      after: entry.floorMarkupAfter,
    );

    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r12),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VText(
                dateText,
                variant: VTextVariant.bodyDefault,
                color: colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (entry.isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceBrand,
                    borderRadius: BorderRadius.circular(VRadius.r4),
                  ),
                  child: VText(
                    'Hiện tại',
                    variant: VTextVariant.caption,
                    color: colors.primary,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VSpacing.space1),
          VText(
            'Bởi: ${entry.actorDisplayName}',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const SizedBox(height: VSpacing.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VText(
                'Giá niêm yết',
                variant: VTextVariant.bodyDefault,
                color: colors.textPrimary,
              ),
              VText(
                '+$listPercent%',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (listDelta != null) ...[
            const VGap.xs(),
            Align(
              alignment: Alignment.centerRight,
              child: VText(
                listDelta,
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: VSpacing.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VText(
                'Giá sàn',
                variant: VTextVariant.bodyDefault,
                color: colors.textPrimary,
              ),
              VText(
                '$floorPercent%',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (floorDelta != null) ...[
            const VGap.xs(),
            Align(
              alignment: Alignment.centerRight,
              child: VText(
                floorDelta,
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _formatDelta({
    required double? before,
    required double after,
    String prefix = '',
  }) {
    if (before == null) {
      return null;
    }
    final beforePercent = (before * 100).toStringAsFixed(1);
    final afterPercent = (after * 100).toStringAsFixed(1);
    return '($prefix$beforePercent% → $prefix$afterPercent%)';
  }
}
