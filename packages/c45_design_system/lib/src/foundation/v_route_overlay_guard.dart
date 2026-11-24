import 'package:flutter/material.dart';

/// Guards overlay/menu widgets from attaching during route transitions.
abstract final class VRouteOverlayGuard {
  static bool isLayoutReady(BuildContext context) {
    if (!context.mounted) return false;
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return false;

    final animation = route.animation;
    if (animation != null && (animation.isAnimating || animation.value < 1.0)) {
      return false;
    }

    final secondary = route.secondaryAnimation;
    if (secondary != null && secondary.isAnimating) return false;

    final navigator = Navigator.maybeOf(context);
    if (navigator?.userGestureInProgress ?? false) return false;

    return true;
  }
}
