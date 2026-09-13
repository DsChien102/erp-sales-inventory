import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../foundation/v_overlay_menu_shell.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import 'v_combobox.dart';

/// Overlay body for [VCombobox] — registers into [MenuAnchor.menuChildren].
///
/// Does not paint in-place ([SizedBox.shrink]). Build this **before**
/// [VComboboxInput] under the same root.
///
/// Typical child: [VComboboxList] or list + [footer].
///
/// Registers [child]/[footer] on the root each build so an open overlay can
/// refresh when items change (slot widgets, not a stale builder closure).
class VComboboxContent extends StatelessWidget {
  /// Default inset around list + footer inside the overlay panel.
  static const EdgeInsets defaultPadding = EdgeInsets.all(VSpacing.space2);

  const VComboboxContent({
    super.key,
    required this.child,
    this.footer,
    this.padding,
  });

  /// Overlay main body (usually [VComboboxList]).
  final Widget child;

  /// Optional action row below the list (create-new, etc.).
  final Widget? footer;

  /// Overlay panel inset. `null` = [defaultPadding].
  final EdgeInsetsGeometry? padding;

  /// Builds the menu panel chrome used by [VComboboxInput]'s overlay.
  static Widget buildPanel({
    required BuildContext context,
    required double menuWidth,
    required Object tapRegionGroupId,
    required Widget body,
    Widget? footer,
    EdgeInsetsGeometry? padding,
  }) {
    final colors = context.vColors;
    final menuRadius = VRadius.input;
    const menuBoxShadow = VOverlayMenuShell.menuShadow;

    final content = footer == null
        ? body
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              body,
              footer,
            ],
          );

    final panel = VOverlayMenuShell.panel(
      borderRadius: BorderRadius.circular(menuRadius),
      borderSide: VBorders.side(colors.borderStrong),
      padding: padding ?? defaultPadding,
      boxShadow: menuBoxShadow,
      child: content,
    );

    return TapRegion(
      groupId: tapRegionGroupId,
      child: SizedBox(
        width: menuWidth,
        child: panel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final root = vComboboxOf(context);
    root.registerOverlay(
      body: child,
      footer: footer,
      padding: padding ?? defaultPadding,
    );
    return const SizedBox.shrink();
  }
}
