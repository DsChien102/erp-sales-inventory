import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
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
              Text(
                dateText,
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
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
                  child: Text(
                    'Hiện tại',
                    style: VTypography.caption.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Bởi: ${entry.actorDisplayName}',
            style: VTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: VSpacing.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giá niêm yết',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              Text(
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
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                listDelta,
                style: VTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: VSpacing.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giá sàn',
                style: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              Text(
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
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                floorDelta,
                style: VTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
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
