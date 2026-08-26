import 'package:flutter/material.dart';

import 'v_component_contracts.dart';

/// Ambient contract bag for V* components. Soft inherit; missing scope is OK.
///
/// Slice 1 exposes [tone] only. Later fields (emphasis, state, …) can be added
/// here without a new [InheritedWidget] type.
class VComponentScope extends InheritedWidget {
  const VComponentScope({
    super.key,
    this.tone,
    required super.child,
  });

  final VComponentTone? tone;

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

  @override
  bool updateShouldNotify(covariant VComponentScope oldWidget) {
    return tone != oldWidget.tone;
  }
}

/// Wrap when a shell wants to cascade ambient contract values.
Widget vProvideComponentScope({
  Key? key,
  VComponentTone? tone,
  required Widget child,
}) {
  return VComponentScope(
    key: key,
    tone: tone,
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
