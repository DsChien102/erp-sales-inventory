import 'package:flutter/material.dart';
import '../patterns/v_gap.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_inspector_scope.dart';
import '../theme/v_color_scheme.dart';

/// Visual emphasis of [VBadge]. [soft] uses the tinted surface of the tone,
/// [strong] fills with the tone color and inverts the foreground.
enum VBadgeVariant { soft, strong }

@Deprecated('Use VComponentTone + VBadgeVariant instead. Will be removed in a future release.')
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

/// Maps the deprecated [VBadgeStatus] to a semantic [VComponentTone].
@Deprecated('Pass VComponentTone directly. Will be removed in a future release.')
// ignore: deprecated_member_use_from_same_package
VComponentTone toneFromBadgeStatus(VBadgeStatus status) {
  switch (status) {
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.success:
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.completed:
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.paid:
      return VComponentTone.success;
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.warning:
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.partiallyPaid:
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.outstanding:
      return VComponentTone.warning;
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.danger:
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.overdue:
      return VComponentTone.danger;
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.info:
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.pending:
      return VComponentTone.info;
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.processing:
      return VComponentTone.primary;
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.draft:
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.cancelled:
    // ignore: deprecated_member_use_from_same_package
    case VBadgeStatus.locked:
      return VComponentTone.neutral;
  }
}

/// Tinted surface of a tone (shade 50 in light theme).
Color _softBackground(VColorScheme colors, VComponentTone tone) {
  return switch (tone) {
    VComponentTone.primary => colors.surfaceBrand,
    VComponentTone.success => colors.successBg,
    VComponentTone.warning => colors.warningBg,
    VComponentTone.danger => colors.dangerBg,
    VComponentTone.info => colors.infoBg,
    VComponentTone.neutral => colors.surfaceAlt,
  };
}

/// Tinted surface of a tone (shade 50 in light theme).
Color _strongBackground(VColorScheme colors, VComponentTone tone) {
  return switch (tone) {
    VComponentTone.primary || VComponentTone.success => colors.success,
    VComponentTone.warning => colors.warning,
    VComponentTone.danger => colors.danger,
    VComponentTone.info => colors.info,
    VComponentTone.neutral => colors.textPrimary,
  };
}

class VBadge extends StatelessWidget {
  final String label;

  @Deprecated('Use tone + variant instead. Will be removed in a future release.')
  // ignore: deprecated_member_use_from_same_package
  final VBadgeStatus? status;

  final bool showDot;
  final IconData? iconData;
  final bool isSmall;

  /// Semantic tone; falls back to ambient [VComponentScope] then [neutral].
  final VComponentTone? tone;

  /// Emphasis of the tone palette. Defaults to [VBadgeVariant.soft].
  final VBadgeVariant variant;

  final String? semanticLabel;

  const VBadge({
    super.key,
    required this.label,
    // ignore: deprecated_member_use_from_same_package
    @Deprecated('Use tone + variant instead. Will be removed in a future release.') this.status,
    this.showDot = false,
    this.iconData,
    this.isSmall = false,
    this.tone,
    this.variant = VBadgeVariant.soft,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    // ignore: deprecated_member_use_from_same_package
    final legacyStatus = status;
    final resolvedTone =
        VComponentScope.resolveTone(context, local: tone) ??
        // ignore: deprecated_member_use_from_same_package
        (legacyStatus != null ? toneFromBadgeStatus(legacyStatus) : null) ??
        VComponentTone.neutral;

    // Shade 500 of the tone (neutral maps to textPrimary).
    final toneColor = dynamicColors.foregroundForTone(resolvedTone)!;

    final Color backgroundColor;
    final Color textColor;
    switch (variant) {
      case VBadgeVariant.soft:
        backgroundColor = _softBackground(dynamicColors, resolvedTone);
        textColor = toneColor;
      case VBadgeVariant.strong:
        backgroundColor = _strongBackground(dynamicColors, resolvedTone);
        textColor = dynamicColors.textInverse;
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
            const VGap(VSpacing.space1, axis: Axis.horizontal),
          ] else if (showDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const VGap(VSpacing.space1, axis: Axis.horizontal),
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

    return vInspectorHide(
      Semantics(
        label: semanticLabel ?? label,
        child: badge,
      ),
    );
  }
}
