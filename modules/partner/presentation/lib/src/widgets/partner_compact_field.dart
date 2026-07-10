import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

String _removeVietnameseTones(String str) {
  str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
  str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
  str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
  str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
  str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
  str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
  str = str.replaceAll(RegExp(r'[đ]'), 'd');
  str = str.replaceAll(RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'), 'A');
  str = str.replaceAll(RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'), 'E');
  str = str.replaceAll(RegExp(r'[ÌÍỊỈĨ]'), 'I');
  str = str.replaceAll(RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'), 'O');
  str = str.replaceAll(RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'), 'U');
  str = str.replaceAll(RegExp(r'[ỲÝỴỶỸ]'), 'Y');
  str = str.replaceAll(RegExp(r'[Đ]'), 'D');
  return str;
}

abstract final class PartnerCompactField {
  static const double controlHeight = 40;

  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );

  static TextStyle valueStyle(BuildContext context) {
    return VTypography.bodySmall.copyWith(
      color: context.vColors.textPrimary,
      fontSize: 14,
      height: 1.2,
    );
  }

  static TextStyle hintStyle(BuildContext context) {
    return VTypography.bodySmall.copyWith(
      color: context.vColors.textMuted,
      fontSize: 14,
      height: 1.2,
    );
  }

  static BoxDecoration decoration(
    BuildContext context, {
    required bool enabled,
  }) {
    final colors = context.vColors;
    return BoxDecoration(
      color: enabled ? colors.surface : colors.surfaceAlt,
      borderRadius: BorderRadius.circular(VRadius.input),
      border: Border.all(
        color: enabled ? colors.borderStrong : colors.borderDefault,
      ),
    );
  }

  static InputDecoration inputDecoration(
    BuildContext context, {
    String? hintText,
    bool enabled = true,
  }) {
    final colors = context.vColors;
    final borderRadius = BorderRadius.circular(VRadius.input);

    OutlineInputBorder border(Color color) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: color),
      );
    }

    final defaultBorder = border(
      enabled ? colors.borderStrong : colors.borderDefault,
    );

    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: hintStyle(context),
      filled: true,
      fillColor: enabled ? colors.surface : colors.surfaceAlt,
      contentPadding: contentPadding,
      border: defaultBorder,
      enabledBorder: defaultBorder,
      disabledBorder: defaultBorder,
      focusedBorder: border(colors.primary),
      errorBorder: defaultBorder,
      focusedErrorBorder: border(colors.primary),
    );
  }
}

class PartnerCompactTextField extends StatefulWidget {
  const PartnerCompactTextField({
    super.key,
    this.initialValue,
    this.hintText,
    this.keyboardType,
    this.onChanged,
  });

  final String? initialValue;
  final String? hintText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  State<PartnerCompactTextField> createState() => _PartnerCompactTextFieldState();
}

class _PartnerCompactTextFieldState extends State<PartnerCompactTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant PartnerCompactTextField oldWidget) {
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
    return SizedBox(
      height: PartnerCompactField.controlHeight,
      width: double.infinity,
      child: TextField(
        controller: _controller,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: PartnerCompactField.valueStyle(context),
        textAlignVertical: TextAlignVertical.center,
        decoration: PartnerCompactField.inputDecoration(
          context,
          hintText: widget.hintText,
        ),
      ),
    );
  }
}

class PartnerCompactMultilineTextField extends StatefulWidget {
  const PartnerCompactMultilineTextField({
    super.key,
    this.initialValue,
    this.hintText,
    this.minLines = 2,
    this.maxLines = 3,
    this.maxLength,
    this.onChanged,
  });

  final String? initialValue;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  State<PartnerCompactMultilineTextField> createState() =>
      _PartnerCompactMultilineTextFieldState();
}

class _PartnerCompactMultilineTextFieldState
    extends State<PartnerCompactMultilineTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant PartnerCompactMultilineTextField oldWidget) {
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
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: PartnerCompactField.valueStyle(context),
      textAlignVertical: TextAlignVertical.top,
      buildCounter: widget.maxLength == null
          ? null
          : (
              _, {
              required currentLength,
              required isFocused,
              required maxLength,
            }) =>
              null,
      decoration: PartnerCompactField.inputDecoration(
        context,
        hintText: widget.hintText,
      ).copyWith(
        contentPadding: widget.maxLength == null
            ? null
            : const EdgeInsets.fromLTRB(12, 11, 12, 32),
      ),
    );
  }
}

