import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/validation/password_policy.dart';

/// Step 2 — create new password after code verified.
class ResetPasswordCreatePasswordStep extends StatelessWidget {
  const ResetPasswordCreatePasswordStep({
    super.key,
    required this.newPasswordController,
    required this.confirmPasswordController,
    this.newPasswordError,
    this.confirmPasswordError,
    required this.onChanged,
  });

  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final String? newPasswordError;
  final String? confirmPasswordError;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      children: [
        Semantics(
          header: true,
          child: VText(
            'Tạo mật khẩu mới',
            variant: VTextVariant.headingH3,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const VGap.md(),
        VField(
          invalid: newPasswordError != null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VFieldLabel('Mật khẩu mới', isRequired: true),
              VPasswordField(
                hintText: '••••••••••••',
                controller: newPasswordController,
                onChanged: (_) => onChanged(),
              ),
              if (newPasswordError != null)
                VFieldError(newPasswordError!),
            ],
          ),
        ),
        const VGap.md(),
        VField(
          invalid: confirmPasswordError != null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VFieldLabel('Nhập lại mật khẩu mới', isRequired: true),
              VPasswordField(
                hintText: '••••••••••••',
                controller: confirmPasswordController,
                onChanged: (_) => onChanged(),
              ),
              if (confirmPasswordError != null)
                VFieldError(confirmPasswordError!),
            ],
          ),
        ),
        const VGap.lg(),
        VCard(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: VText(
                  'Quy tắc mật khẩu',
                  variant: VTextVariant.headingH4,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const VGap.xs(),
              VText(
                PasswordPolicy.requirementText,
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
