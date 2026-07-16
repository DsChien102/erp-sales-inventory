import 'package:flutter/material.dart';
import '../tokens/v_colors.dart';
import '../tokens/v_radius.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../foundations/icons/v_icons.dart';
import 'v_icon.dart';

class VIconBox extends StatelessWidget {
  /// Semantic icon registry token
  final VIcons? icon;

  /// Legacy Material IconData fallback
  final IconData? iconData;

  final String? assetPath;
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

  (Color bg, Color icon) _tonePreset(VComponentTone tone, dynamic dynamicColors) {
    return switch (tone) {
      VComponentTone.primary => (VColors.primary100, dynamicColors.primary),
      VComponentTone.success => (VColors.successBg, VColors.success),
      VComponentTone.warning => (VColors.warningBg, VColors.warning),
      VComponentTone.danger => (VColors.dangerBg, VColors.danger),
      VComponentTone.info => (VColors.infoBg, VColors.info),
      VComponentTone.neutral => (VColors.neutral100, VColors.neutral500),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    Color resolvedBgColor = backgroundColor ?? VColors.neutral100;
    Color resolvedIconColor = iconColor ?? dynamicColors.textPrimary;

    if (tone != null && backgroundColor == null && iconColor == null) {
      final preset = _tonePreset(tone!, dynamicColors);
      resolvedBgColor = preset.$1;
      resolvedIconColor = preset.$2;
    }

    final resolvedRadius = borderRadius ?? VRadius.iconBox;

    Widget iconWidget;
    if (assetPath != null || icon != null || iconData != null) {
      iconWidget = VIcon(
        icon: icon,
        iconData: iconData,
        assetPath: assetPath,
        size: iconSize,
        color: resolvedIconColor,
      );
    } else {
      iconWidget = const SizedBox.shrink();
    }

    Widget container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolvedBgColor,
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(resolvedRadius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth ?? 1.0)
            : null,
      ),
      alignment: Alignment.center,
      child: iconWidget,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: isCircular
            ? const CircleBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(resolvedRadius),
              ),
        child: container,
      );
    }

    return container;
  }
}
