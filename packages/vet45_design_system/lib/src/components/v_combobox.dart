import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_dropdown_filter.dart';
import '../foundation/v_overlay_menu_layout.dart';
import '../foundation/v_overlay_menu_shell.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_field.dart';
import '../primitives/v_icon_box.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'v_text_field.dart';
import 'v_text_field_affix.dart';
import 'v_text_field_focus_ring.dart';
import '../foundation/v_inspector_scope.dart';

/// Searchable single-select control (combobox).
///
/// Prefer [VField] + [VFieldLabel] for chrome.
/// Input chrome matches [VTextField] (borders + [VTextFieldFocusRing]).
/// Menu panel uses [VOverlayMenuShell] for pixel-perfect bottom shadow.
class VCombobox<T> extends StatefulWidget {
  /// Control height — matches [VTextField.controlHeight].
  static const double controlHeight = VTextField.controlHeight;

  /// Same inset as [VTextField.padding].
  static const EdgeInsets contentPadding = VTextField.padding;

  static const double _menuHeight = 300;

  const VCombobox({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled,
    this.hintText,
    @Deprecated('Use VField + VFieldLabel instead') this.label,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
  });

  final T? value;
  final List<DropdownMenuEntry<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool? enabled;
  final String? hintText;
  @Deprecated('Use VField + VFieldLabel instead')
  final String? label;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  @override
  State<VCombobox<T>> createState() => _VComboboxState<T>();
}

class _VComboboxState<T> extends State<VCombobox<T>> {
  late final FocusNode _focusNode;
  late final TextEditingController _textController;
  late final MenuController _menuController;
  List<DropdownMenuEntry<T>> _filteredEntries = [];
  bool _syncingFocusAndMenu = false;

  /// When true, [MenuController.close] must not unfocus the search field
  /// (e.g. filter became empty while typing).
  bool _keepFocusOnMenuClose = false;

  bool get _canInteract => VComponentScope.resolveEnabled(context, local: widget.enabled);

