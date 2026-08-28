import 'package:flutter/material.dart';
import '../foundation/v_context_extensions.dart';
import '../foundations/icons/v_icons.dart';
import '../foundation/v_inspector_scope.dart';

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

/// Stroke weight for Lucide glyphs.
///
/// Lucide fonts are static instances, so `Icon(weight:)` has no effect on them.
/// `lucide_icons_flutter` instead ships one font family per weight sharing the
/// same code points, so a weight is applied by swapping [fontFamily].
enum VIconWeight {
  thin('Lucide100'),
  extraLight('Lucide200'),
  light('Lucide300'),
  regular('Lucide400'),
  medium('Lucide500'),
  semiBold('Lucide600');

  const VIconWeight(this.fontFamily);
  final String fontFamily;
}

/// Default Lucide family shipped by [VIcons]; the only one weight applies to.
const String _lucideFamily = 'Lucide';

/// Renders [base] from a per-weight Lucide family.
///
/// Mirrors what [Icon] does internally instead of rebuilding [IconData] at
/// runtime, which would break `--tree-shake-icons` on release builds.
Widget _weightedGlyph(
  IconData base,
  VIconWeight weight, {
  required double size,
  required Color color,
}) {
  return SizedBox(
    width: size,
    height: size,
    child: Center(
      child: Text(
        String.fromCharCode(base.codePoint),
        style: TextStyle(
          inherit: false,
          fontFamily: weight.fontFamily,
          package: base.fontPackage,
          fontSize: size,
          color: color,
          height: 1,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
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

  /// Stroke weight for [icon]. Null keeps the default Lucide family.
  ///
  /// Ignored for [assetPath] and for legacy Material [iconData], which have no
  /// per-weight font families.
  final VIconWeight? weight;

  const VIcon({
    super.key,
    this.icon,
    @Deprecated('Use icon parameter with VIcons instead') this.iconData,
    this.assetPath,
    this.size,
    this.color,
    this.iconSize,
    this.iconColor,
    this.weight,
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
        VIconColor.white => dynamicColors.surface,
      };
    } else {
      resolvedColor = dynamicColors.textPrimary;
    }

    if (assetPath != null) {
      return vInspectorHide(
        Image.asset(
          assetPath!,
          width: resolvedSize,
          height: resolvedSize,
          color: resolvedColor,
          fit: BoxFit.contain,
          // Since we are referencing assets within this package
          package: 'vet45_design_system',
        ),
      );
    }

    final resolvedIconData = icon?.value ?? iconData;

    if (weight != null &&
        resolvedIconData != null &&
        resolvedIconData.fontFamily == _lucideFamily) {
      return vInspectorHide(
        ExcludeSemantics(
          child: _weightedGlyph(
            resolvedIconData,
            weight!,
            size: resolvedSize,
            color: resolvedColor,
          ),
        ),
      );
    }

    return vInspectorHide(
      Icon(
        resolvedIconData,
        size: resolvedSize,
        color: resolvedColor,
      ),
    );
  }
}
