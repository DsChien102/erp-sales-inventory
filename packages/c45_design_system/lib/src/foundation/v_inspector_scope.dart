import 'package:flutter/widgets.dart';

/// Hides [child] from Flutter DevTools widget inspector (implementation chrome).
Widget vInspectorHide(Widget child) => DisableWidgetInspectorScope(child: child);

/// Re-enables inspector for a slot under [vInspectorHide] (caller-provided content).
Widget vInspectorShow(Widget child) => EnableWidgetInspectorScope(child: child);
