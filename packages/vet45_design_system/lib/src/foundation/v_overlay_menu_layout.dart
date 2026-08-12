import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/v_spacing.dart';
import 'v_route_overlay_guard.dart';

/// Shared layout helpers for anchored dropdown menus above keyboard/sticky bars.
abstract final class VOverlayMenuLayout {
  static const Offset alignmentOffset = Offset(0, VSpacing.space2);
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

  /// Panel sizing for fixed-shell menus with an inner scroll viewport.
  static VOverlayMenuPanelMetrics panelMetrics({
    required int itemCount,
    required double menuMaxHeight,
    required double itemHeight,
    required double menuPadding,
  }) {
    final listMaxHeight = menuMaxHeight - (menuPadding * 2);
    final contentHeight = itemCount * itemHeight;
    final needsScroll = contentHeight > listMaxHeight;
    final listViewportHeight = needsScroll ? listMaxHeight : contentHeight;
    final shellHeight = (contentHeight + menuPadding * 2).clamp(0.0, menuMaxHeight);

    return VOverlayMenuPanelMetrics(
      shellHeight: shellHeight,
      listViewportHeight: listViewportHeight,
      needsScroll: needsScroll,
    );
  }

  /// Layout padding so [BoxShadow] on a child [DecoratedBox] is not clipped by
  /// [MenuAnchor]'s overlay (shadow paints outside the child's layout bounds).
  static EdgeInsets shadowBleedPadding(List<BoxShadow> shadows) {
    if (shadows.isEmpty) {
      return EdgeInsets.zero;
    }

    var top = 0.0;
    var left = 0.0;
    var right = 0.0;
    var bottom = 0.0;

    for (final shadow in shadows) {
      final blur = shadow.blurRadius;
      final spread = shadow.spreadRadius;
      top = math.max(top, blur + spread - shadow.offset.dy);
      bottom = math.max(bottom, blur + spread + shadow.offset.dy);
      left = math.max(left, blur + spread - shadow.offset.dx);
      right = math.max(right, blur + spread + shadow.offset.dx);
    }

    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  /// [shadowBleedPadding] plus default overlay safe inset for [MenuAnchor].
  static EdgeInsets menuReservedPadding(List<BoxShadow> shadows) {
    const overlayInset = EdgeInsets.all(VSpacing.space2);
    final bleed = shadowBleedPadding(shadows);
    return EdgeInsets.fromLTRB(
      bleed.left + overlayInset.left,
      bleed.top + overlayInset.top,
      bleed.right + overlayInset.right,
      bleed.bottom + overlayInset.bottom,
    );
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

/// Resolved heights for [VOverlayMenuLayout.panelMetrics].
class VOverlayMenuPanelMetrics {
  const VOverlayMenuPanelMetrics({
    required this.shellHeight,
    required this.listViewportHeight,
    required this.needsScroll,
  });

  final double shellHeight;
  final double listViewportHeight;
  final bool needsScroll;
}
