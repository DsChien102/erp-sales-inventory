import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../foundation/v_inspector_scope.dart';
import '../tokens/v_breakpoints.dart';

/// Resolves a value by [VBreakpoint] with cascade fallbacks.
///
/// Resolution order for a given breakpoint:
/// - desktop → [desktop] ?? [tablet] ?? [mobile]
/// - tablet → [tablet] ?? [mobile]
/// - mobile → [mobile]
@immutable
class VResponsiveValue<T> {
  const VResponsiveValue({
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final T mobile;
  final T? tablet;
  final T? desktop;

  T resolve(VBreakpoint breakpoint) {
    return switch (breakpoint) {
      VBreakpoint.desktop => desktop ?? tablet ?? mobile,
      VBreakpoint.tablet => tablet ?? mobile,
      VBreakpoint.mobile => mobile,
    };
  }

  T resolveForWidth(double width) => resolve(VBreakpoints.ofWidth(width));

  T resolveForContext(BuildContext context) =>
      resolve(VBreakpoints.of(context));
}

/// Rebuilds when the parent constraints' width crosses a breakpoint.
///
/// Uses [LayoutBuilder] so nested panes (not just full window width) drive
/// the active [VBreakpoint].
class VResponsive extends StatelessWidget {
  const VResponsive({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, VBreakpoint breakpoint) builder;

  @override
  Widget build(BuildContext context) {
    return vInspectorHide(
      LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          return vInspectorShow(builder(context, VBreakpoints.ofWidth(width)));
        },
      ),
    );
  }
}
