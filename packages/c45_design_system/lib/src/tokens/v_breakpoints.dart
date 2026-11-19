import 'package:flutter/widgets.dart';

/// Width-based layout breakpoints used across responsive patterns.
///
/// - [mobile]: width < [VBreakpoints.tablet]
/// - [tablet]: [VBreakpoints.tablet] ≤ width < [VBreakpoints.desktop]
/// - [desktop]: width ≥ [VBreakpoints.desktop]
enum VBreakpoint {
  mobile,
  tablet,
  desktop;

  bool get isMobile => this == VBreakpoint.mobile;
  bool get isTablet => this == VBreakpoint.tablet;
  bool get isDesktop => this == VBreakpoint.desktop;

  bool isAtLeast(VBreakpoint other) => index >= other.index;

  bool isAtMost(VBreakpoint other) => index <= other.index;
}

/// Named breakpoint width thresholds.
abstract final class VBreakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  static VBreakpoint ofWidth(double width) {
    if (width >= desktop) return VBreakpoint.desktop;
    if (width >= tablet) return VBreakpoint.tablet;
    return VBreakpoint.mobile;
  }

  static VBreakpoint of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);
}
