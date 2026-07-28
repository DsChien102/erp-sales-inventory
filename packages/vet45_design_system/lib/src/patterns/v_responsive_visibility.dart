import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../tokens/v_breakpoints.dart';
import 'v_responsive.dart';

/// Shows or hides [child] based on the current [VBreakpoint].
///
/// Prefer one of:
/// - [visibleOn] — exact match
/// - [visibleFrom] — current ≥ from
/// - [visibleUntil] — current ≤ until
///
/// When hidden, renders [SizedBox.shrink] (not [Offstage]) so layout space
/// is released.
class VResponsiveVisibility extends StatelessWidget {
  const VResponsiveVisibility({
    super.key,
    required this.child,
    this.visibleOn,
    this.visibleFrom,
    this.visibleUntil,
    this.maintainState = false,
    this.maintainAnimation = false,
    this.maintainSize = false,
  }) : assert(
         visibleOn != null || visibleFrom != null || visibleUntil != null,
         'Provide visibleOn, visibleFrom, and/or visibleUntil',
       );

  final Widget child;

  /// Visible only on this exact breakpoint.
  final VBreakpoint? visibleOn;

  /// Visible when current breakpoint is at least this value.
  final VBreakpoint? visibleFrom;

  /// Visible when current breakpoint is at most this value.
  final VBreakpoint? visibleUntil;

  final bool maintainState;
  final bool maintainAnimation;
  final bool maintainSize;

  bool _isVisible(VBreakpoint breakpoint) {
    if (visibleOn != null && breakpoint != visibleOn) return false;
    if (visibleFrom != null && !breakpoint.isAtLeast(visibleFrom!)) {
      return false;
    }
    if (visibleUntil != null && !breakpoint.isAtMost(visibleUntil!)) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return VResponsive(
      builder: (context, breakpoint) {
        final visible = _isVisible(breakpoint);
        if (visible) return child;
        if (maintainState || maintainAnimation || maintainSize) {
          return Visibility(
            visible: false,
            maintainState: maintainState,
            maintainAnimation: maintainAnimation,
            maintainSize: maintainSize,
            child: child,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
