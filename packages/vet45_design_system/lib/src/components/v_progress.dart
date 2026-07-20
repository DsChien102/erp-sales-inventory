import 'package:flutter/material.dart';
import '../foundation/v_context_extensions.dart';

class VProgress extends StatelessWidget {
  final double value; // Between 0.0 and 1.0
  final double height;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool animated;
  final Duration duration;
  final String? semanticLabel;

  const VProgress({
    super.key,
    required this.value,
    this.height = 8.0,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.animated = true,
    this.duration = const Duration(milliseconds: 300),
    this.semanticLabel,
  }) : assert(value >= 0.0 && value <= 1.0);

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final activeColor = color ?? dynamicColors.primary;
    final trackColor = backgroundColor ?? dynamicColors.surfaceAlt;
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    Widget buildIndicator(double val) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: radius,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: val,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: radius,
              ),
            ),
          ),
        ),
      );
    }

    Widget progressWidget;
    if (animated) {
      progressWidget = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: value),
        duration: duration,
        curve: Curves.easeInOut,
        builder: (context, val, child) {
          return buildIndicator(val);
        },
      );
    } else {
      progressWidget = buildIndicator(value);
    }

    return Semantics(
      label: semanticLabel ?? 'Tiến trình',
      value: '${(value * 100).toStringAsFixed(0)}%',
      child: progressWidget,
    );
  }
}
