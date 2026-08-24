import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../components/v_combobox.dart';
import '../components/v_text_field.dart';
import '../components/v_text_field_focus_ring.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../foundation/v_overlay_menu_layout.dart';
import '../foundation/v_overlay_menu_shell.dart';
import '../foundations/icons/v_icons.dart';
import '../primitives/v_icon_box.dart';
import '../primitives/v_text.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'validators/v_select_validator.dart';

/// Non-searchable form select with label / required / helper / error chrome.
///
/// Overlay menu matches [VCombobox] (MenuAnchor + [VOverlayMenuShell]).
class VSelect<T> extends StatefulWidget {
  static const double _menuHeight = 300;

  const VSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hintText = 'Chọn...',
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.isRequired = false,
    this.requiredMessage = VSelectValidator.defaultRequiredMessage,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.state = VComponentState.enabled,
    this.semanticLabel,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool isRequired;
  final String requiredMessage;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState state;
  final String? semanticLabel;

  @override
  State<VSelect<T>> createState() => _VSelectState<T>();
}

class _VSelectState<T> extends State<VSelect<T>> {
  late final FocusNode _focusNode;
  late final MenuController _menuController;
  String? _internalError;

  String? get _effectiveError => widget.errorText ?? _internalError;

  bool _triggerHighlighted = false;

