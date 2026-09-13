import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_overlay_menu_layout.dart';
import '../foundation/v_overlay_menu_shell.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_field.dart';
import '../primitives/v_icon_box.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'v_combobox_content.dart';
import 'v_combobox.dart';
import 'v_input.dart';
import 'v_text_field_focus_ring.dart';

/// Searchable trigger for [VCombobox] (`MenuAnchor` + [VInput]).
///
/// Must sit under [VCombobox]. Prefer building [VComboboxContent] **before**
/// this widget in the subtree so [menuChildren] are registered same-frame.
///
/// Outside dismiss uses [VInput.onTapUpOutside] (completed tap + [kTouchSlop]),
/// not pointer-down unfocus, so dragging a parent list keeps focus / IME.
class VComboboxInput extends StatefulWidget {
  const VComboboxInput({
    super.key,
    this.hintText,
  });

  final String? hintText;

  @override
  State<VComboboxInput> createState() => _VComboboxInputState();
}

class _VComboboxInputState extends State<VComboboxInput> {
  Offset? _outsidePointerDown;

  void _handleTapOutside(PointerDownEvent event) {
    _outsidePointerDown = event.position;
  }

  void _handleTapUpOutside(PointerUpEvent event) {
    final down = _outsidePointerDown;
    _outsidePointerDown = null;
    if (down != null && (event.position - down).distance > kTouchSlop) {
      return;
    }

    final root = vComboboxOf(context);
    root.requestClose();
    if (root.focusNode.hasFocus) {
      root.focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final root = vComboboxOf(context);
    final colors = context.vColors;
    final isEnabled = root.canInteract;
    final isInvalid = VField.resolveInvalid(context, local: root.invalid);
    final useDanger =
        isInvalid || root.tone == VComponentTone.danger;

    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = constraints.maxWidth;
        const menuStyleMaxHeight = 400.0;
        final transparentMenuStyle = MenuStyle(
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          minimumSize: WidgetStatePropertyAll(Size(menuWidth, 0)),
          maximumSize: WidgetStatePropertyAll(
            Size(menuWidth, menuStyleMaxHeight),
          ),
        );

        final menu = MenuButtonTheme(
          data: const MenuButtonThemeData(),
          child: MenuAnchor(
            controller: root.menuController,
            childFocusNode: root.focusNode,
            clipBehavior: Clip.none,
            style: transparentMenuStyle,
            alignmentOffset: VOverlayMenuLayout.alignmentOffset,
            reservedPadding: VOverlayMenuLayout.menuReservedPadding(
              VOverlayMenuShell.menuShadow,
            ),
            crossAxisUnconstrained: false,
            onOpen: root.handleMenuOpen,
            onClose: root.handleMenuClose,
            menuChildren: [
              ListenableBuilder(
                listenable: root,
                builder: (context, _) {
                  final body = root.overlayBody;
                  if (body == null) {
                    return const SizedBox.shrink();
                  }
                  return vComboboxProvideScope(
                    controller: root,
                    child: VComboboxContent.buildPanel(
                      context: context,
                      menuWidth: menuWidth,
                      tapRegionGroupId: root.tapRegionGroupId,
                      body: body,
                      footer: root.overlayFooter,
                      padding: root.overlayPadding,
                    ),
                  );
                },
              ),
            ],
            builder: (context, controller, child) {
              return VInput(
                enabled: isEnabled,
                focusNode: root.focusNode,
                controller: root.textController,
                hintText: widget.hintText,
                tone: root.tone,
                emphasis: root.emphasis,
                invalid: isInvalid,
                groupId: root.tapRegionGroupId,
                textStyle: VTypography.bodyDefault.copyWith(
                  color: colors.textPrimary,
                ),
                suffix: _TrailingChevron(
                  open: controller.isOpen,
                  enabled: isEnabled,
                  onTap: isEnabled ? root.toggleMenu : null,
                ),
                onChanged: isEnabled ? root.syncFromInputChange : null,
                onTap: isEnabled ? root.handleInputTap : null,
                onTapOutside: _handleTapOutside,
                onTapUpOutside: _handleTapUpOutside,
              );
            },
          ),
        );

        // Listen to [FocusNode] only around the ring. Rebuilding [MenuAnchor]
        // on focus would drop overlay state and recreate menu chrome.
        return ListenableBuilder(
          listenable: root.focusNode,
          child: menu,
          builder: (context, child) {
            return VTextFieldFocusRing(
              focused: isEnabled && root.focusNode.hasFocus,
              danger: useDanger,
              child: child!,
            );
          },
        );
      },
    );
  }
}

class _TrailingChevron extends StatelessWidget {
  const _TrailingChevron({
    required this.open,
    required this.enabled,
    required this.onTap,
  });

  final bool open;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VIconBox(
      backgroundColor: Colors.transparent,
      icon: VIcons.arrowDropDown,
      size: VSpacing.space6,
      iconSize: 20,
      borderRadius: VRadius.input - VSpacing.space1 / 2,
      iconColor: open ? colors.textBrand : colors.textMuted,
      onTap: enabled ? onTap : null,
    );
  }
}
