import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../tokens/v_breakpoints.dart';
import '../tokens/v_spacing.dart';

/// Standard screen inset padding (mobile / tablet / desktop breakpoints).
class VPagePadding extends StatelessWidget {
  const VPagePadding({
    super.key,
    required this.child,
    this.horizontal,
    this.vertical,
    this.applyBottomSafeArea = false,
  });

  final Widget child;

  /// Override horizontal inset; defaults to breakpoint-based screen padding.
  final double? horizontal;

  /// Optional vertical padding in addition to horizontal.
  final double? vertical;

  final bool applyBottomSafeArea;

  static double horizontalForWidth(double width) {
    return switch (VBreakpoints.ofWidth(width)) {
      VBreakpoint.desktop => VSpacing.screenDesktop,
      VBreakpoint.tablet => VSpacing.screenTablet,
      VBreakpoint.mobile => VSpacing.screenMobile,
    };
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final h = horizontal ?? horizontalForWidth(width);
    final v = vertical ?? 0.0;

    Widget padded = Padding(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: v),
      child: child,
    );

    if (applyBottomSafeArea) {
      padded = SafeArea(top: false, child: padded);
    }

    return padded;
  }
}
