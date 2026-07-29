import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Step 1 — enter 6-digit verification code.
class ResetPasswordVerifyCodeStep extends StatelessWidget {
  const ResetPasswordVerifyCodeStep({
    super.key,
    required this.emailMasked,
    required this.codeController,
    required this.secondsRemaining,
    required this.isVerifying,
    required this.onCodeChanged,
    required this.onVerify,
    required this.onResend,
  });

  final String emailMasked;
  final TextEditingController codeController;
  final int secondsRemaining;
  final bool isVerifying;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback? onVerify;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isCodeValid = codeController.text.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      children: [
        VCard(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                'Xác minh email',
                variant: VTextVariant.headingH4,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const VGap.xs(),
              VText(
                'Mã 6 chữ số đã được gửi tới $emailMasked. Xác nhận mã để tạo mật khẩu mới.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
        const VGap.lg(),
        VTextField(
          label: 'Mã xác nhận',
          isRequired: true,
          hintText: '12345',
          keyboardType: TextInputType.number,
          controller: codeController,
          onChanged: onCodeChanged,
        ),
        const VGap.lg(),
        VButton(
          label: 'Xác nhận mã',
          variant: VButtonVariant.primary,
          tone: VComponentTone.primary,
          fullWidth: true,
          onPressed: isCodeValid && !isVerifying ? onVerify : null,
        ),
        const VGap.sm(),
        VButton(
          label: secondsRemaining > 0
              ? 'Gửi lại mã sau 00:${secondsRemaining.toString().padLeft(2, '0')}'
              : 'Gửi lại mã',
          variant: VButtonVariant.outline,
          fullWidth: true,
          onPressed: secondsRemaining == 0 ? onResend : null,
        ),
        const VGap.md(),
        VText(
          'Mã chỉ sử dụng một lần và hết hạn sau 10 phút.',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
      ],
    );
  }
}
