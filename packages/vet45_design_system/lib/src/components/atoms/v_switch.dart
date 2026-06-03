import 'package:flutter/material.dart';
import '../../tokens/v_typography.dart';
import '../../utils/v_context_extensions.dart';

class VSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  const VSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    Widget toggle = Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: dynamicColors.primary,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: dynamicColors.borderStrong,
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    );

    if (label != null) {
      return InkWell(
        onTap: onChanged != null ? () => onChanged!(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label!,
                  style: VTypography.bodyDefault.copyWith(
                    color: dynamicColors.textPrimary,
                  ),
                ),
              ),
              toggle,
            ],
          ),
        ),
      );
    }

    return toggle;
  }
}
