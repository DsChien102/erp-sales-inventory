import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundations/icons/v_icons.dart';
import '../theme/v_color_scheme.dart';
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

/// Flexible chip: static label, selectable filter, or removable tag.
///
/// - No [onTap] / [onRemove] → static chip (Polaris `chip`)
/// - [onTap] set → clickable (Polaris `clickable-chip`)
/// - [onRemove] set → shows a dismiss control
///
/// [enabled] maps to [VComponentState.enabled] / [VComponentState.disabled].
class VChip extends StatelessWidget {
  const VChip({
    super.key,
    required this.label,
    this.emphasis = VComponentEmphasis.medium,
    this.selected = false,
    this.onTap,
    this.onRemove,
    this.icon,
    @Deprecated('Use icon instead') this.leadingIcon,
    this.enabled = true,
    this.semanticLabel,
    this.tone,
    this.state,
  });

  final String label;

  /// Emphasis when not [selected]. Selected chips use a filled tone style.
  final VComponentEmphasis emphasis;

  /// Filter/choice selection — filled success when true.
  final bool selected;

  /// When null (and [onRemove] is null), chip is non-interactive.
  final VoidCallback? onTap;

  /// When set, shows a trailing remove control. Does not invoke [onTap].
  final VoidCallback? onRemove;

  final VIcons? icon;

  @Deprecated('Use icon instead')
  final IconData? leadingIcon;

  final bool enabled;
  final String? semanticLabel;

  /// Optional semantic tone for selected/filled chips. Defaults to success.
  final VComponentTone? tone;

  /// Optional state override; defaults from [enabled].
  final VComponentState? state;

  VComponentState get _resolvedState =>
      state ?? (enabled ? VComponentState.enabled : VComponentState.disabled);

  bool get _isEnabled => _resolvedState == VComponentState.enabled;

  bool get _isInteractive => _isEnabled && (onTap != null || onRemove != null);

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final resolvedTone = VComponentScope.resolveTone(context, local: tone);
    final resolved = _resolveColors(colors, tone: resolvedTone);

    final labelStyle = VTypography.bodySmall.copyWith(
      color: resolved.foreground,
      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
    );

    Widget chipBody = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null || leadingIcon != null) ...[
          VIcon(
            icon: icon,
            iconData: icon == null ? leadingIcon : null,
            size: 16,
            color: resolved.foreground,
          ),
          const SizedBox(width: VSpacing.space1),
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
          const SizedBox(width: VSpacing.space1),
          _RemoveButton(
            color: resolved.foreground,
            onPressed: _isEnabled ? onRemove : null,
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
        color: resolved.background,
        borderRadius: BorderRadius.circular(VRadius.r16),
        border: resolved.border,
      ),
      child: chipBody,
    );

    if (!_isEnabled) {
      chipBody = Opacity(opacity: 0.5, child: chipBody);
    }

    final semanticsLabel = semanticLabel ?? label;

    if (!_isInteractive) {
      return vInspectorHide(
        Semantics(
          label: semanticsLabel,
          enabled: _isEnabled,
          child: chipBody,
        ),
      );
    }

    return vInspectorHide(
      Semantics(
        button: onTap != null,
        enabled: _isEnabled,
        label: semanticsLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: _isEnabled && onTap != null ? onTap : null,
            borderRadius: BorderRadius.circular(VRadius.r16),
            child: chipBody,
          ),
        ),
      ),
    );
  }

  _ChipColors _resolveColors(
    VColorScheme colors, {
    VComponentTone? tone,
  }) {
    if (selected) {
      final fillTone = tone ?? VComponentTone.success;
      final fill = _toneFill(colors, fillTone);
      return _ChipColors(
        background: fill,
        foreground: colors.surface,
        border: null,
      );
    }

    switch (emphasis) {
      case VComponentEmphasis.subtle:
        return _ChipColors(
          background: colors.surfaceAlt,
          foreground: colors.textSecondary,
          border: null,
        );
      case VComponentEmphasis.medium:
        return _ChipColors(
          background: colors.surface,
          foreground: colors.textPrimary,
          border: VBorders.all(colors.borderDefault),
        );
      case VComponentEmphasis.strong:
        return _ChipColors(
          background: colors.surfaceBrand,
          foreground: colors.primary,
          border: VBorders.all(colors.primary.withValues(alpha: 0.35)),
        );
    }
  }

  Color _toneFill(VColorScheme colors, VComponentTone tone) {
    return switch (tone) {
      VComponentTone.neutral => colors.textPrimary,
      VComponentTone.primary => colors.primary,
      VComponentTone.success => colors.success,
      VComponentTone.warning => colors.warning,
      VComponentTone.danger => colors.danger,
      VComponentTone.info => colors.info,
    };
  }
}

class _ChipColors {
  const _ChipColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Border? border;
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({
    required this.onPressed,
    required this.color,
  });

  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 24, height: 24),
        iconSize: 16,
        tooltip: 'Xóa',
        onPressed: onPressed,
        icon: Icon(Icons.close, color: color),
      ),
    );
  }
}
