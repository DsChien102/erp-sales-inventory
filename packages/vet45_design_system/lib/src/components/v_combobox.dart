/// Composition host for searchable single-select ([VCombobox]) and scope helpers.
library;

import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_dropdown_filter.dart';
import '../foundation/v_text_normalizer.dart';
import 'v_input.dart';

/// Control height fallback matching default [VTheme] comfortable density
/// (`VDensity.comfortable.controlHeightMedium` == 44).
///
/// Prefer [BuildContext.vDensity].controlHeightMedium when a [BuildContext]
/// is available (respects compact / comfortable).
const double kVComboboxControlHeight = 44;

/// Composition host for searchable single-select.
///
/// Place [VComboboxInput] and [VComboboxContent] under the same [VCombobox].
/// [VComboboxContent] must be built **before** [VComboboxInput] in the subtree
/// (e.g. Content then Input in a [Column] / [Stack]) so the overlay registers
/// in the same frame.
class VCombobox<T> extends StatefulWidget {
  /// Fallback control height — comfortable density medium (44).
  ///
  /// Runtime chrome (input lock, menu rows with context) uses
  /// `context.vDensity.controlHeightMedium`.
  static const double controlHeight = kVComboboxControlHeight;

  /// Same inset as [VInput.defaultPadding].
  static const EdgeInsets contentPadding = VInput.defaultPadding;

  /// Composition host (`child` = Content before Input).
  const VCombobox({
    super.key,
    required this.child,
    this.value,
    this.onChanged,
    this.enabled,
    this.open,
    this.onOpenChange,
    this.filter,
    this.displayTextForValue,
    this.invalid,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
  });

  final Widget child;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final bool? enabled;

  /// Controlled open; `null` = uncontrolled (focus / MenuController).
  final bool? open;
  final ValueChanged<bool>? onOpenChange;

  /// Override default [matchesComboboxSearch] on item [searchText].
  final bool Function(String query, String searchText, Object? value)? filter;

  /// Label shown in the input for [value] when not filtering.
  final String Function(T? value)? displayTextForValue;

  /// Local invalid override. Null inherits [VField.invalid].
  final bool? invalid;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  @override
  State<VCombobox<T>> createState() => _VComboboxState<T>();
}

/// Untyped façade used by composition descendants.
class VComboboxController extends ChangeNotifier {
  VComboboxController._(this._host);

  final _VComboboxHost _host;

  FocusNode get focusNode => _host.focusNode;
  TextEditingController get textController => _host.textController;
  MenuController get menuController => _host.menuController;
  Object get tapRegionGroupId => _host.tapRegionGroupId;

  String get query => _host.query;
  Widget? get overlayBody => _host.overlayBody;
  Widget? get overlayFooter => _host.overlayFooter;
  EdgeInsetsGeometry? get overlayPadding => _host.overlayPadding;
  bool get canInteract => _host.canInteract;
  bool get isOpen => _host.isOpen;
  bool? get invalid => _host.invalid;
  VComponentTone get tone => _host.tone;
  VComponentEmphasis get emphasis => _host.emphasis;
  Object? get selectedValue => _host.selectedValue;

  void registerOverlay({
    required Widget body,
    Widget? footer,
    EdgeInsetsGeometry? padding,
  }) {
    _host.registerOverlay(body: body, footer: footer, padding: padding);
  }

  /// Label shown in the input for [value] ([displayTextForValue], else `''`).
  String labelFor(Object? value) => _host.labelFor(value);

  bool matchesItem(Object? itemValue, {String? searchText}) {
    return _host.matchesItem(itemValue, searchText: searchText);
  }

  void requestOpen({bool requestFocus = true}) {
    _host.requestOpen(requestFocus: requestFocus);
  }

  void requestClose() => _host.requestClose();

  void toggleMenu() => _host.toggleMenu();

  /// Selects by [itemValue]; input text comes from [labelFor].
  void select(Object? itemValue) => _host.select(itemValue);

  void handleMenuOpen() => _host.handleMenuOpen();

  void handleMenuClose() => _host.handleMenuClose();

  /// Tap on [VComboboxInput]: open overlay if closed and reset filter to show
  /// all items without clearing [value] or the displayed input text.
  void handleInputTap() => _host.handleInputTap();

  void syncFromInputChange(String text) => _host.syncFromInputChange(text);

  void _notify() => notifyListeners();
}

abstract class _VComboboxHost {
  FocusNode get focusNode;
  TextEditingController get textController;
  MenuController get menuController;
  Object get tapRegionGroupId;
  String get query;
  Widget? get overlayBody;
  Widget? get overlayFooter;
  EdgeInsetsGeometry? get overlayPadding;
  bool get canInteract;
  bool get isOpen;
  bool? get invalid;
  VComponentTone get tone;
  VComponentEmphasis get emphasis;
  Object? get selectedValue;

