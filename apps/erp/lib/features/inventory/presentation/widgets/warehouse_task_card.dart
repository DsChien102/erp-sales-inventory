import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../data/models/warehouse_task_item.dart';

class WarehouseTaskCard extends StatelessWidget {
  const WarehouseTaskCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final WarehouseTaskItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(
          color: colors.borderDefault,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(VRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: VSpacing.space3,
            ),
            child: Row(
              children: [
                if (item.icon != null) ...[
                  VIcon(
                    icon: item.icon!,
                    iconSize: VIconSize.md,
                    iconColor: VIconColor.secondary,
                  ),
                  const SizedBox(width: VSpacing.space3),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VText(
                        item.title,
                        style: VTypography.labelDefault.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      VText(
                        item.subtitle,
                        style: VTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.badgeLabel != null && item.badgeLabel!.isNotEmpty) ...[
                  VBadge(
                    label: item.badgeLabel!,
                    tone: item.badgeTone ?? VComponentTone.info,
                    variant: VBadgeVariant.soft,
                  ),
                  const SizedBox(width: VSpacing.space2),
                ],
                const VIcon(
                  icon: VIcons.chevronRight,
                  iconSize: VIconSize.sm,
                  iconColor: VIconColor.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
