import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

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
        VText(
          'Tạo mật khẩu mới',
          variant: VTextVariant.headingH3,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const VGap.md(),
        VPasswordField(
          label: 'Mật khẩu mới',
          isRequired: true,
          hintText: '••••••••••••',
          controller: newPasswordController,
          errorText: newPasswordError,
          onChanged: (_) => onChanged(),
        ),
        const VGap.md(),
        VPasswordField(
          label: 'Nhập lại mật khẩu mới',
          isRequired: true,
          hintText: '••••••••••••',
          controller: confirmPasswordController,
          errorText: confirmPasswordError,
          onChanged: (_) => onChanged(),
        ),
        const VGap.lg(),
        VCard(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                'Quy tắc mật khẩu',
                variant: VTextVariant.headingH4,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const VGap.xs(),
              VText(
                'Tối thiểu 8 ký tự, gồm chữ hoa, chữ thường và số.',
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
