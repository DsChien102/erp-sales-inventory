import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_context_extensions.dart';
import '../foundations/icons/v_icons.dart';
import '../patterns/v_gap.dart';
import '../primitives/v_icon.dart';
import '../primitives/v_text.dart';
import '../theme/v_color_scheme.dart';
import '../tokens/v_borders.dart';
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

  final String? label;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final bool isRequired;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState state;
  final String? semanticLabel;

  /// When true (default), cells advertise [AutofillHints.oneTimeCode].
  final bool enableAutofill;

  const VVerificationCodeField({
    super.key,
    this.length = 6,
    this.charset = VVerificationCodeCharset.numeric,
    this.onCompleted,
    this.onChanged,
    this.label,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.isRequired = false,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.state = VComponentState.enabled,
    this.semanticLabel,
    this.enableAutofill = true,
  }) : assert(length > 0, 'length must be greater than 0');

  @override
  State<VVerificationCodeField> createState() => _VVerificationCodeFieldState();
}

class _VVerificationCodeFieldState extends State<VVerificationCodeField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _lastCompleted = '';

  bool get _isAlphanumeric => widget.charset == VVerificationCodeCharset.alphanumeric;

  @override
  void initState() {
    super.initState();
    _createFields(widget.length);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNodes.isNotEmpty) {
          _focusNodes.first.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant VVerificationCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.length != widget.length || oldWidget.charset != widget.charset) {
      _disposeFields();
      _createFields(widget.length);
      _lastCompleted = '';
    }
  }

  @override
  void dispose() {
    _disposeFields();
    super.dispose();
  }

  void _createFields(int length) {
    _controllers = List.generate(length, (_) => TextEditingController());
    _focusNodes = List.generate(length, (index) {
      final node = FocusNode(
        onKeyEvent: (focusNode, event) => _onKeyEvent(index, event),
      );
      node.addListener(_handleFocusChange);
      return node;
    });
  }

  void _disposeFields() {
    for (final node in _focusNodes) {
      node.removeListener(_handleFocusChange);
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  String get _code => _controllers.map((c) => c.text).join();

  String _sanitize(String raw) {
    if (_isAlphanumeric) {
      return raw.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z]'), '');
    }
    return raw.replaceAll(RegExp(r'[^0-9]'), '');
  }

  List<TextInputFormatter> get _inputFormatters {
    if (_isAlphanumeric) {
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
        _UpperCaseTextFormatter(),
      ];
    }
    return [FilteringTextInputFormatter.digitsOnly];
  }

  void _notifyChanged() {
    final code = _code;
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

  void _setChar(int index, String char) {
    final controller = _controllers[index];
    controller.value = TextEditingValue(
      text: char,
      selection: TextSelection.collapsed(offset: char.length),
    );
  }

  void _applyChars(int startIndex, String raw) {
    final cleaned = _sanitize(raw);
    if (cleaned.isEmpty) return;

    var writeIndex = startIndex;
    for (var i = 0; i < cleaned.length && writeIndex < widget.length; i++) {
      _setChar(writeIndex, cleaned[i]);
      writeIndex++;
    }

    final focusIndex = writeIndex < widget.length ? writeIndex : widget.length - 1;
    if (writeIndex >= widget.length) {
      _focusNodes[focusIndex].unfocus();
    } else {
      _focusNodes[focusIndex].requestFocus();
    }

    setState(() {});
    _notifyChanged();
  }

  void _onCellChanged(int index, String value) {
    if (value.length > 1) {
      _applyChars(index, value);
      return;
    }

    if (value.isEmpty) {
      setState(() {});
      _notifyChanged();
      return;
    }

    final cleaned = _sanitize(value);
    if (cleaned.isEmpty) {
      _controllers[index].clear();
      setState(() {});
      _notifyChanged();
      return;
    }

    _setChar(index, cleaned[cleaned.length - 1]);

    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }

    setState(() {});
    _notifyChanged();
  }

  KeyEventResult _onKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }

    if (_controllers[index].text.isNotEmpty) {
      return KeyEventResult.ignored;
    }

    if (index <= 0) return KeyEventResult.ignored;

    _controllers[index - 1].clear();
    _focusNodes[index - 1].requestFocus();
    setState(() {});
    _notifyChanged();
    return KeyEventResult.handled;
  }

  InputBorder _outline(Color color, double width) {
    return VBorders.outlineInput(color, width: width);
  }

  Widget? _message(VColorScheme colors, {required bool hasError}) {
    final text = hasError ? widget.errorText : widget.helperText;
    if (text == null) return null;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          VIcon(
            icon: hasError ? VIcons.error : VIcons.info,
            color: hasError ? colors.danger : colors.textMuted,
            iconSize: VIconSize.sm,
          ),
          const VGap.horizontalXs(),
          Flexible(
            child: VText(
              text,
              variant: VTextVariant.bodySmall,
              color: hasError ? colors.danger : colors.textMuted,
            ),
          ),
        ],
      ),
    );
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
    final focused = isEnabled && _focusNodes[index].hasFocus;
    final restingBorderColor = widget.errorText != null
        ? colors.danger
        : switch (widget.tone) {
            VComponentTone.primary => colors.primary,
            VComponentTone.danger => colors.danger,
            _ => colors.borderStrong,
          };
    final focusBorderColor = useDanger ? colors.danger : colors.primary;
    final restingBorder = _outline(restingBorderColor, borderWidth);
    final focusBorder = _outline(focusBorderColor, borderWidth);
    final dangerBorder = _outline(colors.danger, borderWidth);
    final disabledBorder = _outline(colors.borderDefault, borderWidth);

    final textStyle = VTypography.headingH3.copyWith(
      color: isEnabled
          ? (useDanger && widget.errorText != null ? colors.danger : colors.textPrimary)
          : colors.textMuted,
      fontWeight: FontWeight.w700,
      // Slightly tighter for alphanumeric / narrower cells.
      fontSize: cellW < VVerificationCodeField.cellWidth
          ? VTypography.headingH4.fontSize
          : VTypography.headingH3.fontSize,
    );

    final field = SizedBox(
      width: cellW,
      height: cellH,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        enabled: isEnabled,
        keyboardType: _isAlphanumeric ? TextInputType.visiblePassword : TextInputType.number,
        textCapitalization: _isAlphanumeric
            ? TextCapitalization.characters
            : TextCapitalization.none,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        style: textStyle,
        cursorColor: useDanger ? colors.danger : colors.primary,
        expands: true,
        maxLines: null,
        minLines: null,
        autofillHints: widget.enableAutofill ? const [AutofillHints.oneTimeCode] : null,
        inputFormatters: _inputFormatters,
        onChanged: (value) => _onCellChanged(index, value),
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: isEnabled ? colors.surface : colors.surfaceAlt,
          hoverColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: cellW, height: cellH),
          border: restingBorder,
          enabledBorder: restingBorder,
          focusedBorder: focusBorder,
          disabledBorder: disabledBorder,
          errorBorder: dangerBorder,
          focusedErrorBorder: dangerBorder,
        ),
      ),
    );

    return VTextFieldFocusRing(
      focused: focused,
      danger: useDanger,
      innerRadius: VRadius.input,
      child: field,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEnabled = widget.enabled && widget.state != VComponentState.disabled;
    final hasError = widget.errorText != null;
    final useDanger = hasError || widget.tone == VComponentTone.danger;
    final borderWidth = VBorders.widthFor(widget.emphasis);
    final message = _message(colors, hasError: hasError);

    return Semantics(
      textField: true,
      enabled: isEnabled,
      label: widget.semanticLabel ?? widget.label ?? 'Verification code',
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
            const VGap.sm(),
          ],
          LayoutBuilder(
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

              return Row(
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
              );
            },
          ),
          if (message != null) ...[
            const VGap.sm(),
            message,
          ],
        ],
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
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
