import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:c45_design_system/design_system.dart';

class _SingleDecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final filtered = StringBuffer();
    var hasSeparator = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) {
        filtered.write(ch);
      } else if ((ch == ',' || ch == '.') && !hasSeparator) {
        hasSeparator = true;
        filtered.write(ch);
      } else if (ch == ',' || ch == '.') {
        return oldValue;
      }
    }
    final result = filtered.toString();
    if (result == text) return newValue;
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

/// Ô nhập số tại dòng theo mẫu K7 (prototype k7EditCell).
class K7EditCell extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final String unit;
  final String? errorText;
  final String semanticLabel;
  final bool enabled;
  final bool allowDecimal;
  final TextInputAction? textInputAction;
  final double? maxWidth;
  final FocusNode? focusNode;

  const K7EditCell({
    super.key,
    required this.value,
    required this.onChanged,
    this.onSubmitted,
    this.unit = '',
    this.errorText,
    required this.semanticLabel,
    this.enabled = true,
    this.allowDecimal = false,
    this.textInputAction,
    this.maxWidth,
    this.focusNode,
  });

  @override
  State<K7EditCell> createState() => _K7EditCellState();
}

class _K7EditCellState extends State<K7EditCell> {
  late TextEditingController _controller;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant K7EditCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isWide = inventoryIsWide(context);
    final boxHeight = isWide ? 40.0 : 44.0;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final isFocused = _effectiveFocusNode.hasFocus;

    Color borderColor;
    if (hasError) {
      borderColor = const Color(0xFFB53232);
    } else if (isFocused) {
      borderColor = const Color(0xFFB8DFBD);
    } else {
      borderColor = const Color(0xFFE5E8EB);
    }

    final boxDecoration = BoxDecoration(
      color: widget.enabled ? const Color(0xFFFFFFFF) : const Color(0xFFE5E8EB),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: borderColor,
        width: (isFocused && !hasError) ? 1.5 : 1.0,
      ),
    );

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('k7_edit_cell_box'),
          constraints: BoxConstraints(
            minHeight: boxHeight,
            maxHeight: boxHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: boxDecoration,
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  label: widget.semanticLabel,
                  child: TextField(
                    controller: _controller,
                    focusNode: _effectiveFocusNode,
                    enabled: widget.enabled,
                    textAlign: TextAlign.right,
                    keyboardType: widget.allowDecimal
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number,
                    textInputAction: widget.textInputAction,
                    inputFormatters: widget.allowDecimal
                        ? [_SingleDecimalTextInputFormatter()]
                        : [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'JetBrainsMono',
                      color: widget.enabled
                          ? context.vColors.textPrimary
                          : context.vColors.textSecondary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isCollapsed: true,
                    ),
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                  ),
                ),
              ),
              if (widget.unit.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  widget.unit,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w400,
                    color: context.vColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                fontSize: 12,
                height: 16 / 12,
                color: Color(0xFFB53232),
              ),
            ),
          ),
      ],
    );

    if (widget.maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth!),
        child: content,
      );
    }

    return content;
  }
}
