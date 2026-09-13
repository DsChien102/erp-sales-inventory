import 'package:flutter/material.dart';

import '../tokens/v_spacing.dart';
import 'v_combobox.dart';

/// Optional action strip under [VComboboxList] (e.g. create-new).
///
/// Same slot pattern as [ListenableBuilder]: rebuild via [builder], keep an
/// immutable subtree in [child] when it should not rebuild with query/state.
class VComboboxFooter extends StatelessWidget {
  const VComboboxFooter({
    super.key,
    required this.builder,
    this.child,
    this.padding = const EdgeInsets.only(top: VSpacing.space1),
  });

  /// Builds the footer.
  ///
  /// [child] is the optional immutable [VComboboxFooter.child].
  /// [root] is the nearest [VComboboxController] when under [VCombobox].
  final Widget Function(BuildContext context, Widget? child, VComboboxController root) builder;

  /// Optional immutable subtree passed into [builder] (icons, static chrome).
  final Widget? child;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final root = vComboboxOf(context);
    return Padding(
      padding: padding,
      child: builder(context, child, root),
    );
  }
}
