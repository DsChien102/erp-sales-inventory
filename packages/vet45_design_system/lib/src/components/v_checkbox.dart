import 'package:flutter/material.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';

class VCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? label;

  const VCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    Widget checkbox = Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: dynamicColors.primary,
      checkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.r4),
      ),
      side: BorderSide(
        color: dynamicColors.borderStrong,
        width: 1.5,
      ),
    );

    if (label != null) {
      return InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(VRadius.r4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              checkbox,
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

    return checkbox;
  }
}
