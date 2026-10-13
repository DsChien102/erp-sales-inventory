import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../patterns/v_field.dart';
import '../theme/v_color_scheme.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_opacity.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'v_text_field_focus_ring.dart';

/// Character set accepted by [VVerificationCodeField].
enum VVerificationCodeCharset {
  /// Digits `0-9` only (default OTP / 2FA).
  numeric,

  /// Uppercase `A-Z` and digits `0-9` (invitation / activation codes).
  alphanumeric,
}

/// Multi-box field for OTP or alphanumeric verification codes.
///
/// Prefer [VField] + [VFieldLabel] / [VFieldDescription] / [VFieldError] for chrome.
/// Uses one hidden [TextField] for IME input (backspace / paste / autofill) and
/// paints digit slots as display-only cells.
class VVerificationCodeField extends StatefulWidget {
  static const double cellWidth = 48;

  /// Taller than [cellWidth] so digits + heading style have room; focus ring
  /// still draws [VTextFieldFocusRing.ringSize] outside this box.
  static const double cellHeight = 56;

  /// Number of character slots. Defaults to 6.
  final int length;

  /// Accepted characters. Defaults to [VVerificationCodeCharset.numeric].
  final VVerificationCodeCharset charset;

  /// Called when all [length] characters are filled.
  final ValueChanged<String>? onCompleted;

  /// Called whenever the current code string changes.
  final ValueChanged<String>? onChanged;

  @Deprecated('Use VField + VFieldLabel instead')
  final String? label;
  @Deprecated('Use VFieldDescription instead')
  final String? helperText;
  @Deprecated(
    'Use VField(invalid: true) + VFieldError for message; keep error chrome via tone/domain',
  )
  final String? errorText;
  final bool? enabled;
  final bool autofocus;
  @Deprecated('Use VFieldLabel(..., isRequired: true) instead')
  final bool isRequired;

  /// Local invalid override. Null inherits [VField.invalid].
  final bool? invalid;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  /// When true (default), the hidden field advertises [AutofillHints.oneTimeCode].
  final bool enableAutofill;

  const VVerificationCodeField({
    super.key,
    this.length = 6,
    this.charset = VVerificationCodeCharset.numeric,
    this.onCompleted,
    this.onChanged,
    @Deprecated('Use VField + VFieldLabel instead') this.label,
    @Deprecated('Use VFieldDescription instead') this.helperText,
    @Deprecated(
      'Use VField(invalid: true) + VFieldError for message; keep error chrome via tone/domain',
    )
    this.errorText,
    this.enabled,
    this.autofocus = false,
    @Deprecated('Use VFieldLabel(..., isRequired: true) instead') this.isRequired = false,
    this.invalid,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
    this.enableAutofill = true,
  }) : assert(length > 0, 'length must be greater than 0');

  @override
  State<VVerificationCodeField> createState() => _VVerificationCodeFieldState();
}

