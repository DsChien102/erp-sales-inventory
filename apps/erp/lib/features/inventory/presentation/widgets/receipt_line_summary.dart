import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/receipt_item_draft.dart';
import '../../logic/receipt_rules.dart';
import 'receipt_key_value_row.dart';

/// Một dòng hàng thực nhận (SCR-010, 011, 012): tên, tổng, phần vào tồn, từng lô + HSD.
class ReceiptLineSummary extends StatelessWidget {
  const ReceiptLineSummary({
    super.key,
    required this.item,
    this.onTap,
    this.trailingLabel,
  });

  final ReceiptItemDraft item;

  /// null = không chạm được.
  final VoidCallback? onTap;

  /// Ví dụ "Đã xong".
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final unit = item.unitName;
    final subtitle = '${item.productCode} · $unit'
        '${item.isLotTracked ? ' · ${item.lots.length} lô' : ''}';

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      item.productName,
                      style: VTypography.labelDefault.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const VGap(VSpacing.space1),
                    VText(
                      subtitle,
                      style: VTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailingLabel != null) ...[
                const VGap(VSpacing.space2, axis: Axis.horizontal),
                VText(
                  trailingLabel!,
                  style: VTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
              if (onTap != null) ...[
                const VGap(VSpacing.space2, axis: Axis.horizontal),
                const VIcon(
                  icon: VIcons.chevronRight,
                  iconSize: VIconSize.sm,
                  iconColor: VIconColor.muted,
                ),
              ],
            ],
          ),
          const VGap(VSpacing.space2),
          ReceiptKeyValueRow(
            label: 'Tổng kiểm nhận',
            value: '${formatQuantity(item.totalReceived)} $unit',
          ),
          ReceiptKeyValueRow(
            label: 'Vào tồn vật lý',
            value: '${formatQuantity(item.totalPhysicalStock)} $unit',
          ),
          if (item.totalRejected > 0)
            ReceiptKeyValueRow(
              label: 'Từ chối (không vào tồn)',
              value: '${formatQuantity(item.totalRejected)} $unit',
            ),
          if (item.isLotTracked)
            for (final lot in item.lots)
              Padding(
                padding: const EdgeInsets.only(top: VSpacing.space1),
                child: Row(
                  children: [
                    Expanded(
                      child: VText(
                        'Lô ${lot.lotCode}',
                        style: VTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    VText(
                      '${formatQuantity(lot.totalReceived)} $unit',
                      style: VTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (lot.expiryDate != null) ...[
                      const VGap(VSpacing.space3, axis: Axis.horizontal),
                      VText(
                        'HSD ${lot.expiryDate!.format()}',
                        style: VTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
