import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import 'role_radio_list.dart';

class RoleRadioGrid extends StatelessWidget {
  const RoleRadioGrid({
    super.key,
    required this.roles,
    required this.value,
    required this.onChanged,
    this.invalid = false,
  });

  final List<RoleChoice> roles;
  final String? value;
  final ValueChanged<String>? onChanged;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;

    return RadioGroup<String>(
      groupValue: value,
      onChanged: (next) {
        if (enabled && next != null) {
          onChanged!(next);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoCols = constraints.maxWidth >= 560;
          final itemWidth = twoCols
              ? (constraints.maxWidth - 8) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in roles)
                SizedBox(
                  width: itemWidth,
                  child: _RoleGridOption(
                    choice: choice,
                    isSelected: choice.id == value,
                    invalid: invalid,
                    enabled: enabled,
                    onTap: enabled && !choice.isCurrent
                        ? () => onChanged!(choice.id)
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RoleGridOption extends StatelessWidget {
  const _RoleGridOption({
    required this.choice,
    required this.isSelected,
    required this.invalid,
    required this.enabled,
    this.onTap,
  });

  final RoleChoice choice;
  final bool isSelected;
  final bool invalid;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final borderColor = isSelected
        ? colors.primary
        : (invalid ? colors.danger : colors.borderStrong);
    final bgColor = isSelected ? colors.surfaceBrand : colors.surface;

    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(VRadius.r8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VRadius.r8),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.space4,
              vertical: VSpacing.space3,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VRadius.r8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // `.t1-radio-hit` 20 × 20; cả thẻ là vùng bấm.
                SizedBox.square(
                  dimension: 20,
                  child: Radio<String>(
                    value: choice.id,
                    enabled: enabled,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        choice.title,
                        variant: VTextVariant.bodyDefault,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (choice.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        VText(
                          choice.description,
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
