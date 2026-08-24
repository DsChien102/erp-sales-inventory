import 'package:flutter/material.dart';

import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_shadows.dart';
import 'v_context_extensions.dart';
import 'v_inspector_scope.dart';

/// Anchored overlay menu panel with design-system chrome.
///
/// Uses [VShadows] for bottom-weighted shadow (not Material elevation).
abstract final class VOverlayMenuShell {
  static const List<BoxShadow> menuShadow = VShadows.e1;

  static Widget panel({
    required Widget child,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    BorderSide? borderSide,
    List<BoxShadow>? boxShadow,
    EdgeInsetsGeometry? padding,
  }) {
    return _VOverlayMenuShellPanel(
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      borderSide: borderSide,
      boxShadow: boxShadow ?? menuShadow,
      padding: padding,
      child: child,
    );
  }
}

class _VOverlayMenuShellPanel extends StatelessWidget {
  const _VOverlayMenuShellPanel({
    required this.child,
    this.backgroundColor,
    this.borderRadius,
    this.borderSide,
    required this.boxShadow,
    this.padding,
  });

  final Widget child;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;
  final List<BoxShadow> boxShadow;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final radius = borderRadius ?? BorderRadius.circular(VRadius.input);
    final side = borderSide ?? VBorders.side(colors.borderDefault);

    return vInspectorHide(
      DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.surface,
          borderRadius: radius,
          border: Border.fromBorderSide(side),
          boxShadow: boxShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: padding == null
              ? vInspectorShow(child)
              : Padding(
                  padding: padding!,
                  child: vInspectorShow(child),
                ),
        ),
      ),
    );
  }
}
