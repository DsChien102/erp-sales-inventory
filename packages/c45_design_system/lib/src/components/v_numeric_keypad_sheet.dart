import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_text.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'v_button.dart';
import 'v_input.dart';
import 'v_numeric_keypad_grid.dart';

export 'v_numeric_keypad_grid.dart' show VNumericKeypadMode;

/// Bottom numeric input overlay for high-frequency transactional entry.
///
/// Preserve the previous value until [onSave]. Do not use for phone numbers,
/// tax codes, or free-form identifiers.
class VNumericKeypadSheet extends StatefulWidget {
  const VNumericKeypadSheet({
    super.key,
    required this.mode,
    required this.onCancel,
    required this.onSave,
    this.title,
    this.unitLabel,
    this.initialRaw = '',
    this.allowDecimal = true,
    this.maxIntegerDigits = 12,
    this.tone = VComponentTone.primary,
    this.emphasis = VComponentEmphasis.medium,
    this.enabled,
    this.semanticLabel,
  });

  final VNumericKeypadMode mode;
  final VoidCallback onCancel;
  final ValueChanged<String> onSave;
  final String? title;
  final String? unitLabel;
  final String initialRaw;
  final bool allowDecimal;
  final int maxIntegerDigits;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final bool? enabled;
  final String? semanticLabel;

  @override
  State<VNumericKeypadSheet> createState() => _VNumericKeypadSheetState();
}

