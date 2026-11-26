import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Kích hoạt tài khoản theo lời mời trên khổ hẹp
/// (prototype `app/invitation.js` `registerView`).
class InvitationRegisterNarrow extends StatelessWidget {
  const InvitationRegisterNarrow({
    super.key,
    required this.tenantName,
    required this.email,
    required this.familyField,
    required this.givenField,
    required this.emailField,
    required this.phoneField,
    required this.passwordField,
    required this.confirmField,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onBack,
  });

  final String tenantName;
  final String email;
  final Widget familyField;
  final Widget givenField;
  final Widget emailField;
  final Widget phoneField;
  final Widget passwordField;
  final Widget confirmField;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: VAppBar(
        title: 'Kích hoạt tài khoản',
        leading: onBack == null
            ? null
            : IconButton(
                tooltip: 'Quay lại',
                icon: VIcon(icon: VIcons.chevronLeft, color: colors.textPrimary),
                onPressed: isSubmitting ? null : onBack,
              ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.screenMobile,
                  20,
                  VSpacing.screenMobile,
                  VSpacing.xl,
                ),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          VIcon(
                            icon: VIcons.success,
                            size: 22,
                            color: colors.success,
                          ),
                          const VGap.horizontalSm(),
                          Expanded(
                            child: VText(
                              'Mã lời mời hợp lệ',
                              variant: VTextVariant.headingH3,
                              color: colors.textPrimary,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const VGap.xs(),
                      Text.rich(
                        TextSpan(
                          style: VTypography.bodyDefault.copyWith(
                            color: colors.textSecondary,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'Kích hoạt tài khoản để tiếp nhận lời mời và vào ',
                            ),
                            TextSpan(
                              text: tenantName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: familyField),
                          const VGap.horizontalSm(),
                          Expanded(flex: 2, child: givenField),
                        ],
                      ),
                      const VGap.md(),
                      Semantics(
                        container: true,
                        label: 'Email, $email, không sửa được',
                        child: ExcludeSemantics(
                          child: Container(
                            key: const Key('invitation_locked_email'),
                            constraints: const BoxConstraints(
                              minHeight: VSpacing.minTouchTarget,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colors.background,
                              borderRadius: BorderRadius.circular(
                                VRadius.input,
                              ),
                            ),
                            child: Row(
                              children: [
                                VText(
                                  'Email',
                                  variant: VTextVariant.bodyDefault,
                                  color: colors.textPrimary,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: VText(
                                    email,
                                    variant: VTextVariant.bodyDefault,
                                    color: colors.textSecondary,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                VIcon(
                                  icon: VIcons.lock,
                                  size: 16,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const VGap.md(),
                      phoneField,
                      const VGap.md(),
                      passwordField,
                      const VGap.md(),
                      confirmField,
                      const VGap.lg(),
                      VButton(
                        key: const Key('invitation_accept_submit'),
                        label: 'Kích hoạt tài khoản',
                        fullWidth: true,
                        isLoading: isSubmitting,
                        onPressed: isSubmitting ? null : onSubmit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
