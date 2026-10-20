/// Composition host for searchable single-select ([VCombobox]) and scope helpers.
library;

import 'package:flutter/material.dart';

import '../foundation/v_component_scope.dart';
import '../foundation/v_dropdown_filter.dart';
import '../foundation/v_text_normalizer.dart';
import 'v_input.dart';

/// Composition host for searchable single-select.
///
/// Place [VComboboxInput] and [VComboboxContent] under the same [VCombobox].
/// [VComboboxContent] must be built **before** [VComboboxInput] in the subtree
/// (e.g. Content then Input in a [Column] / [Stack]) so the overlay registers
/// in the same frame.
class VCombobox<T> extends StatefulWidget {
  /// Fallback control height — comfortable density medium (44).
  ///
  /// Prefer `context.vDensity.controlHeightMedium` when a context is available.
  static const double controlHeight = 44;

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
    this.displayTextForValue,
    this.invalid,
    this.semanticLabel,
  });

  final Widget child;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final bool? enabled;

  /// Controlled open; `null` = uncontrolled (focus / MenuController).
  final bool? open;
  final ValueChanged<bool>? onOpenChange;

  /// Label shown in the input for [value] when not filtering.
  final String Function(T? value)? displayTextForValue;

  /// Local invalid override. Null inherits [VField.invalid].
  final bool? invalid;
  final String? semanticLabel;

  @override
  State<VCombobox<T>> createState() => _VComboboxState<T>();
}

/// Untyped façade used by composition descendants.
///
/// Apps need only [query] and [select]; the rest wires Input / Content / List.
class VComboboxController extends ChangeNotifier {
  VComboboxController._(this._host);

  final _VComboboxState<dynamic> _host;

  FocusNode get focusNode => _host.focusNode;
  TextEditingController get textController => _host.textController;
  MenuController get menuController => _host.menuController;
  Object get tapRegionGroupId => _host.tapRegionGroupId;

  String get query => _host.query;
  Widget? get overlayBody => _host.overlayBody;
  Widget? get overlayFooter => _host.overlayFooter;
  bool get canInteract => _host.canInteract;
  bool get isOpen => _host.isOpen;
  bool? get invalid => _host.widget.invalid;
  Object? get selectedValue => _host.widget.value;

  void registerOverlay({required Widget body, Widget? footer}) {
    _host.registerOverlay(body: body, footer: footer);
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

class _VComboboxState<T> extends State<VCombobox<T>> {
  final focusNode = FocusNode(debugLabel: 'VCombobox');
  final menuController = MenuController();
  final tapRegionGroupId = Object();
  late final TextEditingController textController;
  late final VComboboxController controller;

  bool _syncingFocusAndMenu = false;
  bool _uncontrolledOpen = false;

  /// Skip restoring input text on the close that follows [select].
  bool _skipCloseTextRestore = false;
  String _query = '';
  String _normalizedQuery = '';
  Widget? overlayBody;
  Widget? overlayFooter;

  String get query => _query;

  bool get canInteract =>
      VComponentScope.resolveEnabled(context, local: widget.enabled);

  bool get isOpen =>
      widget.open ?? (_uncontrolledOpen || menuController.isOpen);

  @override
  void initState() {
    super.initState();
    controller = VComboboxController._(this);
    focusNode.addListener(_handleFocusChange);
    textController = TextEditingController(text: labelFor(widget.value));
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
    if (widget.value != oldWidget.value && _query.trim().isEmpty) {
      final label = labelFor(widget.value);
      if (textController.text != label) {
        textController.text = label;
      }
    }
    final open = widget.open;
    if (open != null && open != oldWidget.open) {
      if (open && !menuController.isOpen) {
        _openMenu(requestFocus: false);
      } else if (!open && menuController.isOpen) {
        menuController.close();
      }
    }
  }

  @override
  void dispose() {
    focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    textController.dispose();
    controller.dispose();
    super.dispose();
  }

  void registerOverlay({required Widget body, Widget? footer}) {
    final unchanged =
        identical(overlayBody, body) && identical(overlayFooter, footer);
    overlayBody = body;
    overlayFooter = footer;
    // Content registers during build. Closed overlay reads slots on next
    // open; only notify while open so MenuAnchor rebuilds the current panel.
    if (unchanged || !isOpen) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && isOpen) controller._notify();
    });
  }

  String labelFor(Object? value) {
    return widget.displayTextForValue?.call(value as T?) ?? '';
  }

  bool matchesItem(Object? itemValue, {String? searchText}) {
    final label = labelFor(itemValue);
    final extra = searchText ?? '';
    final haystack = extra.isEmpty
        ? label
        : (label.isEmpty || label == extra ? extra : '$extra $label');
    return matchesNormalizedComboboxSearch(_normalizedQuery, haystack);
  }

  void _replaceQuery(String query) {
    _query = query;
    _normalizedQuery = VTextNormalizer.normalizeForSearch(query);
  }

  /// Runs [action] without letting the focus listener re-open / close the menu.
  void _withFocusSync(VoidCallback action) {
    _syncingFocusAndMenu = true;
    action();
    _syncingFocusAndMenu = false;
  }

  void requestOpen({bool requestFocus = true}) {
    if (widget.open == null) {
      _openMenu(requestFocus: requestFocus);
      return;
    }
    widget.onOpenChange?.call(true);
    if (!menuController.isOpen) {
      _openMenu(requestFocus: requestFocus);
    } else if (requestFocus && !focusNode.hasFocus) {
      _withFocusSync(focusNode.requestFocus);
    }
  }

  void requestClose() {
    if (widget.open != null) widget.onOpenChange?.call(false);
    if (menuController.isOpen) menuController.close();
  }

  void toggleMenu() => isOpen ? requestClose() : requestOpen();

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
    if (focusNode.hasFocus) _withFocusSync(focusNode.unfocus);
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
      if (resetFilter) _replaceQuery('');
    });
    controller._notify();
    if (!menuController.isOpen) menuController.open();
    if (requestFocus && !focusNode.hasFocus) {
      _withFocusSync(focusNode.requestFocus);
    }
  }

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
    } else if (_query.isNotEmpty) {
      _replaceQuery('');
      controller._notify();
    }
  }

  void handleMenuOpen() {
    _uncontrolledOpen = true;
    if (!focusNode.hasFocus) _withFocusSync(focusNode.requestFocus);
    if (mounted) setState(() {});
    widget.onOpenChange?.call(true);
  }

  void handleMenuClose() {
    _uncontrolledOpen = false;
    // Ancestor scroll may close the overlay while the field stays focused.
    // Only restore the committed label when already unfocused; otherwise keep
    // the typed query so filter/IME survive the drag.
    if (!focusNode.hasFocus) _restoreClosedText();
    controller._notify();
    if (mounted) setState(() {});
    widget.onOpenChange?.call(false);
  }

  void syncFromInputChange(String text) {
    if (text != _query) {
      _replaceQuery(text);
      controller._notify();
    }
    if (!isOpen) _openMenu(requestFocus: false, resetFilter: false);
  }

  @override
  Widget build(BuildContext context) {
    final body = _VComboboxScope(controller: controller, child: widget.child);

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
  bool updateShouldNotify(covariant _VComboboxScope oldWidget) =>
      controller != oldWidget.controller;
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
