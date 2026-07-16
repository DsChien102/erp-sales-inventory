import 'package:flutter/material.dart';
import '../foundation/v_context_extensions.dart';
import '../foundations/icons/v_icons.dart';

enum VIconSize {
  xs(16.0),
  sm(20.0),
  md(24.0),
  lg(32.0),
  xl(40.0);

  const VIconSize(this.value);
  final double value;
}

enum VIconColor {
  primary,
  secondary,
  muted,
  success,
  warning,
  danger,
  info,
  white,
}

class VIcon extends StatelessWidget {
  /// Semantic icon registry token
  final VIcons? icon;

  /// Deprecated: Use [icon] instead. Legacy Material IconData fallback.
  @Deprecated('Use icon parameter with VIcons instead')
  final IconData? iconData;

  /// The path to a custom image asset (e.g. `VAssets.icCalendar`)
  final String? assetPath;

  /// The size of the icon. If null, resolves based on [iconSize] or defaults.
  final double? size;

  /// The color of the icon. If null, resolves from [iconColor] or theme defaults.
  final Color? color;

  /// Semantic icon size token
  final VIconSize? iconSize;

  /// Semantic icon color token
  final VIconColor? iconColor;

  const VIcon({
    super.key,
    this.icon,
    @Deprecated('Use icon parameter with VIcons instead') this.iconData,
    this.assetPath,
    this.size,
    this.color,
    this.iconSize,
    this.iconColor,
  }) : assert(
         icon != null || iconData != null || assetPath != null,
         'Either icon, iconData, or assetPath must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    // Resolve size
    final resolvedSize = size ?? iconSize?.value ?? 24.0;

    // Resolve color
    Color resolvedColor;
    if (color != null) {
      resolvedColor = color!;
    } else if (iconColor != null) {
      resolvedColor = switch (iconColor!) {
        VIconColor.primary => dynamicColors.primary,
        VIconColor.secondary => dynamicColors.textSecondary,
        VIconColor.muted => dynamicColors.textMuted,
        VIconColor.success => dynamicColors.success,
        VIconColor.warning => dynamicColors.warning,
        VIconColor.danger => dynamicColors.danger,
        VIconColor.info => dynamicColors.info,
        VIconColor.white => const Color(0xFFFFFFFF),
      };
    } else {
      resolvedColor = dynamicColors.textPrimary;
    }

    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: resolvedSize,
        height: resolvedSize,
        color: resolvedColor,
        fit: BoxFit.contain,
        // Since we are referencing assets within this package
        package: 'vet45_design_system',
      );
    }

    final resolvedIconData = icon?.value ?? iconData;

    return Icon(
      resolvedIconData,
      size: resolvedSize,
      color: resolvedColor,
    );
  }
}
