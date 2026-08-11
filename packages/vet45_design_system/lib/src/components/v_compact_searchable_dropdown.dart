import 'package:flutter/material.dart';

import '../foundation/v_dropdown_filter.dart';
import '../foundation/v_overlay_menu_layout.dart';
import '../foundation/v_route_overlay_guard.dart';
import '../foundation/v_component_contracts.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';

/// Compact (40px) searchable dropdown for dense ERP forms.
///
/// Handles route-safe overlays, collapsed ellipsis display, optional external
/// trailing arrow (opens menu without focusing the field), and keyboard-aware
/// menu height.
class VCompactSearchableDropdown<T> extends StatefulWidget {
  const VCompactSearchableDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
    this.trailingMode = VCompactDropdownTrailingMode.builtin,
    this.inputKey,
    this.trailingKey,
    this.menuController,
    this.stickyActionsReserve = 72,
    this.collapsedWhenUnfocused = true,
    this.menuHeight = VOverlayMenuLayout.defaultMenuHeight,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.state,
    this.semanticLabel,
  });

  final T? value;
  final List<DropdownMenuEntry<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final bool enabled;
  final VCompactDropdownTrailingMode trailingMode;
  final Key? inputKey;
  final Key? trailingKey;
  final MenuController? menuController;
  final double stickyActionsReserve;
  final bool collapsedWhenUnfocused;
  final double menuHeight;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState? state;
  final String? semanticLabel;

  VComponentState _resolveState() {
    if (state != null) return state!;
    return enabled ? VComponentState.enabled : VComponentState.disabled;
  }

  static const double controlHeight = 40;
  static const double trailingIconWidth = 40;

  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );

  static const BoxConstraints trailingIconConstraints = BoxConstraints.tightFor(
    width: trailingIconWidth,
    height: controlHeight,
  );

  @override
  State<VCompactSearchableDropdown<T>> createState() => _VCompactSearchableDropdownState<T>();
}

enum VCompactDropdownTrailingMode {
  builtin,
  external,
}