  void registerOverlay({
    required Widget body,
    Widget? footer,
    EdgeInsetsGeometry? padding,
  });
  String labelFor(Object? value);
  bool matchesItem(Object? itemValue, {String? searchText});
  void requestOpen({bool requestFocus = true});
  void requestClose();
  void toggleMenu();
  void select(Object? itemValue);
  void handleMenuOpen();
  void handleMenuClose();
  void handleInputTap();
  void syncFromInputChange(String text);
}

class _VComboboxState<T> extends State<VCombobox<T>> implements _VComboboxHost {
  @override
  late final FocusNode focusNode;
  @override
  late final TextEditingController textController;
  @override
  late final MenuController menuController;
  @override
  final Object tapRegionGroupId = Object();
  late final VComboboxController controller;

  bool _syncingFocusAndMenu = false;
  bool _uncontrolledOpen = false;

  /// Skip restoring input text on the close that follows [select].
  bool _skipCloseTextRestore = false;
  String _query = '';
  String _normalizedQuery = '';
  Widget? _overlayBody;
  Widget? _overlayFooter;
  EdgeInsetsGeometry? _overlayPadding;

  @override
  String get query => _query;

  @override
  Widget? get overlayBody => _overlayBody;

  @override
  Widget? get overlayFooter => _overlayFooter;

  @override
  EdgeInsetsGeometry? get overlayPadding => _overlayPadding;

  @override
  bool get canInteract => VComponentScope.resolveEnabled(context, local: widget.enabled);

  @override
  bool get isOpen {
    final controlled = widget.open;
    if (controlled != null) return controlled;
    return _uncontrolledOpen || menuController.isOpen;
  }

  @override
  bool? get invalid => widget.invalid;

  @override
  VComponentTone get tone => widget.tone;

  @override
  VComponentEmphasis get emphasis => widget.emphasis;

  @override
  Object? get selectedValue => widget.value;

