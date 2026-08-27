import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../tokens/v_borders.dart';

/// Thin separator line (horizontal or vertical).
///
/// Defaults: [thickness] = [VBorders.thin] (1), [color] = [VColorScheme.borderDefault].
class VDivider extends StatelessWidget {
  const VDivider({
    super.key,
    this.axis = Axis.horizontal,
    this.thickness = VBorders.thin,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  });

  /// [Axis.horizontal] spans parent width; [Axis.vertical] spans parent height.
  final Axis axis;

  /// Stroke thickness along the cross-axis (default 1).
  final double thickness;

  /// Line color; null resolves to ambient [VColorScheme.borderDefault].
  final Color? color;

  /// Leading inset (left for horizontal, top for vertical).
  final double indent;

  /// Trailing inset (right for horizontal, bottom for vertical).
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? context.vColors.borderDefault;

    if (axis == Axis.horizontal) {
      return vInspectorHide(
        Container(
          margin: EdgeInsetsDirectional.only(start: indent, end: endIndent),
          width: double.infinity,
          height: thickness,
          color: resolvedColor,
        ),
      );
    }

    return vInspectorHide(
      Container(
        margin: EdgeInsetsDirectional.only(top: indent, bottom: endIndent),
        width: thickness,
        height: double.infinity,
        color: resolvedColor,
      ),
    );
  }
}