class PartnerCompactDropdown<T> extends StatelessWidget {
  const PartnerCompactDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    DropdownMenuItem<T>? selectedItem;
    for (final item in items) {
      if (item.value == value) {
        selectedItem = item;
        break;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return MenuAnchor(
          alignmentOffset: const Offset(0, 4),
          crossAxisUnconstrained: false,
          style: MenuStyle(
            alignment: AlignmentDirectional.topStart,
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
            minimumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 0)),
            maximumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 240)),
            backgroundColor: WidgetStatePropertyAll(colors.surface),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
            elevation: const WidgetStatePropertyAll(4),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VRadius.input),
                side: BorderSide(color: colors.borderDefault),
              ),
            ),
          ),
          menuChildren: items
              .map(
                (item) => MenuItemButton(
                  style: MenuItemButton.styleFrom(
                    minimumSize: Size(constraints.maxWidth, 40),
                    padding: PartnerCompactField.contentPadding,
                  ),
                  onPressed: enabled ? () => onChanged?.call(item.value) : null,
                  child: DefaultTextStyle(
                    style: PartnerCompactField.valueStyle(context),
                    child: item.child,
                  ),
                ),
              )
              .toList(),
          builder: (context, controller, child) {
            return SizedBox(
              height: PartnerCompactField.controlHeight,
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: !enabled
                      ? null
                      : () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                  borderRadius: BorderRadius.circular(VRadius.input),
                  child: DecoratedBox(
                    decoration: PartnerCompactField.decoration(
                      context,
                      enabled: enabled,
                    ),
                    child: Padding(
                      padding: PartnerCompactField.contentPadding,
                      child: Row(
                        children: [
                          Expanded(
                            child: DefaultTextStyle(
                              style: selectedItem != null
                                  ? PartnerCompactField.valueStyle(context)
                                  : PartnerCompactField.hintStyle(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: selectedItem != null
                                  ? selectedItem.child
                                  : Text(hintText ?? 'Chọn...'),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: enabled
                                ? colors.textSecondary
                                : colors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class PartnerCompactSearchableDropdown<T> extends StatelessWidget {
  const PartnerCompactSearchableDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
  });

  final T? value;
  final List<DropdownMenuEntry<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: PartnerCompactField.controlHeight,
          width: double.infinity,
          child: DropdownMenu<T>(
            key: ValueKey('compact-search-$value-$enabled'),
            width: constraints.maxWidth,
            enabled: enabled,
            initialSelection: value,
            hintText: hintText,
            enableSearch: true,
            enableFilter: true,
            filterCallback: (entries, filter) {
              final normalizedFilter =
                  _removeVietnameseTones(filter).toLowerCase();
              return entries.where((entry) {
                final normalizedLabel =
                    _removeVietnameseTones(entry.label).toLowerCase();
                return normalizedLabel.contains(normalizedFilter);
              }).toList();
            },
            requestFocusOnTap: true,
            menuHeight: 280,
            textStyle: PartnerCompactField.valueStyle(context).copyWith(
              color: enabled ? colors.textPrimary : colors.textMuted,
            ),
            menuStyle: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(colors.surface),
              surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VRadius.input),
                  side: BorderSide(color: colors.borderDefault),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              isDense: true,
              filled: true,
              fillColor: enabled ? colors.surface : colors.surfaceAlt,
              contentPadding: PartnerCompactField.contentPadding,
              hintStyle: PartnerCompactField.hintStyle(context),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VRadius.input),
                borderSide: BorderSide(color: colors.borderStrong),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VRadius.input),
                borderSide: BorderSide(color: colors.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VRadius.input),
                borderSide: BorderSide(color: colors.primary),
              ),
              constraints: const BoxConstraints(
                minHeight: PartnerCompactField.controlHeight,
                maxHeight: PartnerCompactField.controlHeight,
              ),
            ),
            onSelected: onChanged,
            dropdownMenuEntries: items,
          ),
        );
      },
    );
  }
}
