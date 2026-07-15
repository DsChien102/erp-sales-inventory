import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../foundation/v_component_contracts.dart';

class VActivityItem extends StatelessWidget {
  final Widget leadingIcon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final VBadgeStatus badgeStatus;
  final String time;
  final VoidCallback? onTap;
  final VComponentTone? tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  const VActivityItem({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeStatus,
    required this.time,
    this.onTap,
    this.tone,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    Color iconColor;
    switch (badgeStatus) {
      case VBadgeStatus.danger:
      case VBadgeStatus.overdue:
        iconColor = VColors.danger;
        break;
      case VBadgeStatus.warning:
      case VBadgeStatus.partiallyPaid:
      case VBadgeStatus.outstanding:
        iconColor = VColors.warning;
        break;
      case VBadgeStatus.success:
      case VBadgeStatus.completed:
      case VBadgeStatus.paid:
        iconColor = VColors.success;
        break;
      case VBadgeStatus.info:
      case VBadgeStatus.pending:
        iconColor = VColors.info;
        break;
      default:
        iconColor = dynamicColors.primary;
    }

    return Semantics(
      label: semanticLabel ?? title,
      button: onTap != null,
      child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space3,
          vertical: 10.0,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: dynamicColors.surfaceAlt,
                borderRadius: BorderRadius.circular(VRadius.r12),
              ),
              alignment: Alignment.center,
              child: IconTheme(
                data: IconThemeData(
                  color: iconColor,
                  size: 18,
                ),
                child: leadingIcon,
              ),
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: VTypography.bodyDefault.copyWith(
                      fontWeight: FontWeight.w600,
                      color: dynamicColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: VTypography.caption.copyWith(
                      color: dynamicColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: VSpacing.space2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                VBadge(
                  label: badgeLabel,
                  status: badgeStatus,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: VTypography.caption.copyWith(
                    color: dynamicColors.textMuted,
                    fontFamily: VTypography.monoFontFamily,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}
