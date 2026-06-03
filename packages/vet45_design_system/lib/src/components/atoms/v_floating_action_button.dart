import 'package:flutter/material.dart';
import '../../tokens/v_shadows.dart';
import '../../utils/v_context_extensions.dart';

class VFloatingActionButton extends StatelessWidget {
  final IconData iconData;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const VFloatingActionButton({
    super.key,
    required this.iconData,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final resolvedBgColor = backgroundColor ?? dynamicColors.primary;
    final resolvedIconColor = iconColor ?? Colors.white;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: resolvedBgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: resolvedBgColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          ...VShadows.e3,
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              iconData,
              size: 28,
              color: resolvedIconColor,
            ),
          ),
        ),
      ),
    );
  }
}
