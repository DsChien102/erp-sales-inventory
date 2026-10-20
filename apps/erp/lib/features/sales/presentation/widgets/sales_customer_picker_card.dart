import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/shared/sales_customer_selection.dart';

/// VCard chọn KH — 4 trạng thái theo Figma SG-04:
/// default → hold (press) → selected → disabled.
class SalesCustomerPickerCard extends StatelessWidget {
  const SalesCustomerPickerCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
    this.extraLine,
  });

  /// Convenience từ list item.
  factory SalesCustomerPickerCard.fromItem({
    Key? key,
    required SalesCustomerListItemVm item,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    final phone = item.phone?.trim();
    final subtitleParts = <String>[
      if (phone != null && phone.isNotEmpty) phone,
      if (item.subtitle != null && item.subtitle!.trim().isNotEmpty) item.subtitle!.trim(),
    ];
    return SalesCustomerPickerCard(
      key: key ?? Key('card_sg04_customer_${item.partnerId}'),
      title: item.displayName,
      subtitle: subtitleParts.isEmpty ? '—' : subtitleParts.join(' · '),
      extraLine: null,
      selected: selected,
      enabled: !item.isBlocked,
      onTap: onTap,
    );
  }

  final String title;
  final String subtitle;
  final String? extraLine;
  final VoidCallback onTap;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final disabled = !enabled;

    final Color iconColor;
    final Color titleColor;
    final Color subtitleColor;

    if (disabled) {
      iconColor = colors.textMuted;
      titleColor = colors.textMuted;
      subtitleColor = colors.textMuted;
    } else if (selected) {
      iconColor = colors.textBrand;
      titleColor = colors.textPrimary;
      subtitleColor = colors.textSecondary;
    } else {
      iconColor = colors.textPrimary;
      titleColor = colors.textPrimary;
      subtitleColor = colors.textSecondary;
    }

    return VCard(
      onTap: disabled ? null : onTap,
      padding: const EdgeInsets.all(VSpacing.space3),
      tone: selected ? VComponentTone.primary : VComponentTone.neutral,
      enabled: enabled,
      child: Row(
        children: [
          const VGap(VSpacing.space1, axis: Axis.horizontal),
          VIconBox(
            icon: VIcons.person,
            size: 22,
            iconSize: 22,
            backgroundColor: Colors.transparent,
            iconColor: iconColor,
            borderRadius: VRadius.card,
          ),
          const VGap.horizontalCozy(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  title,
                  variant: VTextVariant.bodyDefault,
                  color: titleColor,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const VGap.xs(),
                VText(
                  subtitle,
                  variant: VTextVariant.bodySmall,
                  color: subtitleColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (extraLine != null) ...[
                  const VGap.xs(),
                  VText(
                    extraLine!,
                    variant: VTextVariant.bodySmall,
                    color: subtitleColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const VGap.horizontalSm(),
          IgnorePointer(
            child: RadioGroup<bool>(
              groupValue: selected,
              onChanged: (_) {},
              child: VRadio<bool>(
                value: true,
                enabled: enabled,
                onChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