  bool get _canInteract => widget.enabled && widget.state != VComponentState.disabled;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'VSelect');
    _focusNode.addListener(_handleFocusChange);
    _menuController = MenuController();
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void _syncMenuState() {
    if (mounted) setState(() {});
  }

  void _handleChanged(T? newValue) {
    widget.onChanged?.call(newValue);
    setState(() {
      _internalError = VSelectValidator.validate(
        newValue,
        isRequired: widget.isRequired,
        requiredMessage: widget.requiredMessage,
      );
    });
  }

  void _openMenu() {
    if (!_canInteract) return;
    if (!_menuController.isOpen) {
      _menuController.open();
    }
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    _syncMenuState();
  }

  void _handleMenuOpen() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    _syncMenuState();
  }

  void _handleMenuClose() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    _syncMenuState();
  }

  void _toggleMenu() {
    if (_menuController.isOpen) {
      _menuController.close();
    } else {
      _openMenu();
    }
  }

  void _selectItem(DropdownMenuItem<T> item) {
    _menuController.close();
    _handleChanged(item.value);
  }

  DropdownMenuItem<T>? _selectedItem() {
    for (final item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  List<Widget> _buildMenuItems({
    required BuildContext context,
    required bool isEnabled,
    required double menuItemRadius,
  }) {
    final colors = context.vColors;
    final itemShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(menuItemRadius));

    return [
      for (final item in widget.items)
        SizedBox(
          height: VCombobox.controlHeight,
          width: double.infinity,
          child: ExcludeFocus(
            child: MenuItemButton(
              requestFocusOnHover: false,
              onPressed: isEnabled && item.enabled ? () => _selectItem(item) : null,
              style: ButtonStyle(
                fixedSize: const WidgetStatePropertyAll(
                  Size(double.infinity, VCombobox.controlHeight),
                ),
                minimumSize: const WidgetStatePropertyAll(
                  Size(double.infinity, VCombobox.controlHeight),
                ),
                maximumSize: const WidgetStatePropertyAll(
                  Size(double.infinity, VCombobox.controlHeight),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: VSpacing.space2),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: WidgetStatePropertyAll(itemShape),
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed) ||
                      states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused)) {
                    return colors.surfaceAlt;
                  }
                  return Colors.transparent;
                }),
              ),
              child: DefaultTextStyle(
                style: VTypography.bodyDefault.copyWith(color: colors.textPrimary),
                child: vInspectorShow(item.child),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildMenuPanelBody({
    required BuildContext context,
    required bool isEnabled,
    required double menuItemRadius,
    required VOverlayMenuPanelMetrics metrics,
  }) {
    final menuItems = _buildMenuItems(
      context: context,
      isEnabled: isEnabled,
      menuItemRadius: menuItemRadius,
    );

    if (!metrics.needsScroll) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: menuItems,
      );
    }

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad,
        },
      ),
      child: ListView(
        primary: false,
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: menuItems,
      ),
    );
  }

  Widget _buildTrigger({
    required BuildContext context,
    required bool isEnabled,
    required Color borderColor,
    required double borderWidth,
  }) {
    final colors = context.vColors;
    final selected = _selectedItem();
    final open = _menuController.isOpen;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: isEnabled ? _toggleMenu : null,
        onHighlightChanged: isEnabled
            ? (highlighted) {
                if (_triggerHighlighted == highlighted) return;
                setState(() => _triggerHighlighted = highlighted);
              }
            : null,
        borderRadius: BorderRadius.circular(VRadius.input),
        child: Ink(
          height: VTextField.controlHeight,
          decoration: BoxDecoration(
            color: !isEnabled
                ? colors.surfaceAlt
                : _triggerHighlighted
                ? colors.surfacePressed
                : colors.surface,
            borderRadius: BorderRadius.circular(VRadius.input),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  // Match menu label inset: shell padding + MenuItemButton padding.
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space4,
                  ),
                  child: DefaultTextStyle(
                    style: VTypography.bodyDefault.copyWith(
                      color: !isEnabled
                          ? colors.textMuted
                          : selected != null
                          ? colors.textPrimary
                          : colors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: selected != null
                        ? vInspectorShow(selected.child)
                        : VText(
                            widget.hintText ?? 'Chọn...',
                            color: isEnabled ? colors.textMuted : colors.textSecondary,
                          ),
                  ),
                ),
              ),
              VIconBox(
                backgroundColor: Colors.transparent,
                icon: VIcons.arrowDropDown,
                borderRadius: VRadius.input - VSpacing.space1 / 2,
                iconColor: !isEnabled
                    ? colors.borderStrong
                    : open
                    ? colors.textBrand
                    : colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEnabled = _canInteract;
    final hasError = _effectiveError != null;
    final useDanger =
        hasError || widget.tone == VComponentTone.danger || widget.state == VComponentState.error;
    final focused = isEnabled && (_focusNode.hasFocus || _menuController.isOpen);
    // Neutral/primary: no focus chrome. Danger: keep danger border + focus ring.
    final showDangerFocusChrome = useDanger && focused;
    final borderWidth = VBorders.widthFor(widget.emphasis);
    final borderColor = useDanger
        ? colors.danger
        : switch (widget.tone) {
            VComponentTone.primary => colors.primary,
            VComponentTone.danger => colors.danger,
            _ => isEnabled ? colors.borderStrong : colors.borderDefault,
          };

    return vInspectorHide(
      Semantics(
        label: widget.semanticLabel ?? widget.label ?? widget.hintText ?? 'Select',
        button: true,
        enabled: isEnabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null) ...[
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: widget.label!,
                      style: VTypography.headingH4.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    if (widget.isRequired)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: colors.danger),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: VSpacing.space2),
            ],
            VTextFieldFocusRing(
              focused: showDangerFocusChrome,
              danger: useDanger,
              child: Focus(
                focusNode: _focusNode,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final menuRadius = VRadius.input;
                    const menuPadding = VSpacing.space2;
                    final menuWidth = constraints.maxWidth;
                    const menuMaxHeight = VSelect._menuHeight;
                    const menuBoxShadow = VOverlayMenuShell.menuShadow;
                    final menuMetrics = VOverlayMenuLayout.panelMetrics(
                      itemCount: widget.items.length,
                      menuMaxHeight: menuMaxHeight,
                      itemHeight: VCombobox.controlHeight,
                      menuPadding: menuPadding,
                    );
                    final transparentMenuStyle = MenuStyle(
                      elevation: const WidgetStatePropertyAll(0),
                      backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
                      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
                      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                      minimumSize: WidgetStatePropertyAll(Size(menuWidth, 0)),
                      maximumSize: WidgetStatePropertyAll(Size(menuWidth, menuMaxHeight)),
                    );

                    return MenuButtonTheme(
                      data: const MenuButtonThemeData(),
                      child: MenuAnchor(
                        controller: _menuController,
                        childFocusNode: _focusNode,
                        clipBehavior: Clip.none,
                        style: transparentMenuStyle,
                        alignmentOffset: VOverlayMenuLayout.alignmentOffset,
                        reservedPadding: VOverlayMenuLayout.menuReservedPadding(menuBoxShadow),
                        crossAxisUnconstrained: false,
                        onOpen: _handleMenuOpen,
                        onClose: _handleMenuClose,
                        menuChildren: [
                          SizedBox(
                            width: menuWidth,
                            height: menuMetrics.shellHeight,
                            child: VOverlayMenuShell.panel(
                              borderRadius: BorderRadius.circular(menuRadius),
                              borderSide: VBorders.side(colors.borderStrong),
                              padding: const EdgeInsets.all(menuPadding),
                              boxShadow: menuBoxShadow,
                              child: menuMetrics.needsScroll
                                  ? SizedBox(
                                      height: menuMetrics.listViewportHeight,
                                      child: _buildMenuPanelBody(
                                        context: context,
                                        isEnabled: isEnabled,
                                        menuItemRadius: menuRadius,
                                        metrics: menuMetrics,
                                      ),
                                    )
                                  : _buildMenuPanelBody(
                                      context: context,
                                      isEnabled: isEnabled,
                                      menuItemRadius: menuRadius - menuPadding / 2,
                                      metrics: menuMetrics,
                                    ),
                            ),
                          ),
                        ],
                        builder: (context, controller, child) {
                          return _buildTrigger(
                            context: context,
                            isEnabled: isEnabled,
                            borderColor: borderColor,
                            borderWidth: borderWidth,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_effectiveError != null) ...[
              const SizedBox(height: VSpacing.space1),
              Text(
                _effectiveError!,
                style: VTypography.bodySmall.copyWith(color: colors.danger),
              ),
            ] else if (widget.helperText != null) ...[
              const SizedBox(height: VSpacing.space1),
              Text(
                widget.helperText!,
                style: VTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
