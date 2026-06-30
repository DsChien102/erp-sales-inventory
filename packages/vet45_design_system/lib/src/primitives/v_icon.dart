import 'package:flutter/material.dart';
import '../foundation/v_context_extensions.dart';

class VIcon extends StatelessWidget {
  /// The icon data (e.g. `Icons.add`)
  final IconData? iconData;

  /// The path to a custom image asset (e.g. `VAssets.icCalendar`)
  final String? assetPath;

  /// The size of the icon. If null, resolves based on current text scale / defaults.
  final double? size;

  /// The color of the icon. If null, resolves from [VColorScheme.textPrimary] or active theme colors.
  final Color? color;

  const VIcon({
    super.key,
    this.iconData,
    this.assetPath,
    this.size = 24.0,
    this.color,
  }) : assert(
         iconData != null || assetPath != null,
         'Either iconData or assetPath must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final resolvedColor = color ?? dynamicColors.textPrimary;

    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: size,
        height: size,
        color: resolvedColor,
        fit: BoxFit.contain,
        // Since we are referencing assets within this package
        package: 'vet45_design_system',
      );
    }

    return Icon(
      iconData,
      size: size,
      color: resolvedColor,
    );
  }
}
