import 'package:flutter/material.dart';

import '../../components/v_checkbox.dart';
import '../../foundation/v_context_extensions.dart';
import '../../tokens/v_borders.dart';
import '../../tokens/v_radius.dart';
import '../../tokens/v_spacing.dart';
import '../../tokens/v_typography.dart';
import '../models/v_choice_option.dart';

class VChoiceListTile<T> extends StatelessWidget {
  const VChoiceListTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.allowMultiple,
    required this.enabled,
    required this.hasError,
    required this.onChanged,
  });

  final VChoiceOption<T> option;
  final bool isSelected;
  final bool allowMultiple;
  final bool enabled;
  final bool hasError;
  final ValueChanged<bool> onChanged;

  bool get isInteractive => enabled && !option.disabled;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final child = option.childBuilder?.call(isSelected);

    Widget control;
    if (allowMultiple) {
      control = VCheckbox(
        value: isSelected,
        onChanged: isInteractive ? (val) => onChanged(val ?? false) : (_) {},
      );
    } else {
      control = Radio<T>(
        value: option.value,
      );
    }

    return Semantics(
      checked: isSelected,
      enabled: isInteractive,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VRadius.input),
          border: hasError
              ? VBorders.all(dynamicColors.danger.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: isInteractive ? () => onChanged(!isSelected) : null,
              borderRadius: BorderRadius.circular(VRadius.input),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: VSpacing.space2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IgnorePointer(
                      ignoring: true,
                      child: control,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.label,
                            style: VTypography.bodyDefault.copyWith(
                              color: isInteractive
                                  ? dynamicColors.textPrimary
                                  : dynamicColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (option.helpText != null) ...[
                            const SizedBox(height: VSpacing.space1),
                            Text(
                              option.helpText!,
                              style: VTypography.bodySmall.copyWith(
                                color: dynamicColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (child != null)
              Padding(
                padding: const EdgeInsets.only(
                  left: 40,
                  top: VSpacing.space2,
                  bottom: VSpacing.space1,
                ),
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}
