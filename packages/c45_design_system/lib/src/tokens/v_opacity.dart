import 'package:flutter/widgets.dart';

/// Shared opacity values for design-system interaction states.
class VOpacity {
  VOpacity._();

  /// Opacity applied to the whole control when disabled.
  static const double disabled = 0.4;
}

/// Keeps enabled colors; fades the subtree when [enabled] is false.
Widget vDisabledOpacity({
  required bool enabled,
  required Widget child,
}) {
  if (enabled) return child;
  return Opacity(opacity: VOpacity.disabled, child: child);
}
