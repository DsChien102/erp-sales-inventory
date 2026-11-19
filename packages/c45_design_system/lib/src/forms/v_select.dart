import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../components/v_text_field_focus_ring.dart';
import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../foundation/v_overlay_menu_layout.dart';
import '../foundation/v_overlay_menu_shell.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_field.dart';
import '../primitives/v_icon_box.dart';
import '../primitives/v_text.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'validators/v_select_validator.dart';

/// Non-searchable form select.
///
/// Prefer [VField] + [VFieldLabel] / [VFieldDescription] / [VFieldError] for chrome.
/// Overlay menu matches [VCombobox] (MenuAnchor + [VOverlayMenuShell]).
class VSelect<T> extends StatefulWidget {
  static const double _menuHeight = 300;

  const VSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    @Deprecated('Use VField + VFieldLabel instead') this.label,
    this.hintText = 'Chọn...',
    @Deprecated('Use VFieldDescription instead') this.helperText,
    @Deprecated(
      'Use VField(invalid: true) + VFieldError for message; keep error chrome via tone/domain',
    )
    this.errorText,
    this.enabled,
    @Deprecated('Use VFieldLabel(..., isRequired: true) instead') this.isRequired = false,
    this.requiredMessage = VSelectValidator.defaultRequiredMessage,
    this.invalid,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  @Deprecated('Use VField + VFieldLabel instead')
  final String? label;
  final String? hintText;
  @Deprecated('Use VFieldDescription instead')
  final String? helperText;
  @Deprecated(
    'Use VField(invalid: true) + VFieldError for message; keep error chrome via tone/domain',
  )
  final String? errorText;
  final bool? enabled;
  @Deprecated('Use VFieldLabel(..., isRequired: true) instead')
  final bool isRequired;
  final String requiredMessage;

  /// Local invalid override. Null inherits [VField.invalid].
  final bool? invalid;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  @override
  State<VSelect<T>> createState() => _VSelectState<T>();
}

class _VSelectState<T> extends State<VSelect<T>> {
  late final FocusNode _focusNode;
  late final MenuController _menuController;
  String? _internalError;

  // ignore: deprecated_member_use_from_same_package
  String? get _effectiveError => widget.errorText ?? _internalError;

  bool _triggerHighlighted = false;

  bool get _canInteract => VComponentScope.resolveEnabled(context, local: widget.enabled);

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
        // ignore: deprecated_member_use_from_same_package
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
    final controlHeight = context.vDensity.controlHeightMedium;
    final itemShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(menuItemRadius));

    return [
      for (final item in widget.items)
        SizedBox(
          height: controlHeight,
          width: double.infinity,
          child: ExcludeFocus(
            child: MenuItemButton(
              requestFocusOnHover: false,
              onPressed: isEnabled && item.enabled ? () => _selectItem(item) : null,
              style: ButtonStyle(
                fixedSize: WidgetStatePropertyAll(
                  Size(double.infinity, controlHeight),
                ),
                minimumSize: WidgetStatePropertyAll(
                  Size(double.infinity, controlHeight),
                ),
                maximumSize: WidgetStatePropertyAll(
                  Size(double.infinity, controlHeight),
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
          height: context.vDensity.controlHeightMedium,
          decoration: BoxDecoration(
            color: _triggerHighlighted
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
                      color: selected != null
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
                            color: colors.textMuted,
                          ),
                  ),
                ),
              ),
              VIconBox(
                backgroundColor: Colors.transparent,
                icon: VIcons.arrowDropDown,
                borderRadius: VRadius.input - VSpacing.space1 / 2,
                iconColor: open
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
    final isInvalid =
        VField.resolveInvalid(context, local: widget.invalid) || hasError;
    final useDanger = isInvalid || widget.tone == VComponentTone.danger;
    final focused = isEnabled && (_focusNode.hasFocus || _menuController.isOpen);
    // Neutral/primary: no focus chrome. Danger: keep danger border + focus ring.
    final showDangerFocusChrome = useDanger && focused;
    final borderWidth = VBorders.widthFor(widget.emphasis);
    final borderColor = useDanger
        ? colors.danger
        : switch (widget.tone) {
            VComponentTone.primary => colors.primary,
            VComponentTone.danger => colors.danger,
            _ => isEnabled ? colors.borderInput : colors.borderDefault,
          };

    // ignore: deprecated_member_use_from_same_package
    final legacyLabel = widget.label;
    // ignore: deprecated_member_use_from_same_package
    final legacyHelper = widget.helperText;
    // ignore: deprecated_member_use_from_same_package
    final legacyRequired = widget.isRequired;

    final control = VTextFieldFocusRing(
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
              itemHeight: context.vDensity.controlHeightMedium,
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
                      borderSide: VBorders.side(colors.borderInput),
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
    );

    final useShell = legacyLabel != null ||
        legacyHelper != null ||
        _effectiveError != null ||
        legacyRequired;
    final body = useShell
        ? vFieldShell(
            control: control,
            label: legacyLabel,
            isRequired: legacyRequired,
            helperText: legacyHelper,
            errorText: _effectiveError,
          )
        : control;

    return vInspectorHide(
      Semantics(
        label: widget.semanticLabel ?? legacyLabel ?? widget.hintText ?? 'Chọn',
        button: true,
        enabled: isEnabled,
        child: vDisabledOpacity(enabled: isEnabled, child: body),
      ),
    );
  }
}
