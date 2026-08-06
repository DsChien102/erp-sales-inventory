import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_text.dart';
import '../theme/v_color_scheme.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import 'v_button.dart';
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
    this.state,
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
  final VComponentState? state;
  final String? semanticLabel;

  @override
  State<VNumericKeypadSheet> createState() => _VNumericKeypadSheetState();
}

class _VNumericKeypadSheetState extends State<VNumericKeypadSheet> {
  late String _raw;

  bool get _isEnabled => (widget.state ?? VComponentState.enabled) == VComponentState.enabled;

  @override
  void initState() {
    super.initState();
    _raw = _sanitizeInitial(widget.initialRaw);
  }

  String _sanitizeInitial(String value) => switch (widget.mode) {
    VNumericKeypadMode.money => value.replaceAll(RegExp(r'[^0-9]'), ''),
    VNumericKeypadMode.quantity => value.replaceAll(RegExp(r'[^0-9.]'), ''),
  };

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

  void _appendMoney(String key) {
    final limitOk = key == '000'
        ? _raw.length + 3 <= widget.maxIntegerDigits
        : _raw.length < widget.maxIntegerDigits;
    if (!limitOk) return;
    _raw = '$_raw$key';
  }

  void _appendQuantity(String key) {
    switch (key) {
      case '.':
        if (!_decimalAllowed || _raw.contains('.')) return;
        _raw = _raw.isEmpty ? '0.' : '$_raw.';
      case _:
        if (_raw.contains('.')) {
          final parts = _raw.split('.');
          if (parts.length == 2 && parts[1].length >= 3) return;
          _raw = '$_raw$key';
          return;
        }
        final digits = _raw.replaceFirst(RegExp(r'^0+(?=\d)'), '');
        if (digits.length >= widget.maxIntegerDigits) return;
        _raw = digits.isEmpty && key == '0' ? '0' : '${digits == '0' ? '' : digits}$key';
    }
  }

  void _append(String key) {
    if (!_isEnabled) return;
    HapticFeedback.selectionClick();
    setState(() {
      switch (widget.mode) {
        case VNumericKeypadMode.money:
          _appendMoney(key);
        case VNumericKeypadMode.quantity:
          _appendQuantity(key);
      }
    });
  }

  void _backspace() {
    if (!_isEnabled || _raw.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _raw = _raw.substring(0, _raw.length - 1));
  }

  String get _displayValue => switch (widget.mode) {
    VNumericKeypadMode.money => _raw.isEmpty ? '0đ' : '${_formatThousands(_raw)}đ',
    VNumericKeypadMode.quantity => _raw.isEmpty ? '0' : _raw,
  };

  static String _formatThousands(String digits) {
    if (digits.isEmpty) return '0';
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buf.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('.');
    }
    return buf.toString();
  }

  Color _borderAccent(VColorScheme colors) => switch (widget.tone) {
    VComponentTone.danger => colors.danger,
    VComponentTone.warning => colors.warning,
    _ => colors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final displayBorder = Color.lerp(_borderAccent(colors), colors.borderDefault, 0.35)!;
    final borderWidth = widget.emphasis == VComponentEmphasis.strong
        ? VBorders.thick
        : VBorders.thin;

    return Semantics(
      label: widget.semanticLabel ?? _resolvedTitle,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            Container(
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(VRadius.card),
                border: VBorders.all(displayBorder, width: borderWidth),
              ),
              child: VText(_displayValue, variant: VTextVariant.headingH1),
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
