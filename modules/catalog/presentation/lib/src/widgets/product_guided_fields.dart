import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/product_guided_create_cubit.dart';

class ProductGuidedFields {
  static Widget buildLabel(BuildContext context, String label) {
    final dynamicColors = context.vColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.space1, left: VSpacing.space1),
      child: Text(
        label,
        style: VTypography.bodySmall.copyWith(
          color: dynamicColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static InputDecoration buildInputDecoration(
    BuildContext context,
    String hintText, {
    String? errorText,
  }) {
    final dynamicColors = context.vColors;
    return InputDecoration(
      hintText: hintText,
      hintStyle: VTypography.bodyDefault.copyWith(color: dynamicColors.textMuted),
      errorText: errorText,
      errorStyle: VTypography.bodySmall.copyWith(color: VColors.danger),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space3,
        vertical: VSpacing.space2,
      ),
      filled: true,
      fillColor: dynamicColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.button),
        borderSide: BorderSide(color: dynamicColors.borderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.button),
        borderSide: BorderSide(color: dynamicColors.borderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.button),
        borderSide: BorderSide(color: dynamicColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.button),
        borderSide: BorderSide(color: VColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.button),
        borderSide: BorderSide(color: VColors.danger),
      ),
    );
  }

  static Widget buildNavigationButtons(
    BuildContext context, {
    required bool showSkip,
    bool showNext = true,
  }) {
    final dynamicColors = context.vColors;
    final cubit = context.read<ProductGuidedCreateCubit>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showSkip)
          TextButton(
            onPressed: cubit.nextStep,
            child: Text(
              'Bỏ qua',
              style: VTypography.bodyDefault.copyWith(color: dynamicColors.textSecondary),
            ),
          )
        else
          const SizedBox.shrink(),
        if (showNext)
          VButton(
            label: 'Tiếp',
            onPressed: cubit.nextStep,
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
