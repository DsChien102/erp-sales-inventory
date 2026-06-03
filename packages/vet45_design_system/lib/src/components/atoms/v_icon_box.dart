import 'package:flutter/material.dart';
import '../../tokens/v_colors.dart';
import '../../tokens/v_radius.dart';
import '../../utils/v_context_extensions.dart';

class VIconBox extends StatelessWidget {
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

  const VIconBox({
    super.key,
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
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    
    final resolvedBgColor = backgroundColor ?? VColors.neutral100;
    final resolvedIconColor = iconColor ?? dynamicColors.textPrimary;
    final resolvedRadius = borderRadius ?? VRadius.iconBox;

    Widget iconWidget;
    if (assetPath != null) {
      iconWidget = Image.asset(
        assetPath!,
        width: iconSize,
        height: iconSize,
        color: resolvedIconColor,
        fit: BoxFit.contain,
        package: 'vet45_design_system',
      );
    } else if (iconData != null) {
      iconWidget = Icon(
        iconData,
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
        customBorder: isCircular ? const CircleBorder() : RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(resolvedRadius),
        ),
        child: container,
      );
    }

    return container;
  }
}