  bool get _hasFilteredEntries => _filteredEntries.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'VCombobox');
    _focusNode.addListener(_handleFocusChange);
    _textController = TextEditingController(text: _labelForValue(widget.value));
    _menuController = MenuController();
    _filteredEntries = widget.items;
  }

  @override
  void didUpdateWidget(covariant VCombobox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final label = _labelForValue(widget.value);
      if (_textController.text != label) {
        _textController.text = label;
      }
    }
    if (widget.items != oldWidget.items) {
      _filteredEntries = filterDropdownEntries(widget.items, _textController.text);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_syncingFocusAndMenu) return;

    if (_focusNode.hasFocus && _canInteract && !_menuController.isOpen) {
      _openMenu(requestFocus: false);
    }

    if (mounted) setState(() {});
  }

  void _syncMenuState() {
    if (mounted) setState(() {});
  }

  void _applyFilter(String query) {
    _filteredEntries = filterDropdownEntries(widget.items, query);
  }

  void _openMenu({bool requestFocus = true}) {
    setState(() {
      _applyFilter(_textController.text);
    });
    if (!_hasFilteredEntries) {
      _closeMenu(keepFocus: true);
      _syncMenuState();
      return;
    }
    if (!_menuController.isOpen) {
      _menuController.open();
    }
    if (requestFocus && !_focusNode.hasFocus) {
      _syncingFocusAndMenu = true;
      _focusNode.requestFocus();
      _syncingFocusAndMenu = false;
    }
    _syncMenuState();
  }

  void _closeMenu({required bool keepFocus}) {
    if (!_menuController.isOpen) {
      _syncMenuState();
      return;
    }
    _keepFocusOnMenuClose = keepFocus;
    _menuController.close();
  }

  void _handleMenuOpen() {
    if (!_hasFilteredEntries) {
      _closeMenu(keepFocus: true);
      return;
    }
    if (!_focusNode.hasFocus) {
      _syncingFocusAndMenu = true;
      _focusNode.requestFocus();
      _syncingFocusAndMenu = false;
    }
    _syncMenuState();
  }

  void _handleMenuClose() {
    final keepFocus = _keepFocusOnMenuClose;
    _keepFocusOnMenuClose = false;
    if (!keepFocus && _focusNode.hasFocus) {
      _syncingFocusAndMenu = true;
      _focusNode.unfocus();
      _syncingFocusAndMenu = false;
    }
    _syncMenuState();
  }

  String _labelForValue(T? value) {
    if (value == null) return '';
    for (final entry in widget.items) {
      if (entry.value == value) return entry.label;
    }
    return '';
  }

  OutlineInputBorder _outline(Color color, double width) {
    return VBorders.outlineInput(color, width: width);
  }

  void _toggleMenu(MenuController controller) {
    if (controller.isOpen) {
      controller.close();
    } else {
      _openMenu();
    }
  }

  void _selectEntry(DropdownMenuEntry<T> entry) {
    _textController.value = TextEditingValue(
      text: entry.label,
      selection: TextSelection.collapsed(offset: entry.label.length),
    );
    _menuController.close();
    setState(() {
      _filteredEntries = widget.items;
    });
    widget.onChanged?.call(entry.value);
  }

  Widget _buildTrailingIcon(
    BuildContext context,
    MenuController controller, {
    required bool isEnabled,
  }) {
    final open = controller.isOpen;
    final colors = context.vColors;

    return VIconBox(
      backgroundColor: Colors.transparent,
      icon: VIcons.arrowDropDown,
      size: VSpacing.space6,
      iconSize: 20,
      borderRadius: VRadius.input - VSpacing.space1 / 2,
      iconColor: open ? colors.textBrand : colors.textMuted,
      onTap: isEnabled ? () => _toggleMenu(controller) : null,
    );
  }

  InputDecoration _buildDecoration(
    BuildContext context,
    MenuController controller, {
    required bool isEnabled,
    required OutlineInputBorder restingBorder,
    required OutlineInputBorder focusBorder,
    required OutlineInputBorder disabledBorder,
    required Color iconColor,
    required Color hoverColor,
  }) {
    return InputDecoration(
      hintText: widget.hintText,
      suffixIcon: _buildTrailingIcon(
        context,
        controller,
        isEnabled: isEnabled,
      ),
      contentPadding: vTextFieldContentPadding(
        base: VCombobox.contentPadding,
        hasPrefix: false,
        hasSuffix: true,
      ),
    ).applyDefaults(
      InputDecorationTheme(
        filled: true,
        fillColor: isEnabled ? context.vColors.surface : context.vColors.surfaceAlt,
        hoverColor: Colors.transparent,
        contentPadding: vTextFieldContentPadding(
          base: VCombobox.contentPadding,
          hasPrefix: false,
          hasSuffix: true,
        ),
        hintStyle: VTypography.bodyDefault.copyWith(
          color: context.vColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
        border: restingBorder,
        enabledBorder: restingBorder,
        focusedBorder: focusBorder,
        disabledBorder: disabledBorder,
        constraints: const BoxConstraints(
          minHeight: VCombobox.controlHeight,
          maxHeight: VCombobox.controlHeight,
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems({
    required BuildContext context,
    required bool isEnabled,
    required double menuItemRadius,
  }) {
    final colors = context.vColors;
    final itemShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(menuItemRadius));

    return [
      for (final entry in _filteredEntries)
        SizedBox(
          height: VCombobox.controlHeight,
          width: double.infinity,
          child: ExcludeFocus(
            child: MenuItemButton(
              requestFocusOnHover: false,
              onPressed: entry.enabled && isEnabled ? () => _selectEntry(entry) : null,
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
              leadingIcon: entry.leadingIcon,
              trailingIcon: entry.trailingIcon,
              child:
                  entry.labelWidget ??
                  Text(
                    entry.label,
                    style: VTypography.bodyDefault.copyWith(color: colors.textPrimary),
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

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEnabled = _canInteract;
    final useDanger = widget.tone == VComponentTone.danger;
    final focused = isEnabled && _focusNode.hasFocus;
    final borderWidth = VBorders.widthFor(widget.emphasis);

    final restingBorderColor = useDanger
        ? colors.danger
        : switch (widget.tone) {
            VComponentTone.primary => colors.primary,
            VComponentTone.danger => colors.danger,
            _ => colors.borderDefault,
          };
    final focusBorderColor = useDanger ? colors.danger : colors.primary;
    final restingBorder = _outline(restingBorderColor, borderWidth);
    final focusBorder = _outline(focusBorderColor, borderWidth);
    final disabledBorder = _outline(colors.borderDefault, borderWidth);
    final trailingIconColor = isEnabled ? colors.textMuted : colors.borderStrong;

    // ignore: deprecated_member_use_from_same_package
    final legacyLabel = widget.label;

    final control = LayoutBuilder(
      builder: (context, constraints) {
        final menuRadius = VRadius.input;
        const menuPadding = VSpacing.space2;
        final menuWidth = constraints.maxWidth;
        const menuMaxHeight = VCombobox._menuHeight;
        const menuBoxShadow = VOverlayMenuShell.menuShadow;
        final menuMetrics = VOverlayMenuLayout.panelMetrics(
          itemCount: _filteredEntries.length,
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

        return VTextFieldFocusRing(
          focused: focused,
          danger: useDanger,
          child: MenuButtonTheme(
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
              menuChildren: !_hasFilteredEntries
                  ? const <Widget>[]
                  : [
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
                return TextField(
                  enabled: isEnabled,
                  focusNode: _focusNode,
                  controller: _textController,
                  style: VTypography.bodyDefault.copyWith(
                    color: isEnabled ? colors.textPrimary : colors.textMuted,
                  ),
                  onChanged: isEnabled
                      ? (text) {
                          setState(() {
                            _applyFilter(text);
                          });
                          if (!_hasFilteredEntries) {
                            _closeMenu(keepFocus: true);
                          } else if (!controller.isOpen) {
                            _openMenu(requestFocus: false);
                          } else {
                            _syncMenuState();
                          }
                        }
                      : null,
                  decoration: _buildDecoration(
                    context,
                    controller,
                    isEnabled: isEnabled,
                    restingBorder: restingBorder,
                    focusBorder: focusBorder,
                    disabledBorder: disabledBorder,
                    iconColor: trailingIconColor,
                    hoverColor: colors.surfaceHover,
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    final body = legacyLabel != null ? vFieldShell(control: control, label: legacyLabel) : control;

    return vInspectorHide(
      Semantics(
        label: widget.semanticLabel ?? legacyLabel ?? widget.hintText ?? 'Combobox',
        textField: true,
        enabled: isEnabled,
        child: body,
      ),
    );
  }
}
