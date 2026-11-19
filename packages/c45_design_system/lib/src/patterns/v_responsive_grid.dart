import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../foundation/v_inspector_scope.dart';
import '../tokens/v_spacing.dart';
import 'v_responsive.dart';

/// Adaptive column grid driven by parent width breakpoints.
///
/// Default columns: mobile 1, tablet 2, desktop 3.
class VResponsiveGrid extends StatelessWidget {
  const VResponsiveGrid({
    super.key,
    required this.children,
    this.columns = const VResponsiveValue(
      mobile: 1,
      tablet: 2,
      desktop: 3,
    ),
    this.spacing = VSpacing.md,
    this.runSpacing = VSpacing.md,
  });

  final List<Widget> children;
  final VResponsiveValue<int> columns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return VResponsive(
      builder: (context, breakpoint) {
        final columnCount = columns.resolve(breakpoint).clamp(1, 12);
        return vInspectorHide(
          LayoutBuilder(
            builder: (context, constraints) {
              final totalSpacing = spacing * (columnCount - 1);
              final itemWidth =
                  (constraints.maxWidth - totalSpacing) / columnCount;

              return Wrap(
                spacing: spacing,
                runSpacing: runSpacing,
                children: [
                  for (final child in children)
                    SizedBox(
                      width: itemWidth,
                      child: vInspectorShow(child),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
