import 'package:flutter/material.dart';

import 'v_route_overlay_guard.dart';

/// Shared layout helpers for anchored dropdown menus above keyboard/sticky bars.
abstract final class VOverlayMenuLayout {
  static const Offset alignmentOffset = Offset(0, 4);
  static const AlignmentGeometry alignment = AlignmentDirectional.bottomStart;

  static const double defaultMenuHeight = 180;
  static const double minMenuHeight = 88;

  /// Space below the field for a downward menu.
  ///
  /// Safe to call after layout (e.g. post-frame). Must not be relied on during
  /// `build`: `localToGlobal` walks ancestors and can hit a
  /// [RenderFractionalTranslation] (route [SlideTransition]) that has not been
  /// laid out yet → `hasSize` assertion.
  static double availableSpace(
    BuildContext context, {
    double stickyActionsReserve = 0,
  }) {
    if (!VRouteOverlayGuard.isLayoutReady(context)) {
      return defaultMenuHeight;
    }

    final media = MediaQuery.of(context);
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) {
      return defaultMenuHeight;
    }

    try {
      final fieldBottom = box.localToGlobal(Offset(0, box.size.height)).dy;
      final usableBottom = media.size.height - media.viewInsets.bottom - stickyActionsReserve;
      return usableBottom - fieldBottom - alignmentOffset.dy;
    } on AssertionError {
      // Ancestor transform (e.g. route FractionalTranslation) not laid out yet.
      return defaultMenuHeight;
    }
  }

  static double resolvedMenuHeight(
    BuildContext context, {
    double preferredHeight = defaultMenuHeight,
    double minHeight = minMenuHeight,
    double stickyActionsReserve = 0,
  }) {
    final available = availableSpace(
      context,
      stickyActionsReserve: stickyActionsReserve,
    );
    if (available >= preferredHeight) return preferredHeight;
    if (available <= minHeight) return minHeight;
    return available;
  }

  static Future<void> ensureOpensDownward(
    BuildContext context, {
    double stickyActionsReserve = 0,
    bool anticipateKeyboard = false,
  }) {
    if (!context.mounted || !VRouteOverlayGuard.isLayoutReady(context)) {
      return Future<void>.value();
    }

    final media = MediaQuery.of(context);
    final hasKeyboard = media.viewInsets.bottom > 0;
    return Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: hasKeyboard || anticipateKeyboard ? 0.02 : 0.12,
    );
  }
}
