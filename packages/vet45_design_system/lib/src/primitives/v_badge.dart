import 'package:flutter/material.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';

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

/// Maps [VBadgeStatus] to semantic [VComponentTone] when no explicit override.
VComponentTone toneFromBadgeStatus(VBadgeStatus status) {
  switch (status) {
    case VBadgeStatus.success:
    case VBadgeStatus.completed:
    case VBadgeStatus.paid:
      return VComponentTone.success;
    case VBadgeStatus.warning:
    case VBadgeStatus.partiallyPaid:
    case VBadgeStatus.outstanding:
      return VComponentTone.warning;
    case VBadgeStatus.danger:
    case VBadgeStatus.overdue:
      return VComponentTone.danger;
    case VBadgeStatus.info:
    case VBadgeStatus.pending:
      return VComponentTone.info;
    case VBadgeStatus.processing:
      return VComponentTone.primary;
    case VBadgeStatus.draft:
    case VBadgeStatus.cancelled:
    case VBadgeStatus.locked:
      return VComponentTone.neutral;
  }
}

class VBadge extends StatelessWidget {
  final String label;
  final VBadgeStatus status;
  final bool showDot;
  final IconData? iconData;
  final bool isSmall;

  /// Optional semantic tone override; defaults to [toneFromBadgeStatus].
  final VComponentTone? tone;

  final String? semanticLabel;

  const VBadge({
    super.key,
    required this.label,
    required this.status,
    this.showDot = false,
    this.iconData,
    this.isSmall = false,
    this.tone,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    final dynamicColors = context.vColors;
    final resolvedTone = tone ?? toneFromBadgeStatus(status);

    switch (status) {
      case VBadgeStatus.success:
      case VBadgeStatus.completed:
      case VBadgeStatus.paid:
        backgroundColor = dynamicColors.successBg;
        textColor = dynamicColors.success;
        break;

      case VBadgeStatus.warning:
      case VBadgeStatus.partiallyPaid:
      case VBadgeStatus.outstanding:
        backgroundColor = dynamicColors.warningBg;
        textColor = dynamicColors.warning;
        break;

      case VBadgeStatus.danger:
      case VBadgeStatus.overdue:
        backgroundColor = dynamicColors.dangerBg;
        textColor = dynamicColors.danger;
        break;

      case VBadgeStatus.info:
      case VBadgeStatus.pending:
        backgroundColor = dynamicColors.infoBg;
        textColor = dynamicColors.info;
        break;

      case VBadgeStatus.processing:
        backgroundColor = dynamicColors.surfaceBrand;
        textColor = dynamicColors.primary;
        break;

      case VBadgeStatus.draft:
      case VBadgeStatus.cancelled:
        backgroundColor = dynamicColors.surfaceAlt;
        textColor = dynamicColors.textSecondary;
        break;

      case VBadgeStatus.locked:
        backgroundColor = dynamicColors.background;
        textColor = dynamicColors.textPrimary;
        break;
    }

    // Tone override adjusts palette when explicitly set.
    if (tone != null) {
      switch (resolvedTone) {
        case VComponentTone.success:
          backgroundColor = dynamicColors.successBg;
          textColor = dynamicColors.success;
        case VComponentTone.warning:
          backgroundColor = dynamicColors.warningBg;
          textColor = dynamicColors.warning;
        case VComponentTone.danger:
          backgroundColor = dynamicColors.dangerBg;
          textColor = dynamicColors.danger;
        case VComponentTone.info:
          backgroundColor = dynamicColors.infoBg;
          textColor = dynamicColors.info;
        case VComponentTone.primary:
          backgroundColor = dynamicColors.surfaceBrand;
          textColor = dynamicColors.primary;
        case VComponentTone.neutral:
          backgroundColor = dynamicColors.surfaceAlt;
          textColor = dynamicColors.textSecondary;
      }
    }

    final badge = Container(
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

    return Semantics(
      label: semanticLabel ?? label,
      child: badge,
    );
  }
}
