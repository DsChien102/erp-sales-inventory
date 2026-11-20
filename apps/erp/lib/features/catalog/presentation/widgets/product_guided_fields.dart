import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';
import '../../logic/product_guided_create_cubit.dart';

class ProductGuidedFields {
  static Widget buildLabel(BuildContext context, String label) {
    final dynamicColors = context.vColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.space1, left: VSpacing.space1),
      child: VText(
        label,
        variant: VTextVariant.bodySmall,
        color: dynamicColors.textSecondary,
        style: const TextStyle(fontWeight: FontWeight.bold),
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
      errorStyle: VTypography.bodySmall.copyWith(color: dynamicColors.danger),
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
        borderSide: BorderSide(color: dynamicColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VRadius.button),
        borderSide: BorderSide(color: dynamicColors.danger),
      ),
    );
  }

  static Widget buildNavigationButtons(
    BuildContext context, {
    required bool showSkip,
    bool showNext = true,
    VoidCallback? onSkip,
    VoidCallback? onNext,
    Key? skipKey,
    Key? nextKey,
  }) {
    final dynamicColors = context.vColors;
    final cubit = context.read<ProductGuidedCreateCubit>();
    final state = cubit.state;
    final isLastStep = state.activeStepIndex == state.stepCount - 1;

    final actualShowSkip = isLastStep ? false : showSkip;
    final actualShowNext = isLastStep ? false : showNext;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (actualShowSkip)
          TextButton(
            key: skipKey,
            onPressed: onSkip ?? cubit.nextStep,
            child: VText(
              'Bỏ qua',
              variant: VTextVariant.bodyDefault,
              color: dynamicColors.textSecondary,
            ),
          )
        else
          const SizedBox.shrink(),
        if (actualShowNext)
          VButton(
            key: nextKey,
            label: 'Tiếp',
            onPressed: onNext ?? cubit.nextStep,
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
