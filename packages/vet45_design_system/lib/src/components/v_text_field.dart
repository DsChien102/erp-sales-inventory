import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_component_contracts.dart';
import '../primitives/v_text.dart';
import '../patterns/v_gap.dart';

enum VTextFieldVariant { standard, inline }

class VTextField extends StatelessWidget {
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
  final ValueChanged<String>? onSubmitted;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final bool isDense;
  final VTextFieldVariant variant;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final VComponentState state;
  final String? semanticLabel;

  const VTextField({
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
    this.onSubmitted,
    this.contentPadding,
    this.fillColor,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.isDense = false,
    this.variant = VTextFieldVariant.standard,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.state = VComponentState.enabled,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isInline = variant == VTextFieldVariant.inline;

    final bool isEnabled = enabled && state != VComponentState.disabled;
    final Color toneBorderColor = switch (tone) {
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
              width: emphasis == VComponentEmphasis.strong ? 1.5 : 1,
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
              width: emphasis == VComponentEmphasis.strong ? 1.5 : 1,
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

    final textFieldWidget = TextField(
      controller: controller,
      enabled: isEnabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      autofocus: autofocus,
      focusNode: focusNode,
      minLines: minLines,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      textAlign: textAlign,
      onSubmitted: onSubmitted,
      style: textStyle ?? defaultStyle,
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        hintText: hintText,
        isDense: isDense || isInline,
        hintStyle: VTypography.bodyDefault.copyWith(
          color: dynamicColors.textMuted,
        ),
        prefixIcon: prefixIcon,
        suffixIconConstraints:
            suffixIconConstraints ??
            (suffixIcon != null ? null : const BoxConstraints(minWidth: 0, minHeight: 0)),
        suffixIcon:
            suffixIcon ??
            (suffixText != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          right: isInline ? VSpacing.space2 : VSpacing.space4,
                        ),
                        child: VText(
                          suffixText!,
                          variant: VTextVariant.bodyDefault,
                          color: dynamicColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : null),
        filled: true,
        fillColor: fillColor ?? defaultFillColor,
        contentPadding: contentPadding ?? defaultContentPadding,
        border: border ?? defaultBorder,
        enabledBorder: enabledBorder ?? defaultEnabledBorder,
        focusedBorder: focusedBorder ?? defaultFocusedBorder,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isInline ? VRadius.r4 : VRadius.input,
          ),
          borderSide: BorderSide(color: dynamicColors.borderDefault),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isInline ? VRadius.r4 : VRadius.input,
          ),
          borderSide: BorderSide(color: dynamicColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isInline ? VRadius.r4 : VRadius.input,
          ),
          borderSide: BorderSide(color: dynamicColors.danger, width: 2),
        ),
        errorText: errorText,
        errorStyle: VTypography.bodySmall.copyWith(color: dynamicColors.danger),
        helperText: errorText == null ? helperText : null,
        helperStyle: VTypography.bodySmall.copyWith(
          color: dynamicColors.textSecondary,
        ),
      ),
    );

    if (isInline || label == null) {
      return Semantics(
        textField: true,
        enabled: isEnabled,
        label: semanticLabel ?? label ?? hintText ?? 'Text field',
        child: textFieldWidget,
      );
    }

    return Semantics(
      textField: true,
      enabled: isEnabled,
      label: semanticLabel ?? label ?? hintText ?? 'Text field',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label!,
                    style: VTypography.headingH4.copyWith(
                      color: dynamicColors.textPrimary,
                    ),
                  ),
                  if (isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: dynamicColors.danger),
                    ),
                ],
              ),
            ),
            const VGap.sm(),
          ],
          textFieldWidget,
        ],
      ),
    );
  }
}
