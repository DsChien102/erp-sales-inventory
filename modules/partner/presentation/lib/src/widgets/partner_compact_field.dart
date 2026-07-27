import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vet45_design_system/design_system.dart';

/// Dense single-line field for [PartnerFormFieldRow] — wraps [VTextField]
/// with [VCompactSearchableDropdown] control metrics.
class PartnerCompactTextField extends StatefulWidget {
  const PartnerCompactTextField({
    super.key,
    this.initialValue,
    this.hintText,
    this.keyboardType,
    this.digitsOnly = false,
    this.onChanged,
  });

  final String? initialValue;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool digitsOnly;
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
    final colors = context.vColors;
    return SizedBox(
      height: VCompactSearchableDropdown.controlHeight,
      width: double.infinity,
      child: VTextField(
        controller: _controller,
        hintText: widget.hintText,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.digitsOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        onChanged: widget.onChanged,
        isDense: true,
        contentPadding: VCompactSearchableDropdown.contentPadding,
        textStyle: VTypography.bodyDefault.copyWith(
          color: colors.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Dense multiline field — wraps [VTextField].
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
    final colors = context.vColors;
    final formatters = <TextInputFormatter>[
      if (widget.maxLength != null)
        LengthLimitingTextInputFormatter(widget.maxLength),
    ];

    return VTextField(
      controller: _controller,
      hintText: widget.hintText,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      inputFormatters: formatters.isEmpty ? null : formatters,
      onChanged: widget.onChanged,
      isDense: true,
      contentPadding: widget.maxLength == null
          ? VCompactSearchableDropdown.contentPadding
          : const EdgeInsets.fromLTRB(
              VSpacing.space3,
              VSpacing.space3 - 1,
              VSpacing.space3,
              VSpacing.space8,
            ),
      textStyle: VTypography.bodyDefault.copyWith(
        color: colors.textPrimary,
        height: 1.2,
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

  TextStyle _valueStyle(BuildContext context, {required bool hasValue}) {
    final colors = context.vColors;
    return VTypography.bodySmall.copyWith(
      color: hasValue ? colors.textPrimary : colors.textMuted,
      fontSize: 14,
      height: 1.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final hasValue = value != null;
    final displayText = hasValue ? value.toString() : (hintText ?? 'Chọn...');

    MediaQuery.viewInsetsOf(context);
    final menuHeight = VOverlayMenuLayout.resolvedMenuHeight(
      context,
      preferredHeight: VOverlayMenuLayout.defaultMenuHeight,
      stickyActionsReserve: 72,
    );

    // Constrain outside MenuAnchor so the row centers the 40px control
    // against the label (MenuAnchor alone can report a taller intrinsic size).
    return SizedBox(
      height: VCompactSearchableDropdown.controlHeight,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return MenuAnchor(
            alignmentOffset: VOverlayMenuLayout.alignmentOffset,
            crossAxisUnconstrained: false,
            style: MenuStyle(
              alignment: VOverlayMenuLayout.alignment,
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              minimumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 0)),
              maximumSize: WidgetStatePropertyAll(
                Size(constraints.maxWidth, menuHeight),
              ),
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
                      minimumSize: Size(
                        constraints.maxWidth,
                        VCompactSearchableDropdown.controlHeight,
                      ),
                      padding: VCompactSearchableDropdown.contentPadding,
                    ),
                    onPressed: enabled ? () => onChanged?.call(item.value) : null,
                    child: DefaultTextStyle(
                      style: _valueStyle(context, hasValue: true),
                      child: item.child,
                    ),
                  ),
                )
                .toList(),
            builder: (context, controller, child) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: !enabled
                      ? null
                      : () async {
                          if (controller.isOpen) {
                            controller.close();
                            return;
                          }
                          await VOverlayMenuLayout.ensureOpensDownward(
                            context,
                            stickyActionsReserve: 72,
                          );
                          if (!context.mounted) return;
                          controller.open();
                        },
                  borderRadius: BorderRadius.circular(VRadius.input),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: enabled ? colors.surface : colors.surfaceAlt,
                      borderRadius: BorderRadius.circular(VRadius.input),
                      border: Border.all(
                        color: enabled
                            ? colors.borderStrong
                            : colors.borderDefault,
                      ),
                    ),
                    child: Padding(
                      padding: VCompactSearchableDropdown.contentPadding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              displayText,
                              style: _valueStyle(context, hasValue: hasValue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          VIcon(
                            icon: controller.isOpen
                                ? VIcons.chevronUp
                                : VIcons.chevronDown,
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
              );
            },
          );
        },
      ),
    );
  }
}

/// Thin alias — prefer [VCompactSearchableDropdown] directly in new code.
typedef PartnerCompactSearchableDropdown<T> = VCompactSearchableDropdown<T>;
