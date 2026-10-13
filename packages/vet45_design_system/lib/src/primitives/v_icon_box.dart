import 'package:flutter/material.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../theme/v_color_scheme.dart';
import '../foundations/icons/v_icons.dart';
import 'v_icon.dart';
import 'v_text.dart';
import '../foundation/v_inspector_scope.dart';

class VIconBox extends StatelessWidget {
  /// Semantic icon registry token
  final VIcons? icon;

  /// Legacy Material IconData fallback
  final IconData? iconData;

  final String? assetPath;

  /// Text label (e.g. avatar initials). Takes precedence over icon/asset.
  final String? label;

  /// Accessibility name for the tappable box (screen readers).
  ///
  /// Required in practice when [onTap] is set and there is no visible [label];
  /// debug builds assert on that combination.
  final String? semanticLabel;

  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? borderRadius;
  final bool isCircular;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double? borderWidth;

  /// Optional tone preset for bg/icon when explicit colors are omitted.
  final VComponentTone? tone;

  const VIconBox({
    super.key,
    this.icon,
    this.iconData,
    this.assetPath,
    this.label,
    this.semanticLabel,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.backgroundColor,
    this.iconColor,
    this.borderRadius,
    this.isCircular = false,
    this.onTap,
    this.borderColor,
    this.borderWidth,
    this.tone,
  });

  (Color bg, Color icon) _tonePreset(VComponentTone tone, VColorScheme dynamicColors) {
    return switch (tone) {
      VComponentTone.primary => (dynamicColors.surface, dynamicColors.primary),
      VComponentTone.success => (dynamicColors.successBg, dynamicColors.success),
      VComponentTone.warning => (dynamicColors.warningBg, dynamicColors.warning),
      VComponentTone.danger => (dynamicColors.dangerBg, dynamicColors.danger),
      VComponentTone.info => (dynamicColors.infoBg, dynamicColors.info),
      VComponentTone.neutral => (dynamicColors.surface, dynamicColors.textSecondary),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final resolvedTone = VComponentScope.resolveTone(context, local: tone);

    Color resolvedBgColor = backgroundColor ?? dynamicColors.surface;
    Color resolvedIconColor = iconColor ?? dynamicColors.textPrimary;

    if (resolvedTone != null && backgroundColor == null && iconColor == null) {
      final preset = _tonePreset(resolvedTone, dynamicColors);
      resolvedBgColor = preset.$1;
      resolvedIconColor = preset.$2;
    }

    final resolvedRadius = borderRadius ?? VRadius.iconBox;

    final Widget child;
    final trimmedLabel = label?.trim();
    if (trimmedLabel != null && trimmedLabel.isNotEmpty) {
      child = VText(
        trimmedLabel,
        variant: size >= 56 ? VTextVariant.headingH2 : VTextVariant.bodyDefault,
        color: resolvedIconColor,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontWeight: size >= 56 ? FontWeight.w700 : FontWeight.w600,
          fontSize: iconSize,
          height: 1,
        ),
      );
    } else if (assetPath != null || icon != null || iconData != null) {
      child = VIcon(
        icon: icon,
        iconData: iconData,
        assetPath: assetPath,
        size: iconSize,
        color: resolvedIconColor,
      );
    } else {
      child = const SizedBox.shrink();
    }

    Widget container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolvedBgColor,
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(resolvedRadius),
        border: borderColor != null
            ? VBorders.all(borderColor!, width: borderWidth ?? VBorders.thin)
            : null,
      ),
      alignment: Alignment.center,
      child: child,
    );

    if (onTap != null) {
      final hasVisibleLabel = trimmedLabel != null && trimmedLabel.isNotEmpty;
      assert(
        hasVisibleLabel || (semanticLabel != null && semanticLabel!.isNotEmpty),
        'VIconBox with onTap needs semanticLabel',
      );
      // The drawn box keeps [size]; the tappable area is at least 44×44.
      return vInspectorHide(
        Semantics(
          button: true,
          label: semanticLabel ?? trimmedLabel,
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: onTap,
            customBorder: isCircular
                ? const CircleBorder()
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(resolvedRadius),
                  ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: VSpacing.minTouchTarget,
                minHeight: VSpacing.minTouchTarget,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                // The name comes from the wrapper above; keep the tap action.
                child: ExcludeSemantics(child: container),
              ),
            ),
          ),
        ),
      );
    }

    return vInspectorHide(container);
  }
}
