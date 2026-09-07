import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import 'v_text_area.dart';

/// Deprecated alias of [VTextArea]. Prefer [VTextArea] for new code.
@Deprecated('Use VTextArea instead')
class VTextFormField extends VTextArea {
  /// Floor for [minLines] — cannot render shorter than this.
  static const int defaultMinLines = VTextArea.defaultMinLines;

  /// Multiline inset — see [VTextArea.padding].
  static const EdgeInsets padding = VTextArea.padding;

  /// Dense multiline inset — see [VTextArea.densePadding].
  static const EdgeInsets densePadding = VTextArea.densePadding;

  @Deprecated('Use VTextArea instead')
  const VTextFormField({
    super.key,
    super.controller,
    @Deprecated('Use VField + VFieldLabel instead') super.label,
    super.hintText,
    @Deprecated('Use VFieldDescription instead') super.helperText,
    @Deprecated(
      'Use VField(invalid: true) + VFieldError for message; keep error chrome via tone/domain',
    )
    super.errorText,
    super.prefixIcon,
    super.suffixIcon,
    super.suffixIconConstraints,
    super.suffixText,
    super.enabled,
    super.obscureText = false,
    super.keyboardType,
    super.onChanged,
    @Deprecated('Use VFieldLabel(..., isRequired: true) instead')
    super.isRequired = false,
    super.minLines = defaultMinLines,
    super.maxLines,
    super.inputFormatters,
    super.textStyle,
    super.textAlign = TextAlign.start,
    super.autofocus = false,
    super.focusNode,
    super.onFieldSubmitted,
    super.border = true,
    super.isDense = false,
    super.tone = VComponentTone.neutral,
    super.emphasis = VComponentEmphasis.medium,
    super.semanticLabel,
    super.validator,
    super.onSaved,
    super.initialValue,
    super.autovalidateMode,
    super.maxLength,
    super.maxLengthEnforcement,
    super.showCounter = true,
  });
}
