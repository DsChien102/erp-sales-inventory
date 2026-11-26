import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:flutter/material.dart';

/// Kích hoạt tài khoản theo lời mời trên web
/// (prototype `app/web/invitation.js` `registerView`).
class InvitationRegisterWide extends StatelessWidget {
  const InvitationRegisterWide({
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
      backgroundColor: colors.background,
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
        child: FlowColumn(
          children: [
            VBanner(
              status: VBannerStatus.success,
              title: 'Mã lời mời hợp lệ',
              description:
                  'Kích hoạt tài khoản để tiếp nhận lời mời và vào $tenantName.',
            ),
            const VGap.md(),
            FlowCard(
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    familyField,
                    const VGap.md(),
                    givenField,
                    const VGap.md(),
                    emailField,
                    const VGap.md(),
                    phoneField,
                    const VGap.md(),
                    passwordField,
                    const VGap.md(),
                    confirmField,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.borderDefault)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: VButton(
                  key: const Key('invitation_accept_submit'),
                  label: 'Kích hoạt tài khoản',
                  fullWidth: true,
                  isLoading: isSubmitting,
                  onPressed: isSubmitting ? null : onSubmit,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
