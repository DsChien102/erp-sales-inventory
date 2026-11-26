import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/validation/password_policy.dart';
import 'package:erp/core/widgets/flow/resend_countdown.dart';
import 'package:flutter/material.dart';

const _resetSteps = ['Xác minh email', 'Tạo mật khẩu mới'];

/// Bước 1 Đặt lại mật khẩu trên khổ hẹp (prototype `app/reset.js` `verifyStep`).
class ResetVerifyNarrow extends StatelessWidget {
  const ResetVerifyNarrow({
    super.key,
    required this.maskedEmail,
    required this.codeField,
    required this.canSubmit,
    required this.remaining,
    required this.onVerify,
    required this.onResend,
  });

  final String maskedEmail;
  final Widget codeField;
  final bool canSubmit;
  final Duration remaining;
  final VoidCallback onVerify;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VStepProgress(
                    titles: _resetSteps,
                    currentIndex: 0,
                    variant: VStepProgressVariant.mobile,
                  ),
                  const VGap.lg(),
                  Semantics(
                    header: true,
                    child: VText(
                      'Xác minh email',
                      variant: VTextVariant.headingH2,
                      color: colors.textPrimary,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const VGap.xs(),
                  Text.rich(
                    TextSpan(
                      style: VTypography.bodyDefault.copyWith(
                        color: colors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Mã 6 chữ số đã được gửi tới '),
                        TextSpan(
                          text: maskedEmail,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                        const TextSpan(
                          text: '. Xác nhận mã để tạo mật khẩu mới.',
                        ),
                      ],
                    ),
                  ),
                  const VGap.lg(),
                  codeField,
                  const VGap.sm(),
                  VText(
                    'Mã chỉ sử dụng một lần và hết hạn sau 10 phút.',
                    variant: VTextVariant.bodySmall,
                    color: colors.textSecondary,
                  ),
                  const VGap.lg(),
                  VButton(
                    label: 'Xác nhận mã',
                    variant: VButtonVariant.primary,
                    tone: VComponentTone.primary,
                    fullWidth: true,
                    onPressed: canSubmit ? onVerify : null,
                  ),
                  ResendCountdown(remaining: remaining, onResend: onResend),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bước 2 Đặt lại mật khẩu trên khổ hẹp (prototype `app/reset.js` `createStep`).
class ResetCreateNarrow extends StatelessWidget {
  const ResetCreateNarrow({
    super.key,
    required this.newPasswordField,
    required this.confirmPasswordField,
  });

  final Widget newPasswordField;
  final Widget confirmPasswordField;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const VStepProgress(
                    titles: _resetSteps,
                    currentIndex: 1,
                    variant: VStepProgressVariant.mobile,
                  ),
                  const VGap.lg(),
                  Semantics(
                    header: true,
                    child: VText(
                      'Tạo mật khẩu mới',
                      variant: VTextVariant.headingH2,
                      color: colors.textPrimary,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const VGap.md(),
                  newPasswordField,
                  const VGap.md(),
                  confirmPasswordField,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
