import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Step 1 — enter 6-digit verification code.
class ResetPasswordVerifyCodeStep extends StatelessWidget {
  const ResetPasswordVerifyCodeStep({
    super.key,
    required this.emailMasked,
    required this.code,
    required this.secondsRemaining,
    required this.isVerifying,
    required this.onCodeChanged,
    required this.onVerify,
    required this.onResend,
    this.errorText,
  });

  final String emailMasked;
  final String code;
  final int secondsRemaining;
  final bool isVerifying;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback? onVerify;
  final VoidCallback? onResend;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isCodeValid = RegExp(r'^\d{6}$').hasMatch(code);

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
        VVerificationCodeField(
          length: 6,
          charset: VVerificationCodeCharset.numeric,
          label: 'Mã xác nhận',
          isRequired: true,
          autofocus: true,
          enabled: !isVerifying,
          errorText: errorText,
          onChanged: onCodeChanged,
          onCompleted: (_) => onVerify?.call(),
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