  @override
  void initState() {
    super.initState();
    controller = VComboboxController._(this);
    focusNode = FocusNode(debugLabel: 'VCombobox');
    focusNode.addListener(_handleFocusChange);
    textController = TextEditingController(text: labelFor(widget.value));
    menuController = MenuController();
    if (widget.open == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openMenu(requestFocus: false);
      });
    }
  }

  @override
  void didUpdateWidget(covariant VCombobox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_queryActive) {
      final label = labelFor(widget.value);
      if (textController.text != label) {
        textController.text = label;
      }
    }
    if (widget.open != oldWidget.open && widget.open != null) {
      if (widget.open! && !menuController.isOpen) {
        _openMenu(requestFocus: false);
      } else if (!widget.open! && menuController.isOpen) {
        menuController.close();
      }
    }
  }

  bool get _queryActive => _query.trim().isNotEmpty;

  @override
  void dispose() {
    focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    textController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  void registerOverlay({
    required Widget body,
    Widget? footer,
    EdgeInsetsGeometry? padding,
  }) {
    final unchanged =
        identical(_overlayBody, body) &&
        identical(_overlayFooter, footer) &&
        _overlayPadding == padding;
    _overlayBody = body;
    _overlayFooter = footer;
    _overlayPadding = padding;
    // Content registers during build. Closed overlay reads slots on next
    // open; only notify while open so MenuAnchor rebuilds the current panel.
    if (unchanged || !isOpen) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && isOpen) controller._notify();
    });
  }

  @override
  String labelFor(Object? value) {
    return widget.displayTextForValue?.call(value as T?) ?? '';
  }

  @override
  bool matchesItem(Object? itemValue, {String? searchText}) {
    final haystack = _itemHaystack(itemValue, searchText);
    final custom = widget.filter;
    if (custom != null) {
      return custom(_query, haystack, itemValue);
    }
    return matchesNormalizedComboboxSearch(_normalizedQuery, haystack);
  }

  String _itemHaystack(Object? itemValue, String? searchText) {
    final hasSearch = searchText != null && searchText.isNotEmpty;
    if (!hasSearch) return labelFor(itemValue);
    final label = labelFor(itemValue);
    if (label.isEmpty || label == searchText) return searchText;
    return '$searchText $label';
  }

  void _replaceQuery(String query) {
    _query = query;
    _normalizedQuery = VTextNormalizer.normalizeForSearch(query);
  }

  void setQuery(String query) {
    if (query == _query) return;
    _replaceQuery(query);
    controller._notify();
  }

  @override
  void requestOpen({bool requestFocus = true}) {
    if (widget.open != null) {
      widget.onOpenChange?.call(true);
      if (!menuController.isOpen) {
        _openMenu(requestFocus: requestFocus);
      } else if (requestFocus && !focusNode.hasFocus) {
        _syncingFocusAndMenu = true;
        focusNode.requestFocus();
        _syncingFocusAndMenu = false;
      }
      return;
    }
    _openMenu(requestFocus: requestFocus);
  }

  @override
  void requestClose() {
    if (widget.open != null) {
      widget.onOpenChange?.call(false);
    }
    if (menuController.isOpen) {
      menuController.close();
    }
  }

  @override
  void toggleMenu() {
    if (isOpen) {
      requestClose();
    } else {
      requestOpen();
    }
  }

  @override
  void select(Object? itemValue) {
    final label = labelFor(itemValue);
    textController.value = TextEditingValue(
      text: label,
      selection: TextSelection.collapsed(offset: label.length),
    );
    _replaceQuery('');
    controller._notify();
    _skipCloseTextRestore = true;
    widget.onChanged?.call(itemValue as T?);
    requestClose();
    // Intentional dismiss after pick — not via [handleMenuClose], so parent
    // scroll closing the overlay does not steal focus/IME.
    if (focusNode.hasFocus) {
      _syncingFocusAndMenu = true;
      focusNode.unfocus();
      _syncingFocusAndMenu = false;
    }
    if (mounted) setState(() {});
  }

  void _handleFocusChange() {
    if (_syncingFocusAndMenu) return;

    if (focusNode.hasFocus && canInteract && !isOpen) {
      requestOpen(requestFocus: false);
    } else if (!focusNode.hasFocus) {
      // Restore label on true blur. Menu may already be closed (scroll) while
      // focused — keep typed filter until then.
      _restoreClosedText();
    }
  }

  void _restoreClosedText() {
    _replaceQuery('');
    if (_skipCloseTextRestore) {
      _skipCloseTextRestore = false;
      return;
    }
    final label = labelFor(widget.value);
    if (textController.text != label) {
      textController.text = label;
    }
  }

  void _openMenu({bool requestFocus = true, bool resetFilter = true}) {
    setState(() {
      _uncontrolledOpen = true;
      // Opening from focus/tap/chevron shows the full list. Typing opens with
      // [resetFilter]: false so [syncFromInputChange] keeps the typed query.
      if (resetFilter) {
        _replaceQuery('');
      }
    });
    controller._notify();
    if (!menuController.isOpen) {
      menuController.open();
    }
    if (requestFocus && !focusNode.hasFocus) {
      _syncingFocusAndMenu = true;
      focusNode.requestFocus();
      _syncingFocusAndMenu = false;
    }
  }

  @override
  void handleInputTap() {
    if (!canInteract) return;

    // Keep displayed text / value; select all so the next keystroke replaces
    // the label while filtering.
    final text = textController.text;
    if (text.isNotEmpty) {
      textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: text.length,
      );
    }

    if (!isOpen) {
      requestOpen(requestFocus: false);
      return;
    }

    if (_query.isNotEmpty) {
      _replaceQuery('');
      controller._notify();
    }
  }

  @override
  void handleMenuOpen() {
    _uncontrolledOpen = true;
    if (!focusNode.hasFocus) {
      _syncingFocusAndMenu = true;
      focusNode.requestFocus();
      _syncingFocusAndMenu = false;
    }
    if (mounted) setState(() {});
    widget.onOpenChange?.call(true);
  }

  @override
  void handleMenuClose() {
    _uncontrolledOpen = false;
    // Ancestor scroll may close the overlay while the field stays focused.
    // Only restore the committed label when already unfocused; otherwise keep
    // the typed query so filter/IME survive the drag.
    if (!focusNode.hasFocus) {
      _restoreClosedText();
    }
    controller._notify();
    if (mounted) setState(() {});
    widget.onOpenChange?.call(false);
  }

  @override
  void syncFromInputChange(String text) {
    setQuery(text);
    if (!isOpen) {
      _openMenu(requestFocus: false, resetFilter: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _VComboboxScope(
      controller: controller,
      child: widget.child,
    );

    final label = widget.semanticLabel;
    if (label == null) return body;

    return Semantics(
      label: label,
      textField: true,
      enabled: canInteract,
      child: body,
    );
  }
}

class _VComboboxScope extends InheritedWidget {
  const _VComboboxScope({
    required this.controller,
    required super.child,
  });

  final VComboboxController controller;

  static VComboboxController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_VComboboxScope>();
    if (scope == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('VCombobox descendant must be used within a VCombobox.'),
        ErrorDescription(
          'Place VComboboxInput / VComboboxContent / VComboboxList / '
          'VComboboxItem under the same VCombobox. Build Content before '
          'Input in the subtree so the overlay registers in the same frame.',
        ),
      ]);
    }
    return scope.controller;
  }

  @override
  bool updateShouldNotify(covariant _VComboboxScope oldWidget) {
    final a = controller;
    final b = oldWidget.controller;
    return a != b ||
        a.query != b.query ||
        a.selectedValue != b.selectedValue ||
        a.isOpen != b.isOpen ||
        a.canInteract != b.canInteract;
  }
}

/// Looks up the nearest [VCombobox] controller.
VComboboxController vComboboxOf(BuildContext context) {
  return _VComboboxScope.of(context);
}

/// Re-provides [controller] for overlay subtrees (e.g. [MenuAnchor.menuChildren]).
Widget vComboboxProvideScope({
  required VComboboxController controller,
  required Widget child,
}) {
  return _VComboboxScope(controller: controller, child: child);
}