class _VNumericKeypadSheetState extends State<VNumericKeypadSheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final GlobalKey _displayKey = GlobalKey();

  /// Taps inside the sheet share this id with [VInput] so they are not
  /// treated as [TextField.onTapOutside].
  final Object _tapRegionGroupId = Object();

  bool get _isEnabled => VComponentScope.resolveEnabled(context, local: widget.enabled);

  bool get _isMoney => widget.mode == VNumericKeypadMode.money;

  /// Digits-only value for [onSave] (money strips thousand separators).
  String get _raw => _isMoney ? _digitsOnly(_controller.text) : _controller.text;

  @override
  void initState() {
    super.initState();
    final initial = _sanitizeInitial(widget.initialRaw);
    _controller = TextEditingController(
      text: _isMoney ? _formatMoney(initial) : initial,
    );
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      // Avoid platform select-all-on-focus; caret stays at end for append.
      final len = _controller.text.length;
      _controller.selection = TextSelection.collapsed(offset: len);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _sanitizeInitial(String value) => switch (widget.mode) {
    VNumericKeypadMode.money => value.replaceAll(RegExp(r'[^0-9]'), ''),
    VNumericKeypadMode.quantity => value.replaceAll(RegExp(r'[^0-9.]'), ''),
  };

  static String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  /// Formats digit string with `,` thousand separators (e.g. `1234` → `1,234`).
  static String _formatMoney(String digits) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buf.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  /// Number of digits in [formatted] before index [index].
  static int _digitOffsetAt(String formatted, int index) {
    var count = 0;
    final end = index.clamp(0, formatted.length);
    for (var i = 0; i < end; i++) {
      final c = formatted.codeUnitAt(i);
      if (c >= 0x30 && c <= 0x39) count++;
    }
    return count;
  }

  /// Caret index in [formatted] after [digitOffset] digits.
  static int _formattedOffsetForDigit(String formatted, int digitOffset) {
    if (digitOffset <= 0) return 0;
    var count = 0;
    for (var i = 0; i < formatted.length; i++) {
      final c = formatted.codeUnitAt(i);
      if (c >= 0x30 && c <= 0x39) {
        count++;
        if (count == digitOffset) return i + 1;
      }
    }
    return formatted.length;
  }

  String get _resolvedTitle =>
      widget.title ??
      switch (widget.mode) {
        VNumericKeypadMode.money => 'Nhập số tiền',
        VNumericKeypadMode.quantity => 'Nhập số lượng',
      };

  String get _resolvedUnit =>
      widget.unitLabel ??
      switch (widget.mode) {
        VNumericKeypadMode.money => 'Đơn vị: VND',
        VNumericKeypadMode.quantity => 'Đơn vị',
      };

  bool get _decimalAllowed => widget.mode == VNumericKeypadMode.quantity && widget.allowDecimal;

  List<TextInputFormatter> get _displayFormatters => [
        TextInputFormatter.withFunction(_formatHardwareEdit),
      ];

  /// Normalize HW keyboard edits (and keypad commits through EditableText) to
  /// the same money/quantity rules as the custom keypad.
  TextEditingValue _formatHardwareEdit(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_isMoney) {
      var digits = _digitsOnly(newValue.text);
      if (digits.length > widget.maxIntegerDigits) {
        // Prefer keeping a prefix that matches typing at end; otherwise clamp.
        final oldDigits = _digitsOnly(oldValue.text);
        if (digits.startsWith(oldDigits) && oldDigits.length == widget.maxIntegerDigits) {
          digits = oldDigits;
        } else {
          digits = digits.substring(0, widget.maxIntegerDigits);
        }
      }
      final formatted = _formatMoney(digits);
      final caretDigits = _digitOffsetAt(
        newValue.text,
        newValue.selection.extentOffset,
      ).clamp(0, digits.length);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: _formattedOffsetForDigit(formatted, caretDigits),
        ),
      );
    }

    final text = newValue.text;
    if (RegExp(r'[^0-9.]').hasMatch(text)) return oldValue;
    if ('.'.allMatches(text).length > 1) return oldValue;
    if (!_decimalAllowed && text.contains('.')) return oldValue;
    if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length == 2 && parts[1].length > 3) return oldValue;
      if (parts[0].length > widget.maxIntegerDigits) return oldValue;
    } else {
      final collapsed = text.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      if (collapsed.length > widget.maxIntegerDigits) return oldValue;
    }
    return newValue;
  }

  ({int start, int end}) _selectionBounds() {
    final text = _controller.text;
    final sel = _controller.selection;
    if (!sel.isValid) {
      return (start: text.length, end: text.length);
    }
    final start = sel.start.clamp(0, text.length);
    final end = sel.end.clamp(0, text.length);
    return (start: start, end: end);
  }

  /// Prefer IME-style updates so [EditableText] restarts the caret blink timer.
  EditableTextState? _editableTextState() {
    final root = _displayKey.currentContext;
    if (root == null) return null;
    EditableTextState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is EditableTextState) {
        found = element.state as EditableTextState;
        return;
      }
      element.visitChildren(visit);
    }

    root.visitChildElements(visit);
    return found;
  }

  void _commit(String next, int caret) {
    final value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: caret.clamp(0, next.length)),
    );
    final editable = _editableTextState();
    if (editable != null) {
      editable.userUpdateTextEditingValue(value, SelectionChangedCause.keyboard);
    } else {
      _controller.value = value;
    }
  }

  void _commitMoney(String nextRaw, int caretDigitOffset) {
    final formatted = _formatMoney(nextRaw);
    _commit(formatted, _formattedOffsetForDigit(formatted, caretDigitOffset));
  }

  String? _insertMoney(String before, String after, String key) {
    final limitOk = key == '000'
        ? before.length + after.length + 3 <= widget.maxIntegerDigits
        : before.length + after.length + key.length <= widget.maxIntegerDigits;
    if (!limitOk) return null;
    return '$before$key$after';
  }

  String? _insertQuantity(String before, String after, String key) {
    switch (key) {
      case '.':
        if (!_decimalAllowed) return null;
        final proposed = before.isEmpty && after.isEmpty ? '0.' : '$before.$after';
        if ('.'.allMatches(proposed).length > 1) return null;
        return proposed;
      case _:
        final proposed = '$before$key$after';
        if (RegExp(r'[^0-9.]').hasMatch(proposed)) return null;
        if ('.'.allMatches(proposed).length > 1) return null;
        if (proposed.contains('.')) {
          final parts = proposed.split('.');
          if (parts.length == 2 && parts[1].length > 3) return null;
          if (parts[0].length > widget.maxIntegerDigits) return null;
          return proposed;
        }
        // Caret at end: preserve prior leading-zero collapse.
        if (after.isEmpty) {
          final digits = before.replaceFirst(RegExp(r'^0+(?=\d)'), '');
          if (digits.length >= widget.maxIntegerDigits) return null;
          final next = digits.isEmpty && key == '0' ? '0' : '${digits == '0' ? '' : digits}$key';
          return next;
        }
        if (proposed.replaceFirst(RegExp(r'^0+(?=\d)'), '').length > widget.maxIntegerDigits) {
          return null;
        }
        return proposed;
    }
  }

  void _append(String key) {
    if (!_isEnabled) return;
    HapticFeedback.selectionClick();
    final text = _controller.text;
    final bounds = _selectionBounds();

    if (_isMoney) {
      final raw = _digitsOnly(text);
      final digStart = _digitOffsetAt(text, bounds.start);
      final digEnd = _digitOffsetAt(text, bounds.end);
      final before = raw.substring(0, digStart);
      final after = raw.substring(digEnd);
      final nextRaw = _insertMoney(before, after, key);
      if (nextRaw == null) return;
      final caretDigits = after.isEmpty ? nextRaw.length : before.length + key.length;
      _commitMoney(nextRaw, caretDigits);
      return;
    }

    final before = text.substring(0, bounds.start);
    final after = text.substring(bounds.end);
    final next = _insertQuantity(before, after, key);
    if (next == null) return;
    final caret = after.isEmpty ? next.length : before.length + key.length;
    _commit(next, caret);
  }

  void _backspace() {
    if (!_isEnabled) return;
    final text = _controller.text;
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();

    final bounds = _selectionBounds();

    if (_isMoney) {
      final raw = _digitsOnly(text);
      if (raw.isEmpty) return;
      final digStart = _digitOffsetAt(text, bounds.start);
      final digEnd = _digitOffsetAt(text, bounds.end);
      if (digStart != digEnd) {
        final nextRaw = raw.substring(0, digStart) + raw.substring(digEnd);
        _commitMoney(nextRaw, digStart);
        return;
      }
      if (digStart == 0) return;
      final nextRaw = raw.substring(0, digStart - 1) + raw.substring(digStart);
      _commitMoney(nextRaw, digStart - 1);
      return;
    }

    if (bounds.start != bounds.end) {
      final next = text.substring(0, bounds.start) + text.substring(bounds.end);
      _commit(next, bounds.start);
      return;
    }
    if (bounds.start == 0) return;
    final next = text.substring(0, bounds.start - 1) + text.substring(bounds.start);
    _commit(next, bounds.start - 1);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return vInspectorHide(
      Semantics(
        label: widget.semanticLabel ?? _resolvedTitle,
        child: TapRegion(
          groupId: _tapRegionGroupId,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(VRadius.sheet)),
            ),
            padding: EdgeInsets.fromLTRB(
              VSpacing.space4,
              VSpacing.space3,
              VSpacing.space4,
              VSpacing.space4 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.borderDefault,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const VGap.sm(),
                VText(_resolvedTitle, variant: VTextVariant.headingH3),
                VText(
                  _resolvedUnit,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.sm(),
                VInput(
                  key: _displayKey,
                  controller: _controller,
                  focusNode: _focusNode,
                  groupId: _tapRegionGroupId,
                  // Editable for HW keyboard; TextInputType.none hides soft IME.
                  readOnly: false,
                  showCursor: true,
                  autofocus: true,
                  keyboardType: TextInputType.none,
                  inputFormatters: _displayFormatters,
                  textAlign: TextAlign.center,
                  textStyle: VTypography.headingH1.copyWith(color: colors.textPrimary),
                  suffix: widget.mode == VNumericKeypadMode.money
                      ? VText(
                          'đ',
                          variant: VTextVariant.headingH2,
                          color: colors.textMuted,
                        )
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.space4,
                    vertical: VSpacing.space5,
                  ),
                  lockControlHeight: false,
                  tone: widget.tone,
                  emphasis: widget.emphasis,
                  enabled: widget.enabled,
                ),
                const VGap.sm(),
                VNumericKeypadGrid(
                  mode: widget.mode,
                  allowDecimal: _decimalAllowed,
                  onKey: _append,
                  onBackspace: _backspace,
                ),
                const VGap.sm(),
                Row(
                  children: [
                    Expanded(
                      child: VButton(
                        label: 'Hủy',
                        variant: VButtonVariant.secondary,
                        size: VButtonSize.large,
                        onPressed: widget.onCancel,
                      ),
                    ),
                    const VGap.horizontalSm(),
                    Expanded(
                      child: VButton(
                        label: 'Lưu',
                        size: VButtonSize.large,
                        onPressed: () => widget.onSave(_raw),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows [VNumericKeypadSheet] as a modal bottom sheet.
Future<String?> showVNumericKeypadSheet({
  required BuildContext context,
  required VNumericKeypadMode mode,
  String? title,
  String? unitLabel,
  String initialRaw = '',
  bool allowDecimal = true,
  VComponentTone tone = VComponentTone.primary,
  String? semanticLabel,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => VNumericKeypadSheet(
      mode: mode,
      title: title,
      unitLabel: unitLabel,
      initialRaw: initialRaw,
      allowDecimal: allowDecimal,
      tone: tone,
      semanticLabel: semanticLabel,
      onCancel: () => Navigator.of(sheetContext).pop(),
      onSave: (raw) => Navigator.of(sheetContext).pop(raw),
    ),
  );
}
