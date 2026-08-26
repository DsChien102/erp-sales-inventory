import 'package:flutter/material.dart';

import 'v_component_contracts.dart';

/// Ambient contract bag for V* components. Soft inherit; missing scope is OK.
///
/// Exposes [tone] and [enabled]. Later fields (emphasis, …) can be added here
/// without a new [InheritedWidget] type.
class VComponentScope extends InheritedWidget {
  const VComponentScope({
    super.key,
    this.tone,
    this.enabled,
    required super.child,
  });

  final VComponentTone? tone;

  /// Soft ambient enabled. Null means “no opinion” (children use fallback).
  final bool? enabled;

  static VComponentScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<VComponentScope>();
  }

  /// [local] → nearest [VComponentScope.tone] → null.
  static VComponentTone? resolveTone(
    BuildContext context, {
    VComponentTone? local,
  }) {
    if (local != null) return local;
    return maybeOf(context)?.tone;
  }

  /// [local] → nearest [VComponentScope.enabled] → [fallback].
  static bool resolveEnabled(
    BuildContext context, {
    bool? local,
    bool fallback = true,
  }) {
    if (local != null) return local;
    return maybeOf(context)?.enabled ?? fallback;
  }

  @override
  bool updateShouldNotify(covariant VComponentScope oldWidget) {
    return tone != oldWidget.tone || enabled != oldWidget.enabled;
  }
}

/// Wrap when a shell wants to cascade ambient contract values.
Widget vProvideComponentScope({
  Key? key,
  VComponentTone? tone,
  bool? enabled,
  required Widget child,
}) {
  return VComponentScope(
    key: key,
    tone: tone,
    enabled: enabled,
    child: child,
  );
}

/// Looks up a required ancestor [InheritedWidget]; throws [FlutterError] if missing.
T requireAncestor<T extends InheritedWidget>(
  BuildContext context, {
  required String widgetName,
  required String ancestorName,
}) {
  final ancestor = context.dependOnInheritedWidgetOfExactType<T>();
  if (ancestor == null) {
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('$widgetName must be used within a $ancestorName.'),
      ErrorDescription(
        'Place $widgetName inside $ancestorName so composition stays consistent.',
      ),
    ]);
  }
  return ancestor;
}
