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

  const VCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevated = false,
    this.tone,
    this.emphasis = VComponentEmphasis.medium,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    final borderWidth = emphasis == VComponentEmphasis.strong ? 1.5 : 1.0;
    final borderColor = switch (tone) {
      VComponentTone.primary => dynamicColors.primary.withValues(alpha: 0.35),
      VComponentTone.danger => dynamicColors.danger.withValues(alpha: 0.35),
      _ => dynamicColors.borderDefault,
    };

    return Container(
      decoration: BoxDecoration(
        color: dynamicColors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: elevated
            ? null
            : Border.all(color: borderColor, width: borderWidth),
        boxShadow: elevated ? VShadows.e1 : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VRadius.card),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(VSpacing.md),
            child: child,
          ),
        ),
      ),
    );
  }
}
