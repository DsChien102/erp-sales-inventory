import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../tokens/v_typography.dart';

class VRadio<T> extends StatelessWidget {
  const VRadio({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final T value;
  final ValueChanged<T?>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final registry = RadioGroup.maybeOf<T>(context);

    Widget radio = Radio<T>(
      value: value,
    );

    void select() {
      if (onChanged != null) {
        onChanged!(value);
        return;
      }
      registry?.onChanged(value);
    }

    if (label != null) {
      return InkWell(
        onTap: onChanged != null || registry != null ? select : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              radio,
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label!,
                  style: VTypography.bodyDefault.copyWith(
                    color: dynamicColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return radio;
  }
}
