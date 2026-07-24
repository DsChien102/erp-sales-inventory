import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../primitives/v_text.dart';
import '../patterns/v_gap.dart';
import 'v_text_field.dart';

/// Design system standard TextFormField wrapper.
///
/// Wraps standard Flutter [TextField] inside a [FormField] while maintaining identical styling,
/// density, behavior, and tokens to [VTextField].
class VTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final String? suffixText;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool isRequired;
  final int? minLines;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final VTextFieldVariant variant;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState state;
  final String? semanticLabel;

  // TextFormField specific fields
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final String? initialValue;
  final AutovalidateMode? autovalidateMode;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final bool showCounter;

  const VTextFormField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.suffixText,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.isRequired = false,
    this.minLines,
    this.maxLines = 1,
    this.inputFormatters,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.focusNode,
    this.onFieldSubmitted,
    this.contentPadding,
    this.fillColor,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.variant = VTextFieldVariant.standard,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.state = VComponentState.enabled,
    this.semanticLabel,
    this.validator,
    this.onSaved,
    this.initialValue,
    this.autovalidateMode,
    this.maxLength,
    this.maxLengthEnforcement,
    this.showCounter = true,
  });

  @override
  State<VTextFormField> createState() => _VTextFormFieldState();
}

class _VTextFormFieldState extends State<VTextFormField> {
  TextEditingController? _localController;
  int _currentLength = 0;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_localController ??= TextEditingController(text: widget.initialValue));

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_onTextChanged);
    _currentLength = _effectiveController.text.length;
  }

  @override
  void didUpdateWidget(covariant VTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      widget.controller?.addListener(_onTextChanged);

      // If we switched from local to external controller or vice versa, manage local controller
      if (widget.controller != null && _localController != null) {
        _localController!.dispose();
        _localController = null;
      }

      _currentLength = _effectiveController.text.length;
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTextChanged);
    _localController?.removeListener(_onTextChanged);
    _localController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        _currentLength = _effectiveController.text.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isInline = widget.variant == VTextFieldVariant.inline;

    final bool isEnabled = widget.enabled && widget.state != VComponentState.disabled;
    final Color toneBorderColor = switch (widget.tone) {
      VComponentTone.primary => dynamicColors.primary,
      VComponentTone.danger => dynamicColors.danger,
      _ => dynamicColors.borderStrong,
    };

    final defaultStyle = isInline
        ? VTypography.bodyDefault.copyWith(
            color: isEnabled ? dynamicColors.textPrimary : dynamicColors.textSecondary,
            fontWeight: FontWeight.w700,
          )
        : VTypography.bodyDefault.copyWith(
            color: isEnabled ? dynamicColors.textPrimary : dynamicColors.textSecondary,
          );

    final defaultContentPadding = isInline
        ? const EdgeInsets.symmetric(vertical: 6)
        : EdgeInsets.symmetric(
            horizontal: context.vDensity.fieldHorizontalPadding,
            vertical: context.vDensity.fieldVerticalPadding,
          );

    final defaultFillColor = isInline
        ? dynamicColors.background
        : (isEnabled ? dynamicColors.surface : dynamicColors.surfaceAlt);

    final defaultBorder = isInline
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(VRadius.r4),
            borderSide: BorderSide.none,
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(VRadius.input),
            borderSide: BorderSide(
              color: toneBorderColor,
              width: widget.emphasis == VComponentEmphasis.strong ? 1.5 : 1,
            ),
          );

    final defaultEnabledBorder = isInline
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(VRadius.r4),
            borderSide: BorderSide.none,
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(VRadius.input),
            borderSide: BorderSide(
              color: toneBorderColor,
              width: widget.emphasis == VComponentEmphasis.strong ? 1.5 : 1,
            ),
          );

    final defaultFocusedBorder = isInline
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(VRadius.r4),
            borderSide: BorderSide(color: dynamicColors.primary, width: 1.5),
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(VRadius.input),
            borderSide: BorderSide(color: dynamicColors.primary, width: 2),
          );

    // If counter is active, we need extra bottom padding so the text scrolls/wraps above the counter
    final resolvedContentPadding =
        widget.contentPadding ??
        ((widget.showCounter && widget.maxLength != null && !isInline)
            ? EdgeInsets.only(
                left: context.vDensity.fieldHorizontalPadding,
                right: context.vDensity.fieldHorizontalPadding,
                top: context.vDensity.fieldVerticalPadding,
                bottom: context.vDensity.fieldVerticalPadding + 16,
              )
            : defaultContentPadding);

    return FormField<String>(
      initialValue: widget.initialValue,
      validator: widget.validator,
      onSaved: widget.onSaved,
      autovalidateMode: widget.autovalidateMode,
      builder: (FormFieldState<String> fieldState) {
        final hasValidationError = fieldState.hasError;
        final displayErrorText = hasValidationError ? fieldState.errorText : widget.errorText;

        final InputBorder activeBorder;
        if (displayErrorText != null) {
          activeBorder = OutlineInputBorder(
            borderRadius: BorderRadius.circular(isInline ? VRadius.r4 : VRadius.input),
            borderSide: BorderSide(color: dynamicColors.danger, width: hasValidationError ? 2 : 1),
          );
        } else {
          activeBorder = widget.border ?? defaultBorder;
        }

        final textFieldWidget = TextField(
          controller: _effectiveController,
          enabled: isEnabled,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          textAlignVertical: TextAlignVertical.top,
          onChanged: (val) {
            fieldState.didChange(val);
            if (widget.onChanged != null) {
              widget.onChanged!(val);
            }
          },
          autofocus: widget.autofocus,
          focusNode: widget.focusNode,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          inputFormatters: widget.inputFormatters,
          textAlign: widget.textAlign,
          onSubmitted: widget.onFieldSubmitted,
          style: widget.textStyle ?? defaultStyle,
          onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: VTypography.bodyDefault.copyWith(
              color: dynamicColors.textMuted,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIconConstraints:
                widget.suffixIconConstraints ??
                (widget.suffixIcon != null
                    ? null
                    : const BoxConstraints(minWidth: 0, minHeight: 0)),
            suffixIcon:
                widget.suffixIcon ??
                (widget.suffixText != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              right: isInline ? VSpacing.space2 : VSpacing.space4,
                            ),
                            child: VText(
                              widget.suffixText!,
                              variant: VTextVariant.bodyDefault,
                              color: dynamicColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : null),
            filled: true,
            fillColor: widget.fillColor ?? defaultFillColor,
            contentPadding: resolvedContentPadding,
            border: activeBorder,
            enabledBorder: displayErrorText != null
                ? activeBorder
                : (widget.enabledBorder ?? defaultEnabledBorder),
            focusedBorder: displayErrorText != null
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(isInline ? VRadius.r4 : VRadius.input),
                    borderSide: BorderSide(color: dynamicColors.danger, width: 2),
                  )
                : (widget.focusedBorder ?? defaultFocusedBorder),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isInline ? VRadius.r4 : VRadius.input),
              borderSide: BorderSide(color: dynamicColors.borderDefault),
            ),
          ),
        );

        Widget fieldBox = textFieldWidget;

        // Overlay the character counter at the absolute bottom-right corner inside the field box
        if (widget.showCounter && widget.maxLength != null && !isInline) {
          fieldBox = Stack(
            children: [
              textFieldWidget,
              Positioned(
                right: 12,
                bottom: 8,
                child: IgnorePointer(
                  child: VText(
                    '$_currentLength/${widget.maxLength}',
                    variant: VTextVariant.bodySmall,
                    color: dynamicColors.textSecondary,
                  ),
                ),
              ),
            ],
          );
        }

        // Layout label, field box, and validation error message
        final mainWidget = isInline
            ? Semantics(
                textField: true,
                enabled: isEnabled,
                label: widget.semanticLabel ?? widget.label ?? widget.hintText ?? 'Text form field',
                child: fieldBox,
              )
            : Semantics(
                textField: true,
                enabled: isEnabled,
                label: widget.semanticLabel ?? widget.label ?? widget.hintText ?? 'Text form field',
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
                                color: dynamicColors.textPrimary,
                              ),
                            ),
                            if (widget.isRequired)
                              TextSpan(
                                text: ' *',
                                style: TextStyle(color: dynamicColors.danger),
                              ),
                          ],
                        ),
                      ),
                      const VGap.sm(),
                    ],
                    fieldBox,
                    if (displayErrorText != null) ...[
                      const VGap.xs(),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: VText(
                          displayErrorText,
                          variant: VTextVariant.bodySmall,
                          color: dynamicColors.danger,
                        ),
                      ),
                    ] else if (widget.helperText != null) ...[
                      const VGap.xs(),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: VText(
                          widget.helperText!,
                          variant: VTextVariant.bodySmall,
                          color: dynamicColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              );

        return mainWidget;
      },
    );
  }
}
