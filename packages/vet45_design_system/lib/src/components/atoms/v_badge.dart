import 'package:flutter/material.dart';
import '../../tokens/v_colors.dart';
import '../../tokens/v_spacing.dart';
import '../../tokens/v_radius.dart';
import '../../tokens/v_typography.dart';
import '../../utils/v_context_extensions.dart';

enum VBadgeStatus {
  draft,
  pending,
  processing,
  completed,
  paid,
  partiallyPaid,
  outstanding,
  overdue,
  cancelled,
  locked,
  success,
  warning,
  danger,
  info,
}

class VBadge extends StatelessWidget {
  final String label;
  final VBadgeStatus status;
  final bool showDot;
  final IconData? iconData;
  final bool isSmall;

  const VBadge({
    super.key,
    required this.label,
    required this.status,
    this.showDot = false,
    this.iconData,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    // Use dynamic theme extensions if available, or fallback to VColors
    final dynamicColors = context.vColors;

    switch (status) {
      case VBadgeStatus.success:
      case VBadgeStatus.completed:
      case VBadgeStatus.paid:
        backgroundColor = VColors.successBg;
        textColor = VColors.success;
        break;

      case VBadgeStatus.warning:
      case VBadgeStatus.partiallyPaid:
      case VBadgeStatus.outstanding:
        backgroundColor = VColors.warningBg;
        textColor = VColors.warning;
        break;

      case VBadgeStatus.danger:
      case VBadgeStatus.overdue:
        backgroundColor = VColors.dangerBg;
        textColor = VColors.danger;
        break;

      case VBadgeStatus.info:
      case VBadgeStatus.pending:
        backgroundColor = VColors.infoBg;
        textColor = VColors.info;
        break;

      case VBadgeStatus.processing:
        backgroundColor = VColors.secondarySurface;
        textColor = dynamicColors.primary;
        break;

      case VBadgeStatus.draft:
      case VBadgeStatus.cancelled:
        backgroundColor = VColors.neutral100;
        textColor = VColors.neutral600;
        break;

      case VBadgeStatus.locked:
        backgroundColor = dynamicColors.background;
        textColor = dynamicColors.textPrimary;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 2 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (iconData != null) ...[
            Icon(
              iconData,
              size: isSmall ? 12 : 16,
              color: textColor,
            ),
            const SizedBox(width: VSpacing.space1),
          ] else if (showDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: VSpacing.space1),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: (isSmall ? VTypography.caption : VTypography.bodySmall).copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
