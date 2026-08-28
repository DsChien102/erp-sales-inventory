import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'v_icon.dart';
import '../foundation/v_inspector_scope.dart';

/// Visual weight for chips — mirrors Polaris clickable-chip `color`
/// (`subdued` / `base` / `strong`).
@Deprecated('Use VComponentEmphasis instead')
enum VChipEmphasis { subdued, base, strong }

/// Upper bound for chip icons; clamped further by the label line height.
const double _maxIconSize = 12;

/// Flexible chip: static label, selectable filter, or removable tag.
///
/// - No [onTap] / [onRemove] → static chip (Polaris `chip`)
/// - [onTap] set → clickable (Polaris `clickable-chip`)
/// - [onRemove] set → shows a dismiss control
///
/// Colors come from [tone] only: tinted surface, tone foreground, solid border.
/// [enabled] null inherits from [VComponentScope]; false disables the chip.
class VChip extends StatelessWidget {
  const VChip({
    super.key,
    required this.label,
    this.tone,
    @Deprecated('Use tone instead. Will be removed in a future release.') this.emphasis,
    @Deprecated('Use tone: VComponentTone.primary when the chip is selected.') this.selected,
    this.onTap,
    this.onRemove,
    this.icon,
    @Deprecated('Use icon instead') this.leadingIcon,
    this.enabled,
    this.semanticLabel,
  });

  final String label;

  @Deprecated('Use tone instead. Will be removed in a future release.')
  final VComponentEmphasis? emphasis;

  @Deprecated('Use tone: VComponentTone.primary when the chip is selected.')
  final bool? selected;

  /// When null (and [onRemove] is null), chip is non-interactive.
  final VoidCallback? onTap;

  /// When set, shows a trailing remove control. Does not invoke [onTap].
  final VoidCallback? onRemove;

  final VIcons? icon;

  @Deprecated('Use icon instead')
  final IconData? leadingIcon;

  final bool? enabled;
  final String? semanticLabel;

  /// Semantic tone; falls back to ambient [VComponentScope] then [neutral].
  final VComponentTone? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEnabled = VComponentScope.resolveEnabled(context, local: enabled);
    final isInteractive = isEnabled && (onTap != null || onRemove != null);
    final resolvedTone =
        VComponentScope.resolveTone(context, local: tone) ??
        _toneFromLegacyProps() ??
        VComponentTone.neutral;

    final foreground = colors.foregroundForTone(resolvedTone)!;
    final labelStyle = VTypography.bodySmall.copyWith(
      color: foreground,
      fontWeight: FontWeight.w600,
    );

    // Icons must never make the chip taller than a single line of label text.
    final lineHeight = labelStyle.fontSize! * labelStyle.height!;
    final iconSize = math.min(_maxIconSize, lineHeight);

    Widget chipBody = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null || leadingIcon != null) ...[
          SizedBox(
            height: lineHeight,
            child: VIcon(
              icon: icon,
              iconData: icon == null ? leadingIcon : null,
              size: iconSize,
              color: foreground,
            ),
          ),
          const VGap(VSpacing.space2, axis: Axis.horizontal),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
        if (onRemove != null) ...[
          const VGap(VSpacing.space1, axis: Axis.horizontal),
          _RemoveButton(
            color: foreground,
            extent: lineHeight,
            iconSize: iconSize,
            onPressed: isEnabled ? onRemove : null,
          ),
        ],
      ],
    );

    chipBody = Container(
      padding: EdgeInsets.only(
        left: VSpacing.space3,
        right: onRemove != null ? VSpacing.space1 : VSpacing.space3,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundForTone(resolvedTone),
        borderRadius: BorderRadius.circular(VRadius.pill),
        border: VBorders.all(colors.borderForTone(resolvedTone)!),
      ),
      child: chipBody,
    );

    if (!isEnabled) {
      chipBody = Opacity(opacity: 0.5, child: chipBody);
    }

    final semanticsLabel = semanticLabel ?? label;

    if (!isInteractive) {
      return vInspectorHide(
        Semantics(
          label: semanticsLabel,
          enabled: isEnabled,
          child: chipBody,
        ),
      );
    }

    return vInspectorHide(
      Semantics(
        button: onTap != null,
        enabled: isEnabled,
        label: semanticsLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: isEnabled && onTap != null ? onTap : null,
            borderRadius: BorderRadius.circular(VRadius.r16),
            child: chipBody,
          ),
        ),
      ),
    );
  }

  /// Maps the deprecated [selected] / [emphasis] props onto a tone.
  VComponentTone? _toneFromLegacyProps() {
    // ignore: deprecated_member_use_from_same_package
    if (selected ?? false) return VComponentTone.primary;
    // ignore: deprecated_member_use_from_same_package
    return switch (emphasis) {
      VComponentEmphasis.strong => VComponentTone.primary,
      VComponentEmphasis.subtle || VComponentEmphasis.medium => VComponentTone.neutral,
      null => null,
    };
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({
    required this.onPressed,
    required this.color,
    required this.extent,
    required this.iconSize,
  });

  final VoidCallback? onPressed;
  final Color color;
  final double extent;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: extent,
      height: extent,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: BoxConstraints.tightFor(width: extent, height: extent),
        iconSize: iconSize,
        tooltip: 'Xóa',
        onPressed: onPressed,
        icon: Icon(Icons.close, color: color),
      ),
    );
  }
}
