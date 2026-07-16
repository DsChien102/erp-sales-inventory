import 'package:flutter/material.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_shadows.dart';
import '../tokens/v_spacing.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';

class VCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool elevated;
  final VComponentTone? tone;
  final VComponentEmphasis emphasis;
  final Color? backgroundColor;
  final Border? border;
  final double? borderRadius;

  const VCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevated = false,
    this.tone,
    this.emphasis = VComponentEmphasis.medium,
    this.backgroundColor,
    this.border,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    final borderWidth = emphasis == VComponentEmphasis.strong ? 1.5 : 1.0;
    final resolvedBorderColor = switch (tone) {
      VComponentTone.primary => dynamicColors.primary.withValues(alpha: 0.35),
      VComponentTone.danger => dynamicColors.danger.withValues(alpha: 0.35),
      _ => dynamicColors.borderDefault,
    };

    final resolvedRadius = borderRadius ?? VRadius.card;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? dynamicColors.surface,
        borderRadius: BorderRadius.circular(resolvedRadius),
        border: border ?? (elevated
            ? null
            : Border.all(color: resolvedBorderColor, width: borderWidth)),
        boxShadow: elevated ? VShadows.e1 : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(resolvedRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(VSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}
