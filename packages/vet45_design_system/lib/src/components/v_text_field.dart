import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../patterns/v_field.dart';
import '../primitives/v_text.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_opacity.dart';
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

  /// Single-line control height shared with [VSelect] / [VCombobox].
  ///
  /// Matches the measured default [TextField] + outlined decoration height under
  /// [VTheme] (Material interactive minimum), so form rows align.
  static const double controlHeight = 48;

  final TextEditingController? controller;

  @Deprecated('Use VField + VFieldLabel instead')
  final String? label;
  final String? hintText;
  @Deprecated('Use VFieldDescription instead')
  final String? helperText;
  @Deprecated(
    'Use VField(invalid: true) + VFieldError for message; keep error chrome via tone/domain',
  )
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final BoxConstraints? suffixIconConstraints;
  final String? suffixText;
  final bool? enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  @Deprecated('Use VFieldLabel(..., isRequired: true) instead')
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
  final String? semanticLabel;

  const VTextField({
    super.key,
    this.controller,
    @Deprecated('Use VField + VFieldLabel instead') this.label,
    this.hintText,
    @Deprecated('Use VFieldDescription instead') this.helperText,
    @Deprecated(
      'Use VField(invalid: true) + VFieldError for message; keep error chrome via tone/domain',
    )
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.suffixText,
    this.enabled,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    @Deprecated('Use VFieldLabel(..., isRequired: true) instead') this.isRequired = false,
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
    final useDanger = hasError || widget.tone == VComponentTone.danger;
    final focused = isEnabled && _focusNode.hasFocus;
    final isDense = widget.isDense;
    final borderWidth = VBorders.widthFor(widget.emphasis);

    final restingBorderColor = hasError
        ? colors.danger
        : switch (widget.tone) {
            VComponentTone.primary => colors.primary,
            VComponentTone.danger => colors.danger,
            _ => colors.borderDefault,
          };
    final focusBorderColor = useDanger ? colors.danger : colors.primary;
    final restingBorder = _outline(restingBorderColor, borderWidth);
    final focusBorder = _outline(focusBorderColor, borderWidth);
    final dangerBorder = _outline(colors.danger, borderWidth);
    final disabledBorder = _outline(colors.borderDefault, borderWidth);

    final resolvedSuffix =
        widget.suffixIcon != null
            ? vInspectorShow(widget.suffixIcon!)
            : (widget.suffixText == null
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
          color: colors.textPrimary,
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
          widget.prefixIcon != null ? vInspectorShow(widget.prefixIcon!) : null,
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
        fillColor: colors.surface,
        hoverColor: Colors.transparent,
        contentPadding: vTextFieldContentPadding(
          base: isDense ? VTextField.densePadding : VTextField.padding,
          hasPrefix: widget.prefixIcon != null,
          hasSuffix: resolvedSuffix != null,
        ),
        constraints: isDense
            ? null
            : const BoxConstraints(
                minHeight: VTextField.controlHeight,
                maxHeight: VTextField.controlHeight,
              ),
        border: restingBorder,
        enabledBorder: restingBorder,
        focusedBorder: focusBorder,
        disabledBorder: disabledBorder,
        errorBorder: dangerBorder,
        focusedErrorBorder: dangerBorder,
      ),
    );

    final control = VTextFieldFocusRing(
      focused: focused,
      danger: useDanger,
      child: field,
    );

    final useShell =
        legacyLabel != null || legacyHelper != null || legacyError != null || legacyRequired;

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
        label: widget.semanticLabel ?? legacyLabel ?? widget.hintText ?? 'Text field',
        child: vDisabledOpacity(enabled: isEnabled, child: body),
      ),
    );
  }
}
