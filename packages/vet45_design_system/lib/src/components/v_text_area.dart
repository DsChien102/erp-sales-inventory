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

/// Design system multiline text area (FormField).
///
/// Always at least [defaultMinLines] (2). For single-line input use [VTextField].
class VTextArea extends StatefulWidget {
  /// Floor for [minLines] — cannot render shorter than this.
  static const int defaultMinLines = 2;

  /// Multiline inset — horizontal [VSpacing.space3], vertical [VSpacing.space3].
  static const EdgeInsets padding = EdgeInsets.symmetric(
    horizontal: VSpacing.space2,
    vertical: VSpacing.space3,
  );

  /// Dense multiline inset — horizontal [VSpacing.space2], vertical [VSpacing.space2].
  static const EdgeInsets densePadding = EdgeInsets.symmetric(
    horizontal: VSpacing.space1,
    vertical: VSpacing.space2,
  );

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
  final int? minLines;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;

  /// When false, field has no outline ([InputBorder.none]). Default true.
  final bool border;
  final bool isDense;
  final VComponentTone tone;
  final VComponentEmphasis emphasis;
  final String? semanticLabel;

  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final String? initialValue;
  final AutovalidateMode? autovalidateMode;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final bool showCounter;

  const VTextArea({
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
    this.minLines = defaultMinLines,
    this.maxLines,
    this.inputFormatters,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.focusNode,
    this.onFieldSubmitted,
    this.border = true,
    this.isDense = false,
    this.tone = VComponentTone.neutral,
    this.emphasis = VComponentEmphasis.medium,
    this.semanticLabel,
    this.validator,
    this.onSaved,
    this.initialValue,
    this.autovalidateMode,
    this.maxLength,
    this.maxLengthEnforcement,
    this.showCounter = true,
  });

  /// Resolved [minLines], never below [defaultMinLines].
  int get effectiveMinLines {
    final requested = minLines ?? defaultMinLines;
    return requested < defaultMinLines ? defaultMinLines : requested;
  }

  /// Resolved [maxLines], at least [effectiveMinLines] when finite.
  int? get effectiveMaxLines {
    final max = maxLines;
    if (max == null) return null;
    final min = effectiveMinLines;
    return max < min ? min : max;
  }

  @override
  State<VTextArea> createState() => _VTextAreaState();
}

class _VTextAreaState extends State<VTextArea> {
  TextEditingController? _localController;
  FocusNode? _ownedFocusNode;
  int _currentLength = 0;

