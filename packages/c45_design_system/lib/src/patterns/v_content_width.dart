import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../foundation/v_inspector_scope.dart';
import 'v_responsive.dart';

/// Centers [child] and constrains max width by breakpoint.
///
/// Defaults: mobile unbounded (full width), tablet 840, desktop 1120.
class VContentWidth extends StatelessWidget {
  const VContentWidth({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;

  /// Optional override; when null, uses breakpoint defaults via [VResponsiveValue].
  final VResponsiveValue<double>? maxWidth;

  final Alignment alignment;

  static const VResponsiveValue<double> defaultMaxWidth = VResponsiveValue(
    mobile: double.infinity,
    tablet: 840,
    desktop: 1120,
  );

  @override
  Widget build(BuildContext context) {
    return VResponsive(
      builder: (context, breakpoint) {
        final resolved =
            (maxWidth ?? defaultMaxWidth).resolve(breakpoint);
        return vInspectorHide(
          Align(
            alignment: alignment,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: resolved),
              child: SizedBox(
                width: double.infinity,
                child: vInspectorShow(child),
              ),
            ),
          ),
        );
      },
    );
  }
}
