import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/v_colors.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';

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
  final VTextFieldVariant variant;

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
    this.variant = VTextFieldVariant.standard,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isInline = variant == VTextFieldVariant.inline;

    final defaultStyle = isInline
        ? VTypography.bodyDefault.copyWith(
            color: enabled ? dynamicColors.textPrimary : dynamicColors.textSecondary,
            fontWeight: FontWeight.w700,
          )
        : VTypography.bodyDefault.copyWith(
            color: enabled ? dynamicColors.textPrimary : dynamicColors.textSecondary,
          );

    final defaultContentPadding = isInline
        ? const EdgeInsets.symmetric(vertical: 6)
        : const EdgeInsets.symmetric(
            horizontal: VSpacing.space4,
            vertical: VSpacing.space3,
          );

    final defaultFillColor = isInline
        ? dynamicColors.background
        : (enabled ? dynamicColors.surface : dynamicColors.surfaceAlt);

    final defaultBorder = isInline
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(VRadius.r4),
            borderSide: BorderSide.none,
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(VRadius.input),
            borderSide: BorderSide(color: dynamicColors.borderStrong),
          );

    final defaultEnabledBorder = isInline
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(VRadius.r4),
            borderSide: BorderSide.none,
          )
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(VRadius.input),
            borderSide: BorderSide(color: dynamicColors.borderStrong),
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
      enabled: enabled,
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
                        child: Text(
                          suffixText!,
                          style: VTypography.bodyDefault.copyWith(
                            color: dynamicColors.textSecondary,
                          ),
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
          borderSide: const BorderSide(color: VColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            isInline ? VRadius.r4 : VRadius.input,
          ),
          borderSide: const BorderSide(color: VColors.danger, width: 2),
        ),
        errorText: errorText,
        errorStyle: VTypography.bodySmall.copyWith(color: VColors.danger),
        helperText: errorText == null ? helperText : null,
        helperStyle: VTypography.bodySmall.copyWith(
          color: dynamicColors.textSecondary,
        ),
      ),
    );

    if (isInline) {
      return textFieldWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          RichText(
            text: TextSpan(
              style: VTypography.headingH4.copyWith(
                color: enabled ? dynamicColors.textPrimary : dynamicColors.textMuted,
              ),
              children: [
                TextSpan(text: label!),
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: VColors.danger),
                  ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.space2),
        ],
        textFieldWidget,
      ],
    );
  }
}