class _VVerificationCodeFieldState extends State<VVerificationCodeField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _lastCompleted = '';

  bool get _isAlphanumeric => widget.charset == VVerificationCodeCharset.alphanumeric;

  String get _code => _controller.text;

  /// Slot that shows the focus ring while the hidden field is focused.
  int get _activeIndex {
    final len = _code.length;
    if (len >= widget.length) return widget.length - 1;
    return len;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            VComponentScope.resolveEnabled(context, local: widget.enabled)) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant VVerificationCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.length != widget.length || oldWidget.charset != widget.charset) {
      final cleaned = _sanitize(_controller.text);
      if (cleaned != _controller.text) {
        _controller.value = TextEditingValue(
          text: cleaned,
          selection: TextSelection.collapsed(offset: cleaned.length),
        );
      }
      _lastCompleted = '';
      _notifyChanged(cleaned);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  String _sanitize(String raw) {
    var cleaned = raw;
    if (_isAlphanumeric) {
      cleaned = cleaned.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z]'), '');
    } else {
      cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    }
    if (cleaned.length > widget.length) {
      cleaned = cleaned.substring(0, widget.length);
    }
    return cleaned;
  }

  List<TextInputFormatter> get _inputFormatters {
    if (_isAlphanumeric) {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
        _UpperCaseTextFormatter(),
        LengthLimitingTextInputFormatter(widget.length),
      ];
    }
    return [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(widget.length),
    ];
  }

  void _notifyChanged(String code) {
    widget.onChanged?.call(code);
    if (code.length == widget.length) {
      if (code != _lastCompleted) {
        _lastCompleted = code;
        widget.onCompleted?.call(code);
      }
    } else {
      _lastCompleted = '';
    }
  }

  void _onChanged(String value) {
    final cleaned = _sanitize(value);
    if (cleaned != _controller.text) {
      _controller.value = TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
    }
    setState(() {});
    _notifyChanged(cleaned);
  }

  Widget _buildCell({
    required int index,
    required VColorScheme colors,
    required bool isEnabled,
    required bool useDanger,
    required double borderWidth,
    required double cellW,
    required double cellH,
  }) {
    final code = _code;
    final char = index < code.length ? code[index] : '';
    final focused = isEnabled && _focusNode.hasFocus && index == _activeIndex;

    // ignore: deprecated_member_use_from_same_package
    final legacyError = widget.errorText;
    final restingBorderColor = legacyError != null
        ? colors.danger
        : switch (widget.tone) {
            VComponentTone.primary => colors.primary,
            VComponentTone.danger => colors.danger,
            _ => colors.borderInput,
          };
    final focusBorderColor = useDanger ? colors.danger : colors.primary;
    final borderColor = focused ? focusBorderColor : restingBorderColor;

    final textStyle = VTypography.headingH3.copyWith(
      color: useDanger && legacyError != null ? colors.danger : colors.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: cellW < VVerificationCodeField.cellWidth
          ? VTypography.headingH4.fontSize
          : VTypography.headingH3.fontSize,
    );

    final cell = SizedBox(
      width: cellW,
      height: cellH,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(VRadius.input),
          border: Border.fromBorderSide(
            VBorders.side(borderColor, width: borderWidth),
          ),
        ),
        child: Center(
          child: Text(
            char,
            style: textStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    return VTextFieldFocusRing(
      focused: focused,
      danger: useDanger,
      innerRadius: VRadius.input,
      child: cell,
    );
  }

  Widget _buildHiddenInput({required bool isEnabled}) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: isEnabled,
      autofocus: widget.autofocus,
      keyboardType: _isAlphanumeric ? TextInputType.visiblePassword : TextInputType.number,
      textCapitalization: _isAlphanumeric
          ? TextCapitalization.characters
          : TextCapitalization.none,
      showCursor: false,
      enableInteractiveSelection: true,
      style: const TextStyle(color: Colors.transparent, height: 0.01, fontSize: 1),
      cursorColor: Colors.transparent,
      autofillHints: widget.enableAutofill ? const [AutofillHints.oneTimeCode] : null,
      inputFormatters: _inputFormatters,
      onChanged: _onChanged,
      decoration: const InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        filled: false,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
        counterText: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEnabled = VComponentScope.resolveEnabled(context, local: widget.enabled);
    // ignore: deprecated_member_use_from_same_package
    final legacyError = widget.errorText;
    // ignore: deprecated_member_use_from_same_package
    final legacyHelper = widget.helperText;
    // ignore: deprecated_member_use_from_same_package
    final legacyLabel = widget.label;
    // ignore: deprecated_member_use_from_same_package
    final legacyRequired = widget.isRequired;
    final hasError = legacyError != null;
    final isInvalid =
        VField.resolveInvalid(context, local: widget.invalid) || hasError;
    final useDanger = isInvalid || widget.tone == VComponentTone.danger;
    final borderWidth = VBorders.widthFor(widget.emphasis);

    final control = LayoutBuilder(
      builder: (context, constraints) {
        final gap = VSpacing.space2;
        final gapsTotal = gap * (widget.length - 1);
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : VVerificationCodeField.cellWidth * widget.length + gapsTotal;
        final maxCellW = (available - gapsTotal) / widget.length;
        final cellW = math.min(VVerificationCodeField.cellWidth, maxCellW);
        final cellH = cellW < VVerificationCodeField.cellWidth
            ? math.max(48.0, cellW + 8)
            : VVerificationCodeField.cellHeight;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            IgnorePointer(
              child: Row(
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) SizedBox(width: gap),
                    _buildCell(
                      index: i,
                      colors: colors,
                      isEnabled: isEnabled,
                      useDanger: useDanger,
                      borderWidth: borderWidth,
                      cellW: cellW,
                      cellH: cellH,
                    ),
                  ],
                ],
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: _buildHiddenInput(isEnabled: isEnabled),
              ),
            ),
          ],
        );
      },
    );

    final useShell = legacyLabel != null ||
        legacyHelper != null ||
        legacyError != null ||
        legacyRequired;
    final body = useShell
        ? vFieldShell(
            control: control,
            label: legacyLabel,
            isRequired: legacyRequired,
            helperText: legacyHelper,
            errorText: legacyError,
          )
        : control;

    return vInspectorHide(
      Semantics(
        textField: true,
        enabled: isEnabled,
        label: widget.semanticLabel ?? legacyLabel ?? 'Verification code',
        value: _code,
        child: vDisabledOpacity(enabled: isEnabled, child: body),
      ),
    );
  }
}

final class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upper = newValue.text.toUpperCase();
    if (upper == newValue.text) return newValue;
    return TextEditingValue(
      text: upper,
      selection: TextSelection.collapsed(offset: upper.length),
      composing: TextRange.empty,
    );
  }
}
