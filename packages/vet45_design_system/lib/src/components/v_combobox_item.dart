import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'v_combobox.dart';

/// Selectable row under [VComboboxList].
///
/// Selection is by [value] only. Input label comes from
/// [VCombobox.displayTextForValue].
///
/// Optional [searchText] extends the filter haystack; when omitted, filter uses
/// [VComboboxController.labelFor]. Never parses [child].
///
/// Row height follows [child] layout with a minimum tap target of
/// ambient [VDensity.controlHeightMedium].
class VComboboxItem<T> extends StatelessWidget {
  const VComboboxItem({
    super.key,
    required this.value,
    required this.child,
    this.searchText,
    this.enabled = true,
    this.onSelect,
  });

  final T value;

  /// Optional filter corpus. When null/empty, uses [VCombobox.displayTextForValue].
  /// When set, combined with the display label for matching.
  final String? searchText;

  /// Custom row UI.
  final Widget child;

  final bool enabled;

  /// Override default root [VComboboxController.select].
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final root = vComboboxOf(context);
    final colors = context.vColors;
    final isEnabled = enabled && root.canInteract;

    final controlHeight = context.vDensity.controlHeightMedium;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: controlHeight,
        minWidth: double.infinity,
      ),
      child: ExcludeFocus(
        child: MenuItemButton(
          requestFocusOnHover: false,
          onPressed: isEnabled
              ? () {
                  if (onSelect != null) {
                    onSelect!();
                  } else {
                    root.select(value);
                  }
                }
              : null,
          style: ButtonStyle(
            minimumSize: _itemMinSize,
            maximumSize: _itemMaxSize,
            padding: _itemPadding,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.standard,
            shape: _itemShape,
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return colors.surfaceAlt;
              }
              return Colors.transparent;
            }),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: DefaultTextStyle(
              style: VTypography.bodyDefault.copyWith(color: colors.textPrimary),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

const _itemMinSize = WidgetStatePropertyAll(Size(0, 0));
const _itemMaxSize = WidgetStatePropertyAll(Size(double.infinity, double.infinity));
const _itemPadding = WidgetStatePropertyAll(
  EdgeInsets.symmetric(
    horizontal: VSpacing.space2,
    vertical: VSpacing.space1,
  ),
);
final _itemShape = WidgetStatePropertyAll(
  RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(VRadius.input - VSpacing.space2 / 2),
  ),
);
