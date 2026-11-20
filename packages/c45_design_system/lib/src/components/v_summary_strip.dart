import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';

/// Đại diện cho một chỉ số trong dải tóm tắt.
class VSummaryItem {
  const VSummaryItem(this.label, this.value);

  final String label;
  final String value;
}

/// Dải tóm tắt số liệu (như Tổng tiền, Số dòng, Chiết khấu, ...).
/// Tự động chia đều trên 1 hàng, hoặc xếp 2x2 khi có hơn 3 mục trên màn hình hẹp (< 600px).
class VSummaryStrip extends StatelessWidget {
  const VSummaryStrip({
    super.key,
    required this.items,
  });

  final List<VSummaryItem> items;

  Widget _buildItem(BuildContext context, VSummaryItem item) {
    final colors = context.vColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          style: VTypography.bodySmall.copyWith(
            color: colors.textSecondary,
            fontSize: 12,
            height: 16 / 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: VSpacing.space1),
        Text(
          item.value,
          style: VTypography.monoNumeric.copyWith(
            color: colors.textPrimary,
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.r12),
        border: Border.all(
          color: colors.borderDefault,
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrowWrap = items.length > 3 && constraints.maxWidth < 600;

          if (isNarrowWrap) {
            final rows = <Widget>[];
            for (var i = 0; i < items.length; i += 2) {
              final first = items[i];
              final second = i + 1 < items.length ? items[i + 1] : null;

              if (rows.isNotEmpty) {
                rows.add(const SizedBox(height: VSpacing.space3));
              }

              rows.add(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildItem(context, first)),
                    const SizedBox(width: VSpacing.space3),
                    Expanded(
                      child: second != null
                          ? _buildItem(context, second)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: rows,
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: VSpacing.space3),
                Expanded(child: _buildItem(context, items[i])),
              ],
            ],
          );
        },
      ),
    );
  }
}
