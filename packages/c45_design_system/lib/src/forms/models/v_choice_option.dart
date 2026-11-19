import 'package:flutter/material.dart';

/// A single option within [VChoiceList].
class VChoiceOption<T> {
  const VChoiceOption({
    required this.value,
    required this.label,
    this.helpText,
    this.disabled = false,
    this.childBuilder,
  });

  final T value;
  final String label;
  final String? helpText;
  final bool disabled;

  /// Polaris-style `renderChildren`: only rendered when the option is selected.
  final Widget Function(bool isSelected)? childBuilder;
}
