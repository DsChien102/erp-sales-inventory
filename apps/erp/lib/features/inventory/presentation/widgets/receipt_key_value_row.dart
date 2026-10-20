import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Một dòng nhãn (trái) – giá trị (phải) dùng chung cho các màn nhận hàng.
class ReceiptKeyValueRow extends StatelessWidget {
  const ReceiptKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: VText(
              label,
              style: VTypography.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ),
          const VGap.horizontalCozy(),
          Flexible(
            child: VText(
              value,
              textAlign: TextAlign.end,
              style: VTypography.bodySmall.copyWith(
                fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
