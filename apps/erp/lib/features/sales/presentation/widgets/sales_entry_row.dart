import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Base layout cho các hàng entry/chứng từ trong Sales: icon, tiêu đề, mô tả,
/// badge tùy chọn và chevron điều hướng.
///
/// Không export ra ngoài package — mỗi màn dùng widget theo mục đích
/// (`SalesReceiptEntryCard`, `SalesEInvoiceEntryCard`, …) dựng trên hàng này.
class SalesEntryRow extends StatelessWidget {
  const SalesEntryRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.enabled = true,
  });

  final VIcons icon;
  final String title;
  final String subtitle;

  /// Null hoặc [enabled] = false thì hàng không nhận tap.
  final VoidCallback? onTap;

  /// Badge hiển thị trước chevron (thường là `VBadge`).
  final Widget? badge;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      onTap: onTap,
      enabled: enabled,
      child: Row(
        children: [
          VIcon(
            icon: icon,
            size: 22,
            color: enabled ? colors.textPrimary : colors.textMuted,
          ),
          const VGap(VSpacing.space3, axis: Axis.horizontal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  title,
                  variant: VTextVariant.bodyDefault,
                  color: enabled ? colors.textPrimary : colors.textMuted,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const VGap.xs(),
                VText(
                  subtitle,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            const VGap(VSpacing.space3, axis: Axis.horizontal),
            badge!,
          ],
          const VGap(VSpacing.space3, axis: Axis.horizontal),
          VIcon(
            icon: VIcons.chevronRight,
            size: 20,
            color: enabled ? colors.textMuted : colors.borderDefault,
          ),
        ],
      ),
    );
  }
}
