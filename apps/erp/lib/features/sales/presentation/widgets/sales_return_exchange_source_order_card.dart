import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class SalesReturnExchangeSourceOrderCard extends StatelessWidget {
  const SalesReturnExchangeSourceOrderCard({
    super.key,
    required this.orderNumber,
    this.statusText = 'Đã trả một phần',
    this.onTap,
  });

  final String orderNumber;
  final String statusText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final content = VCard(
      backgroundColor: colors.surface,
      border: Border.all(color: colors.borderDefault),
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Row(
        children: [
          VIconBox(
            icon: VIcons.history,
            size: 36,
            iconSize: 18,
            backgroundColor: colors.surfaceAlt,
            iconColor: colors.textSecondary,
            borderRadius: VRadius.r8,
          ),
          const VGap.horizontalMd(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Đơn hàng nguồn $orderNumber',
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.xs(),
                VText(
                  statusText,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const VIcon(
            icon: VIcons.chevronRight,
            iconColor: VIconColor.secondary,
            size: 20,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.card),
        child: content,
      );
    }

    return content;
  }
}
