import 'package:flutter/material.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_design_system/design_system.dart';

import '../utils/product_change_history_formatters.dart';

class ProductPriceBandHistoryChange extends StatelessWidget {
  const ProductPriceBandHistoryChange({
    super.key,
    required this.change,
    required this.occurredAt,
    required this.actorDisplayName,
  });

  final ProductPriceBandHistoryChangeDto change;
  final DateTime occurredAt;
  final String actorDisplayName;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final before = change.before;
    final title = before == null
        ? 'Tạo khung giá — ${change.unitName}'
        : 'Cập nhật khung giá — ${change.unitName}';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: VTypography.bodyDefault.copyWith(
                    fontWeight: FontWeight.bold,
                    color: dynamicColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              Text(
                formatProductChangeHistoryDateTime(occurredAt),
                style: VTypography.bodySmall.copyWith(
                  color: dynamicColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space3),
          _HistoryValueRow(
            label: 'Cách tính',
            value:
                '${formatProductPriceBandSourceType(before?.sourceType)} → '
                '${formatProductPriceBandSourceType(change.after.sourceType)}',
          ),
          const SizedBox(height: VSpacing.space2),
          _HistoryValueRow(
            label: 'Giá niêm yết',
            value:
                '${formatProductPriceBandHistoryMoney(before?.listPrice, change.currency)} → '
                '${formatProductPriceBandHistoryMoney(change.after.listPrice, change.currency)}',
          ),
          const SizedBox(height: VSpacing.space2),
          _HistoryValueRow(
            label: 'Giá sàn',
            value:
                '${formatProductPriceBandHistoryMoney(before?.floorPrice, change.currency)} → '
                '${formatProductPriceBandHistoryMoney(change.after.floorPrice, change.currency)}',
          ),
          const SizedBox(height: VSpacing.space3),
          Text(
            'Nguyên nhân: ${formatProductPriceBandHistoryTrigger(change.trigger)}',
            style: VTypography.bodySmall.copyWith(
              color: dynamicColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'bởi $actorDisplayName',
            style: VTypography.bodySmall.copyWith(
              color: dynamicColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryValueRow extends StatelessWidget {
  const _HistoryValueRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: VTypography.bodySmall.copyWith(
              color: dynamicColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: VSpacing.space2),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: VTypography.bodyDefault.copyWith(
              color: dynamicColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
