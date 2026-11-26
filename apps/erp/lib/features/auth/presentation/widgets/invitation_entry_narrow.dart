import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Nhập mã lời mời trên khổ hẹp (prototype `app/invitation.js` `entryView`).
class InvitationEntryNarrow extends StatelessWidget {
  const InvitationEntryNarrow({
    super.key,
    required this.codeField,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onBack,
  });

  final Widget codeField;
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
        leading: IconButton(
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
                  VSpacing.lg,
                  VSpacing.screenMobile,
                  VSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: VText(
                        'Nhập mã lời mời',
                        variant: VTextVariant.headingH2,
                        color: colors.textPrimary,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const VGap.xs(),
                    VText(
                      'Sao chép mã được gửi tới email của bạn rồi dán vào trường bên dưới.',
                      variant: VTextVariant.bodyDefault,
                      color: colors.textSecondary,
                    ),
                    const VGap.lg(),
                    codeField,
                    const VGap.lg(),
                    VButton(
                      key: const Key('invitation_token_submit'),
                      label: 'Tiếp tục',
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
    );
  }
}