class _VCompactSearchableDropdownState<T> extends State<VCompactSearchableDropdown<T>>
    with WidgetsBindingObserver {
  late final MenuController _menuController;
  late final FocusNode _focusNode;
  late final bool _ownsMenuController;
  ModalRoute<dynamic>? _watchedRoute;
  bool _forceEditing = false;
  bool _openMenuOnly = false;
  bool _isDismissing = false;
  bool _isFullyReady = false;
  bool _wasShowingCollapsed = true;

  /// Geometry-clamped menu height — updated post-frame only (never in build).
  double? _clampedMenuHeight;

  bool get _hasValue => widget.value != null && widget.value.toString().isNotEmpty;

  bool get _showCollapsedField =>
      widget.collapsedWhenUnfocused && !_forceEditing && !_openMenuOnly && !_focusNode.hasFocus;

  bool get _useExternalTrailing => widget.trailingMode == VCompactDropdownTrailingMode.external;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsMenuController = widget.menuController == null;
    _menuController = widget.menuController ?? MenuController();
    _focusNode = FocusNode(debugLabel: 'VCompactSearchableDropdown');
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (identical(route, _watchedRoute)) return;
    _watchedRoute?.animation?.removeListener(_onRouteMotionChanged);
    _watchedRoute = route;
    route?.animation?.addListener(_onRouteMotionChanged);
  }

  void _onRouteMotionChanged() {
    if (!mounted) return;
    final route = _watchedRoute;
    if (route == null || !route.isActive) {
      _dismissOverlays();
      return;
    }
    if (!VRouteOverlayGuard.isLayoutReady(context)) {
      _dismissOverlays();
    }
    setState(() {});
  }

  void _dismissOverlays() {
    _isDismissing = true;
    _focusNode.unfocus();
    if (_menuController.isOpen) {
      _menuController.close();
    }
    _forceEditing = false;
    _openMenuOnly = false;
    _isDismissing = false;
  }

  void _onFocusChange() {
    if (!mounted || _isDismissing) return;
    if (_focusNode.hasFocus) {
      _openMenuOnly = false;
    } else {
      _forceEditing = false;
      _openMenuOnly = false;
    }
    setState(() {});
    if (!_focusNode.hasFocus) return;
    _scheduleMenuFit();
  }

  @override
  void didChangeMetrics() {
    if (!_focusNode.hasFocus && !_menuController.isOpen) return;
    if (!mounted || !VRouteOverlayGuard.isLayoutReady(context)) return;
    _scheduleMenuFit();
  }

  void _scheduleMenuFit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !VRouteOverlayGuard.isLayoutReady(context)) return;
      if (!_focusNode.hasFocus && !_menuController.isOpen) return;
      VOverlayMenuLayout.ensureOpensDownward(
        context,
        stickyActionsReserve: widget.stickyActionsReserve,
      );
      if (!mounted) return;
      final next = VOverlayMenuLayout.resolvedMenuHeight(
        context,
        preferredHeight: widget.menuHeight,
        stickyActionsReserve: widget.stickyActionsReserve,
      );
      if (_clampedMenuHeight == next) return;
      setState(() => _clampedMenuHeight = next);
    });
  }

  double get _menuHeightForBuild => _clampedMenuHeight ?? widget.menuHeight;

  Future<void> _startEditing() async {
    if (!widget.enabled || !VRouteOverlayGuard.isLayoutReady(context)) return;
    setState(() {
      _forceEditing = true;
      _openMenuOnly = false;
    });
    await VOverlayMenuLayout.ensureOpensDownward(
      context,
      stickyActionsReserve: widget.stickyActionsReserve,
      anticipateKeyboard: true,
    );
    if (!mounted || !VRouteOverlayGuard.isLayoutReady(context)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !VRouteOverlayGuard.isLayoutReady(context)) return;
      _focusNode.requestFocus();
    });
  }

  Future<void> _openMenuFromTrailing() async {
    if (!widget.enabled || !VRouteOverlayGuard.isLayoutReady(context)) return;
    _focusNode.unfocus();
    if (_showCollapsedField) {
      setState(() {
        _forceEditing = true;
        _openMenuOnly = true;
      });
    }
    await VOverlayMenuLayout.ensureOpensDownward(
      context,
      stickyActionsReserve: widget.stickyActionsReserve,
    );
    if (!mounted || !VRouteOverlayGuard.isLayoutReady(context)) return;
    final next = VOverlayMenuLayout.resolvedMenuHeight(
      context,
      preferredHeight: widget.menuHeight,
      stickyActionsReserve: widget.stickyActionsReserve,
    );
    if (_clampedMenuHeight != next) {
      setState(() => _clampedMenuHeight = next);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _menuController.isOpen) return;
      if (!VRouteOverlayGuard.isLayoutReady(context)) return;
      _menuController.open();
    });
  }

  @override
  void deactivate() {
    _dismissOverlays();
    super.deactivate();
  }

  @override
  void dispose() {
    _watchedRoute?.animation?.removeListener(_onRouteMotionChanged);
    WidgetsBinding.instance.removeObserver(this);
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    if (_ownsMenuController) {
      // MenuController has no dispose — owned instance is GC'd with State.
    }
    super.dispose();
  }

  TextStyle _textStyle(Color color) {
    return VTypography.bodySmall.copyWith(
      color: color,
      fontSize: 14,
      height: 1.2,
    );
  }

  BoxDecoration _decoration(BuildContext context) {
    final colors = context.vColors;
    final isEnabled = widget._resolveState() == VComponentState.enabled;
    final borderColor = switch (widget.tone) {
      VComponentTone.primary => colors.primary,
      VComponentTone.danger => colors.danger,
      _ => isEnabled ? colors.borderStrong : colors.borderDefault,
    };
    final borderWidth = VBorders.widthFor(widget.emphasis);

    return BoxDecoration(
      color: isEnabled ? colors.surface : colors.surfaceAlt,
      borderRadius: BorderRadius.circular(VRadius.input),
      border: VBorders.all(borderColor, width: borderWidth),
    );
  }

  Widget _buildBaseField({required Widget child, VoidCallback? onTap}) {
    final box = DecoratedBox(decoration: _decoration(context), child: child);
    final control = SizedBox(
      height: VCompactSearchableDropdown.controlHeight,
      width: double.infinity,
      child: box,
    );
    if (onTap == null) return control;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.input),
        child: control,
      ),
    );
  }

  Widget _buildFrozenField() {
    final colors = context.vColors;
    final display = _hasValue ? widget.value.toString() : null;

    return _buildBaseField(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
              child: Text(
                display ?? widget.hintText ?? 'Chọn...',
                style: _textStyle(
                  widget.enabled ? colors.textMuted : colors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _buildTrailingSlot(
            isOpen: false,
            interactive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedField() {
    final colors = context.vColors;
    final display = _hasValue ? widget.value.toString() : null;

    return _buildBaseField(
      onTap: _startEditing,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
              child: Text(
                display ?? widget.hintText ?? 'Chọn...',
                style: _textStyle(
                  widget.enabled
                      ? (display != null ? colors.textPrimary : colors.textMuted)
                      : colors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _buildTrailingSlot(
            isOpen: _menuController.isOpen,
            interactive: _useExternalTrailing,
          ),
        ],
      ),
    );
  }

  /// Same 40×40 trailing slot for builtin + external so province/ward icons align.
  Widget _buildTrailingSlot({
    required bool isOpen,
    required bool interactive,
  }) {
    final colors = context.vColors;
    final icon = Icon(
      isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
      key: interactive ? null : widget.trailingKey,
      size: 18,
      color: widget.enabled ? colors.textSecondary : colors.textMuted,
    );

    if (!interactive) {
      return SizedBox(
        width: VCompactSearchableDropdown.trailingIconWidth,
        height: VCompactSearchableDropdown.controlHeight,
        child: Center(child: icon),
      );
    }

    return IconButton(
      key: widget.trailingKey,
      onPressed: widget.enabled ? _openMenuFromTrailing : null,
      padding: EdgeInsets.zero,
      constraints: VCompactSearchableDropdown.trailingIconConstraints,
      icon: icon,
    );
  }

  Widget _buildTrailingButton({required bool isOpen}) {
    return _buildTrailingSlot(isOpen: isOpen, interactive: true);
  }

  double _resolvedWidth(BoxConstraints constraints) {
    if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
      return constraints.maxWidth;
    }
    return MediaQuery.sizeOf(context).width;
  }

  Widget _buildDropdownMenu({
    required double menuWidth,
    required double resolvedMenuHeight,
  }) {
    final colors = context.vColors;

    InputBorder border(Color color) {
      if (_useExternalTrailing) return InputBorder.none;
      return VBorders.outlineInput(color);
    }

    // Prefer [expandedInsets] over [width]: DropdownMenu otherwise parents every
    // entry into `_DropdownMenuBody` just to measure width (hundreds of wards),
    // which is expensive and fragile inside ListView/accordion layouts.
    return DropdownMenu<T>(
      key: widget.inputKey,
      expandedInsets: EdgeInsets.zero,
      enabled: widget.enabled,
      initialSelection: widget.value,
      hintText: widget.hintText,
      focusNode: _focusNode,
      menuController: _menuController,
      enableSearch: true,
      enableFilter: true,
      filterCallback: filterDropdownEntries,
      requestFocusOnTap: !_openMenuOnly,
      showTrailingIcon: !_useExternalTrailing,
      trailingIcon: Icon(
        Icons.keyboard_arrow_down,
        size: 18,
        color: widget.enabled ? colors.textSecondary : colors.textMuted,
      ),
      selectedTrailingIcon: Icon(
        Icons.keyboard_arrow_up,
        size: 18,
        color: widget.enabled ? colors.textSecondary : colors.textMuted,
      ),
      alignmentOffset: VOverlayMenuLayout.alignmentOffset,
      menuHeight: resolvedMenuHeight,
      textStyle: _textStyle(widget.enabled ? colors.textPrimary : colors.textMuted),
      menuStyle: MenuStyle(
        alignment: VOverlayMenuLayout.alignment,
        minimumSize: WidgetStatePropertyAll(Size(menuWidth, 0)),
        maximumSize: WidgetStatePropertyAll(Size(menuWidth, resolvedMenuHeight)),
        backgroundColor: WidgetStatePropertyAll(colors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VRadius.input),
            side: VBorders.side(colors.borderDefault),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: _useExternalTrailing
            ? Colors.transparent
            : (widget.enabled ? colors.surface : colors.surfaceAlt),
        contentPadding: VCompactSearchableDropdown.contentPadding,
        hintStyle: _textStyle(colors.textMuted),
        border: border(colors.borderStrong),
        enabledBorder: border(colors.borderStrong),
        disabledBorder: border(colors.borderDefault),
        focusedBorder: border(colors.primary),
        constraints: const BoxConstraints(
          minHeight: VCompactSearchableDropdown.controlHeight,
          maxHeight: VCompactSearchableDropdown.controlHeight,
        ),
        suffixIconConstraints: VCompactSearchableDropdown.trailingIconConstraints,
      ),
      onSelected: (value) {
        widget.onChanged?.call(value);
        _focusNode.unfocus();
        setState(() {
          _forceEditing = false;
          _openMenuOnly = false;
        });
      },
      dropdownMenuEntries: widget.items,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isFullyReady && VRouteOverlayGuard.isLayoutReady(context)) {
      _isFullyReady = true;
    }

    final isEnabled = widget._resolveState() == VComponentState.enabled;

    Widget buildContent(Widget child) {
      return Semantics(
        label: widget.semanticLabel ?? widget.hintText ?? 'Compact searchable dropdown',
        textField: true,
        enabled: isEnabled,
        child: child,
      );
    }

    if (!_isFullyReady) {
      return buildContent(_buildFrozenField());
    }

    // Subscribe to keyboard insets so we rebuild when the keyboard opens;
    // actual menu-height clamp happens post-frame in [_scheduleMenuFit].
    MediaQuery.viewInsetsOf(context);
    final resolvedMenuHeight = _menuHeightForBuild;

    final bool showCollapsed;
    if (VRouteOverlayGuard.isLayoutReady(context)) {
      showCollapsed = _showCollapsedField;
      _wasShowingCollapsed = showCollapsed;
    } else {
      showCollapsed = _wasShowingCollapsed;
    }

    if (showCollapsed) {
      return buildContent(_buildCollapsedField());
    }

    return buildContent(
      SizedBox(
        height: VCompactSearchableDropdown.controlHeight,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fieldWidth = _resolvedWidth(constraints);
            final menuWidth = _useExternalTrailing
                ? fieldWidth - VCompactSearchableDropdown.trailingIconWidth
                : fieldWidth;

            final menu = _buildDropdownMenu(
              menuWidth: menuWidth,
              resolvedMenuHeight: resolvedMenuHeight,
            );

            if (!_useExternalTrailing) {
              return menu;
            }

            return DecoratedBox(
              decoration: _decoration(context),
              child: Row(
                children: [
                  Expanded(child: menu),
                  _buildTrailingButton(isOpen: _menuController.isOpen),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