  TextEditingController get _effectiveController =>
      widget.controller ?? (_localController ??= TextEditingController(text: widget.initialValue));

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    _focusNode.addListener(_onFocusChanged);
    _effectiveController.addListener(_onTextChanged);
    _currentLength = _effectiveController.text.length;
  }

  @override
  void didUpdateWidget(covariant VTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      _ownedFocusNode?.removeListener(_onFocusChanged);
      if (widget.focusNode == null) {
        _ownedFocusNode ??= FocusNode();
      } else {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
      _focusNode.addListener(_onFocusChanged);
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onTextChanged);
      widget.controller?.addListener(_onTextChanged);

      if (widget.controller != null && _localController != null) {
        _localController!.dispose();
        _localController = null;
      }

      _currentLength = _effectiveController.text.length;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _ownedFocusNode?.dispose();
    widget.controller?.removeListener(_onTextChanged);
    _localController?.removeListener(_onTextChanged);
    _localController?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
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
    final colors = context.vColors;
    final isEnabled = VComponentScope.resolveEnabled(context, local: widget.enabled);
    final toneBorderColor = switch (widget.tone) {
      VComponentTone.primary => colors.primary,
      VComponentTone.danger => colors.danger,
      _ => colors.borderDefault,
    };
    final borderWidth = VBorders.widthFor(widget.emphasis);

    final defaultStyle = VTypography.bodyDefault.copyWith(
      color: colors.textPrimary,
    );

    final minLines = widget.effectiveMinLines;
    final maxLines = widget.effectiveMaxLines;
    final basePadding = widget.isDense ? VTextArea.densePadding : VTextArea.padding;
    final contentPadding = widget.showCounter && widget.maxLength != null
        ? basePadding.copyWith(
            bottom: basePadding.bottom + VSpacing.space4,
          )
        : basePadding;

    final showBorder = widget.border;
    const none = InputBorder.none;
    InputBorder outlineOf(Color color, {double? width}) {
      if (!showBorder) return none;
      return VBorders.outlineInput(color, width: width ?? borderWidth);
    }

    final outline = outlineOf(toneBorderColor);
    final focusedOutline = outlineOf(
      switch (widget.tone) {
        VComponentTone.danger => colors.danger,
        VComponentTone.primary => colors.primary,
        _ => colors.primary,
      },
    );
    final disabledOutline = outlineOf(colors.borderDefault);

    return vInspectorHide(
      FormField<String>(
        initialValue: widget.initialValue,
        validator: widget.validator,
        onSaved: widget.onSaved,
        autovalidateMode: widget.autovalidateMode,
        builder: (FormFieldState<String> fieldState) {
          final hasValidationError = fieldState.hasError;
          // ignore: deprecated_member_use_from_same_package
          final legacyError = widget.errorText;
          // ignore: deprecated_member_use_from_same_package
          final legacyHelper = widget.helperText;
          // ignore: deprecated_member_use_from_same_package
          final legacyLabel = widget.label;
          // ignore: deprecated_member_use_from_same_package
          final legacyRequired = widget.isRequired;
          final displayErrorText =
              hasValidationError ? fieldState.errorText : legacyError;

          final InputBorder activeBorder;
          if (!showBorder) {
            activeBorder = none;
          } else if (displayErrorText != null) {
            activeBorder = outlineOf(
              colors.danger,
              width: hasValidationError ? VBorders.thin : borderWidth,
            );
          } else {
            activeBorder = outline;
          }

          final focusedErrorBorder = outlineOf(colors.danger);

          final resolvedSuffix = widget.suffixIcon != null
              ? vInspectorShow(widget.suffixIcon!)
              : (widget.suffixText == null
                    ? null
                    : VText(
                        widget.suffixText!,
                        variant: VTextVariant.bodyDefault,
                        color: colors.textSecondary,
                      ));

          final baseTextStyle = widget.textStyle ?? defaultStyle;
          final textFieldWidget = TextField(
            controller: _effectiveController,
            enabled: isEnabled,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType ?? TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            onChanged: (val) {
              fieldState.didChange(val);
              widget.onChanged?.call(val);
            },
            autofocus: widget.autofocus,
            focusNode: _focusNode,
            minLines: minLines,
            maxLines: maxLines,
            inputFormatters: widget.inputFormatters,
            textAlign: widget.textAlign,
            onSubmitted: widget.onFieldSubmitted,
            cursorColor: displayErrorText != null || widget.tone == VComponentTone.danger
                ? colors.danger
                : colors.primary,
            style: displayErrorText != null
                ? baseTextStyle.copyWith(color: colors.danger)
                : baseTextStyle,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            decoration: InputDecoration(
              hintText: widget.hintText,
              isDense: widget.isDense,
              alignLabelWithHint: true,
              hintStyle: VTypography.bodyDefault.copyWith(color: colors.textMuted),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              prefixIcon: wrapVTextFieldAffix(
                widget.prefixIcon != null ? vInspectorShow(widget.prefixIcon!) : null,
                outerInset: widget.isDense ? kVTextFieldAffixOuterDense : kVTextFieldAffixOuter,
                innerInset: widget.isDense ? kVTextFieldAffixInnerDense : kVTextFieldAffixInner,
                isLeading: true,
              ),
              suffixIconConstraints:
                  widget.suffixIconConstraints ?? const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: wrapVTextFieldAffix(
                resolvedSuffix,
                outerInset: widget.isDense ? kVTextFieldAffixOuterDense : kVTextFieldAffixOuter,
                innerInset: widget.isDense ? kVTextFieldAffixInnerDense : kVTextFieldAffixInner,
                isLeading: false,
              ),
              filled: true,
              fillColor: colors.surface,
              hoverColor: Colors.transparent,
              contentPadding: vTextFieldContentPadding(
                base: contentPadding,
                hasPrefix: widget.prefixIcon != null,
                hasSuffix: resolvedSuffix != null,
              ),
              border: activeBorder,
              enabledBorder: displayErrorText != null ? activeBorder : outline,
              focusedBorder: displayErrorText != null ? focusedErrorBorder : focusedOutline,
              disabledBorder: disabledOutline,
            ),
          );

          final focused = isEnabled && _focusNode.hasFocus;
          Widget fieldBox = VTextFieldFocusRing(
            focused: focused,
            danger: displayErrorText != null,
            child: textFieldWidget,
          );

          if (widget.showCounter && widget.maxLength != null) {
            fieldBox = Stack(
              children: [
                fieldBox,
                Positioned(
                  right: VSpacing.space3,
                  bottom: VSpacing.space2,
                  child: IgnorePointer(
                    child: VText(
                      '$_currentLength/${widget.maxLength}',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            );
          }

          final useShell = legacyLabel != null ||
              legacyHelper != null ||
              displayErrorText != null ||
              legacyRequired;

          final body = useShell
              ? vFieldShell(
                  control: fieldBox,
                  label: legacyLabel,
                  isRequired: legacyRequired,
                  helperText: legacyHelper,
                  errorText: displayErrorText,
                )
              : fieldBox;

          return Semantics(
            textField: true,
            enabled: isEnabled,
            label: widget.semanticLabel ?? legacyLabel ?? widget.hintText ?? 'Text area',
            child: vDisabledOpacity(enabled: isEnabled, child: body),
          );
        },
      ),
    );
  }
}
