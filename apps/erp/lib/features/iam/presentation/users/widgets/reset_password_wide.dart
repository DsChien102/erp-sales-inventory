import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/validation/password_policy.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:erp/core/widgets/flow/resend_countdown.dart';
import 'package:flutter/material.dart';

const _resetSteps = ['Xác minh email', 'Tạo mật khẩu mới'];

/// Bước 1 Đặt lại mật khẩu trên web (prototype `app/web/reset.js` `verifyStep`).
class ResetVerifyWide extends StatelessWidget {
  const ResetVerifyWide({
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
    return FlowColumn(
      children: [
        const VStepProgress(
          titles: _resetSteps,
          currentIndex: 0,
          variant: VStepProgressVariant.standard,
        ),
        const VGap.lg(),
        FlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: FlowIcon.medium(VIcons.mail),
              ),
              const VGap.md(),
              Semantics(
                header: true,
                child: VText(
                  'Xác minh email',
                  variant: VTextVariant.headingH2,
                  color: colors.textPrimary,
                  style: const TextStyle(height: 28 / 22, letterSpacing: 0),
                ),
              ),
              const VGap.sm(),
              VText(
                'Mã 6 chữ số đã được gửi tới $maskedEmail. Xác nhận mã để tạo mật khẩu mới.',
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
              ),
              const VGap.lg(),
              codeField,
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
        const VGap.md(),
        VText(
          'Mã chỉ sử dụng một lần và hết hạn sau 10 phút.',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Bước 2 Đặt lại mật khẩu trên web (prototype `app/web/reset.js` `createStep`).
class ResetCreateWide extends StatelessWidget {
  const ResetCreateWide({
    super.key,
    required this.newPasswordField,
    required this.confirmPasswordField,
  });

  final Widget newPasswordField;
  final Widget confirmPasswordField;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return FlowColumn(
      children: [
        const VStepProgress(
          titles: _resetSteps,
          currentIndex: 1,
          variant: VStepProgressVariant.standard,
        ),
        const VGap.lg(),
        FlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: VText(
                  'Tạo mật khẩu mới',
                  variant: VTextVariant.headingH2,
                  color: colors.textPrimary,
                  style: const TextStyle(height: 28 / 22, letterSpacing: 0),
                ),
              ),
              const VGap.md(),
              newPasswordField,
              const VGap.md(),
              confirmPasswordField,
              const VGap.lg(),
              Container(
                padding: const EdgeInsets.all(VSpacing.space4),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(VRadius.r8),
                ),
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
      ],
    );
  }
}
