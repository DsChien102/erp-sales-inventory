import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vet45_design_system/design_system.dart';

abstract final class PartnerOutlinedField {
  static const double controlHeight = 48;
  static const double fieldGap = VSpacing.space2;

  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 12,
  );

  static Widget buildLabel(
    BuildContext context,
    String label, {
    bool isRequired = false,
  }) {
    return RichText(
      text: TextSpan(
        style: VTypography.bodySmall.copyWith(
          color: context.vColors.textSecondary,
          fontSize: 14,
        ),
        children: [
          TextSpan(text: label),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: VColors.danger),
            ),
        ],
      ),
    );
  }

  static InputDecoration decoration(
    BuildContext context, {
    required Widget label,
    String? errorText,
    bool enabled = true,
    bool multiline = false,
  }) {
    final colors = context.vColors;
    final borderRadius = BorderRadius.circular(VRadius.input);

    OutlineInputBorder border(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    final defaultBorder = border(
      enabled ? colors.borderDefault : colors.borderDefault,
    );

    return InputDecoration(
      label: label,
      alignLabelWithHint: multiline,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelStyle: VTypography.bodySmall.copyWith(
        color: colors.textSecondary,
        fontSize: 14,
        backgroundColor: colors.surface,
      ),
      isDense: true,
      filled: true,
      fillColor: enabled ? colors.surface : colors.surfaceAlt,
      contentPadding: multiline ? const EdgeInsets.fromLTRB(12, 16, 12, 12) : contentPadding,
      border: defaultBorder,
      enabledBorder: defaultBorder,
      disabledBorder: defaultBorder,
      focusedBorder: border(colors.primary, width: 1.5),
      errorBorder: border(VColors.danger),
      focusedErrorBorder: border(VColors.danger, width: 1.5),
      errorText: errorText,
      errorStyle: VTypography.bodySmall.copyWith(color: VColors.danger),
      constraints: multiline
          ? const BoxConstraints(minHeight: 96)
          : const BoxConstraints(
              minHeight: controlHeight,
              maxHeight: controlHeight,
            ),
    );
  }
}

class PartnerOutlinedTextField extends StatefulWidget {
  const PartnerOutlinedTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.isRequired = false,
    this.errorText,
    this.hintText,
    this.keyboardType,
    this.digitsOnly = false,
    this.onChanged,
  });

  final String label;
  final String? initialValue;
  final bool isRequired;
  final String? errorText;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool digitsOnly;
  final ValueChanged<String>? onChanged;

  @override
  State<PartnerOutlinedTextField> createState() => _PartnerOutlinedTextFieldState();
}

class _PartnerOutlinedTextFieldState extends State<PartnerOutlinedTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant PartnerOutlinedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialValue ?? '';
    if (oldWidget.initialValue != widget.initialValue && _controller.text != next) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      onChanged: widget.onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: VTypography.bodyDefault.copyWith(
        color: context.vColors.textPrimary,
        fontSize: 14,
      ),
      textAlignVertical: TextAlignVertical.center,
      decoration:
          PartnerOutlinedField.decoration(
            context,
            label: PartnerOutlinedField.buildLabel(
              context,
              widget.label,
              isRequired: widget.isRequired,
            ),
            errorText: widget.errorText,
          ).copyWith(
            hintText: widget.hintText,
            hintStyle: VTypography.bodyDefault.copyWith(
              color: context.vColors.textMuted,
              fontSize: 14,
            ),
          ),
    );
  }
}

class PartnerOutlinedMultilineTextField extends StatefulWidget {
  const PartnerOutlinedMultilineTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.isRequired = false,
    this.errorText,
    this.hintText,
    this.minLines = 3,
    this.maxLines = 5,
    this.onChanged,
  });

  final String label;
  final String? initialValue;
  final bool isRequired;
  final String? errorText;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  State<PartnerOutlinedMultilineTextField> createState() =>
      _PartnerOutlinedMultilineTextFieldState();
}

class _PartnerOutlinedMultilineTextFieldState extends State<PartnerOutlinedMultilineTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant PartnerOutlinedMultilineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialValue ?? '';
    if (oldWidget.initialValue != widget.initialValue && _controller.text != next) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: VTypography.bodyDefault.copyWith(
        color: context.vColors.textPrimary,
        fontSize: 14,
      ),
      textAlignVertical: TextAlignVertical.top,
      decoration:
          PartnerOutlinedField.decoration(
            context,
            label: PartnerOutlinedField.buildLabel(
              context,
              widget.label,
              isRequired: widget.isRequired,
            ),
            errorText: widget.errorText,
            multiline: true,
          ).copyWith(
            hintText: widget.hintText,
            hintStyle: VTypography.bodyDefault.copyWith(
              color: context.vColors.textMuted,
              fontSize: 14,
            ),
          ),
    );
  }
}

class PartnerOutlinedDropdown<T> extends StatelessWidget {
  const PartnerOutlinedDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.isRequired = false,
    this.errorText,
    this.hintText,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isRequired;
  final String? errorText;
  final String? hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final selectedItem = value == null
        ? null
        : items.cast<DropdownMenuItem<T>?>().firstWhere(
            (item) => item?.value == value,
            orElse: () => null,
          );

    return LayoutBuilder(
      builder: (context, constraints) => PopupMenuButton<T>(
        enabled: enabled && onChanged != null,
        position: PopupMenuPosition.under,
        constraints: BoxConstraints.tightFor(width: constraints.maxWidth),
        tooltip: '',
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          side: BorderSide(color: colors.borderDefault),
        ),
        onSelected: (selected) => onChanged?.call(selected),
        itemBuilder: (_) => items
            .map(
              (item) => PopupMenuItem<T>(
                value: item.value,
                child: DefaultTextStyle(
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textPrimary,
                    fontSize: 14,
                  ),
                  child: item.child,
                ),
              ),
            )
            .toList(),
        child: InputDecorator(
          isEmpty: selectedItem == null,
          decoration: PartnerOutlinedField.decoration(
            context,
            label: PartnerOutlinedField.buildLabel(
              context,
              label,
              isRequired: isRequired,
            ),
            errorText: errorText,
            enabled: enabled,
          ),
          child: Row(
            children: [
              Expanded(
                child: DefaultTextStyle(
                  style: VTypography.bodyDefault.copyWith(
                    color: selectedItem == null ? colors.textMuted : colors.textPrimary,
                    fontSize: 14,
                  ),
                  child: selectedItem?.child ?? Text(hintText ?? 'Chọn...'),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: enabled ? colors.textSecondary : colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
