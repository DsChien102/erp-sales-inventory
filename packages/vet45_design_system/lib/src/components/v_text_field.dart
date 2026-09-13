import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../foundation/v_component_contracts.dart';
import '../foundation/v_component_scope.dart';
import '../foundation/v_context_extensions.dart';
import '../foundation/v_inspector_scope.dart';
import '../patterns/v_field.dart';
import '../primitives/v_text.dart';
import '../tokens/v_opacity.dart';
import 'v_input.dart';
import 'v_text_field_focus_ring.dart';

class VTextField extends StatefulWidget {
  /// Default inset — horizontal [VSpacing.space3], vertical [VSpacing.space2].
  static const EdgeInsets padding = VInput.defaultPadding;

  /// Dense inset — horizontal [VSpacing.space2], vertical [VSpacing.space1].
  static const EdgeInsets densePadding = VInput.densePadding;

  /// Single-line control height shared with [VSelect] / [VCombobox].
  ///
  /// Matches the measured default [TextField] + outlined decoration height under
  /// [VTheme] (Material interactive minimum), so form rows align.
  static const double controlHeight = VInput.controlHeight;

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

  /// Local invalid override. Null inherits [VField.invalid].
  ///
  /// Legacy [errorText] still forces invalid chrome when non-null.
  final bool? invalid;
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
    this.invalid,
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
    final isInvalid =
        VField.resolveInvalid(context, local: widget.invalid) || hasError;
    final useDanger = isInvalid || widget.tone == VComponentTone.danger;
    final focused = isEnabled && _focusNode.hasFocus;

    final suffix =
        widget.suffixIcon ??
        (widget.suffixText == null
            ? null
            : VText(
                widget.suffixText!,
                variant: VTextVariant.bodyDefault,
                color: colors.textMuted,
              ));

    final field = VInput(
      controller: widget.controller,
      focusNode: _focusNode,
      hintText: widget.hintText,
      prefix: widget.prefixIcon,
      suffix: suffix,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      inputFormatters: widget.inputFormatters,
      textStyle: widget.textStyle,
      textAlign: widget.textAlign,
      autofocus: widget.autofocus,
      onSubmitted: widget.onSubmitted,
      border: widget.border,
      padding: widget.isDense ? VInput.densePadding : VInput.defaultPadding,
      lockControlHeight: !widget.isDense,
      invalid: isInvalid,
      tone: widget.tone,
      emphasis: widget.emphasis,
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
