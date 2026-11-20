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
  const VComboboxContent({super.key, required this.child, this.footer});

  /// Overlay main body (usually [VComboboxList]).
  final Widget child;

  /// Optional action row below the list (create-new, etc.). Built inside the
  /// overlay, so [vComboboxOf] resolves there.
  final Widget? footer;

  /// Builds the menu panel chrome used by [VComboboxInput]'s overlay.
  static Widget buildPanel({
    required BuildContext context,
    required double menuWidth,
    required Object tapRegionGroupId,
    required Widget body,
    Widget? footer,
  }) {
    final panel = VOverlayMenuShell.panel(
      borderRadius: BorderRadius.circular(VRadius.input),
      borderSide: VBorders.side(context.vColors.borderStrong),
      padding: const EdgeInsets.all(VSpacing.space2),
      boxShadow: VOverlayMenuShell.menuShadow,
      child: footer == null
          ? body
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                body,
                const SizedBox(height: VSpacing.space1),
                footer,
              ],
            ),
    );

    return TapRegion(
      groupId: tapRegionGroupId,
      child: SizedBox(width: menuWidth, child: panel),
    );
  }

  @override
  Widget build(BuildContext context) {
    vComboboxOf(context).registerOverlay(body: child, footer: footer);
    return const SizedBox.shrink();
  }
}
