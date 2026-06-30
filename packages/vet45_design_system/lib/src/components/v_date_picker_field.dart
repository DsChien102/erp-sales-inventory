import 'package:flutter/material.dart';
import '../tokens/v_colors.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_context_extensions.dart';

class VDatePickerField extends StatelessWidget {
  final DateTime? value;
  final String label;
  final String hintText;
  final bool required;
  final VoidCallback onTap;

  const VDatePickerField({
    super.key,
    required this.value,
    required this.label,
    this.hintText = 'nn/mm/yyyy',
    this.required = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final dateText = value != null
        ? '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'
        : hintText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: dynamicColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: VTypography.bodyDefault.copyWith(
                color: dynamicColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: VColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VRadius.input),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4),
            decoration: BoxDecoration(
              color: dynamicColors.background,
              border: Border.all(color: dynamicColors.borderDefault),
              borderRadius: BorderRadius.circular(VRadius.input),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dateText,
                    style: VTypography.bodyDefault.copyWith(
                      color: value != null ? dynamicColors.textPrimary : dynamicColors.textMuted,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_month_rounded,
                  size: 20,
                  color: dynamicColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
