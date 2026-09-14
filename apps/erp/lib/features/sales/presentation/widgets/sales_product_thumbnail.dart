import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Product thumbnail square.
class SalesProductThumbnail extends StatelessWidget {
  const SalesProductThumbnail({
    super.key,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.borderRadius = VRadius.r8,
    this.icon = VIcons.inventory,
    this.backgroundColor,
    this.iconColor,
    this.image,
  });

  final double size;
  final double iconSize;
  final double borderRadius;
  final VIcons icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Widget? image;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final bg = backgroundColor ?? colors.surfaceAlt;
    final fg = iconColor ?? colors.textSecondary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color: bg,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child:
                image ??
                VIcon(
                  icon: icon,
                  size: iconSize,
                  color: fg,
                ),
          ),
        ),
      ),
    );
  }
}
