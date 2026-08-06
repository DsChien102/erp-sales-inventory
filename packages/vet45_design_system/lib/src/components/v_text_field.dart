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
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import 'v_text_field_affix.dart';
import 'v_text_field_focus_ring.dart';

class VTextField extends StatefulWidget {
  /// Default inset — horizontal [VSpacing.space3], vertical [VSpacing.space2].
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: VSpacing.space3,
    vertical: VSpacing.space2,
  );

  /// Dense inset — horizontal [VSpacing.space2], vertical [VSpacing.space1].
  static const EdgeInsets densePadding = EdgeInsets.symmetric(
    horizontal: VSpacing.space2,
    vertical: VSpacing.space1,
  );

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
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  /// When false, field has no outline ([InputBorder.none]). Default true.
  final bool border;
  final bool isDense;
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
    this.inputFormatters,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.focusNode,
    this.onSubmitted,
    this.border = true,
    this.isDense = false,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.state = VComponentState.enabled,
    this.semanticLabel,
  });

  @override
  State<VTextField> createState() => _VTextFieldState();
}

class _VTextFieldState extends State<VTextField> {
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant VTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _ownedFocusNode?.removeListener(_handleFocusChange);
      if (widget.focusNode == null) {
        _ownedFocusNode ??= FocusNode();
      } else {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  InputBorder _outline(Color color, double width) {
    if (!widget.border) return InputBorder.none;
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
            color: hasError ? colors.danger : colors.textSecondary,
            iconSize: VIconSize.sm,
          ),
          const VGap.horizontalXs(),
          VText(
            text,
            variant: VTextVariant.bodySmall,
            color: hasError ? colors.danger : colors.textSecondary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isEnabled = widget.enabled && widget.state != VComponentState.disabled;
    final hasError = widget.errorText != null;
    final useDanger = hasError || widget.tone == VComponentTone.danger;
    final focused = isEnabled && _focusNode.hasFocus;
    final isDense = widget.isDense;
    final borderWidth = VBorders.widthFor(widget.emphasis);

    final restingBorderColor = hasError
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

    final resolvedSuffix =
        widget.suffixIcon ??
        (widget.suffixText == null
            ? null
            : VText(
                widget.suffixText!,
                variant: VTextVariant.bodyDefault,
                color: colors.textMuted,
              ));

    final affixOuter = isDense ? kVTextFieldAffixOuterDense : kVTextFieldAffixOuter;
    final affixInner = isDense ? kVTextFieldAffixInnerDense : kVTextFieldAffixInner;

    final baseTextStyle =
        widget.textStyle ??
        VTypography.bodyDefault.copyWith(
          color: isEnabled ? colors.textPrimary : colors.textSecondary,
        );

    final field = TextField(
      controller: widget.controller,
      enabled: isEnabled,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      autofocus: widget.autofocus,
      focusNode: _focusNode,
      maxLines: 1,
      inputFormatters: widget.inputFormatters,
      textAlign: widget.textAlign,
      onSubmitted: widget.onSubmitted,
      cursorColor: useDanger ? colors.danger : colors.primary,
      style: hasError ? baseTextStyle.copyWith(color: colors.danger) : baseTextStyle,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        hintText: widget.hintText,
        isDense: isDense,
        hintStyle: VTypography.bodyDefault.copyWith(
          color: colors.textMuted,
          fontWeight: FontWeight.w500,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        prefixIcon: wrapVTextFieldAffix(
          widget.prefixIcon,
          outerInset: affixOuter,
          innerInset: affixInner,
          isLeading: true,
        ),
        suffixIconConstraints:
            widget.suffixIconConstraints ?? const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: wrapVTextFieldAffix(
          resolvedSuffix,
          outerInset: affixOuter,
          innerInset: affixInner,
          isLeading: false,
        ),
        filled: true,
        fillColor: isEnabled ? colors.surface : colors.surfaceAlt,
        hoverColor: Colors.transparent,
        contentPadding: vTextFieldContentPadding(
          base: isDense ? VTextField.densePadding : VTextField.padding,
          hasPrefix: widget.prefixIcon != null,
          hasSuffix: resolvedSuffix != null,
        ),
        border: restingBorder,
        enabledBorder: restingBorder,
        focusedBorder: focusBorder,
        disabledBorder: disabledBorder,
        // Keep error chrome on the input only; message is rendered below the ring.
        errorBorder: dangerBorder,
        focusedErrorBorder: dangerBorder,
      ),
    );

    final message = _message(colors, hasError: hasError);

    return Semantics(
      textField: true,
      enabled: isEnabled,
      label: widget.semanticLabel ?? widget.label ?? widget.hintText ?? 'Text field',
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
          VTextFieldFocusRing(
            focused: focused,
            danger: useDanger,
            child: field,
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
