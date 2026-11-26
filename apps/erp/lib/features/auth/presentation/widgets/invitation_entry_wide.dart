import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:flutter/material.dart';

/// Nhập mã lời mời trên web (prototype `app/web/invitation.js` `entryView`).
class InvitationEntryWide extends StatelessWidget {
  const InvitationEntryWide({
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
      backgroundColor: colors.background,
      appBar: VAppBar(
        title: 'Kích hoạt tài khoản',
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: VIcon(icon: VIcons.chevronLeft, color: colors.textPrimary),
          onPressed: isSubmitting ? null : onBack,
        ),
      ),
      body: SafeArea(
        child: FlowColumn(
          children: [
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
                      'Nhập mã lời mời',
                      variant: VTextVariant.headingH2,
                      color: colors.textPrimary,
                      style: const TextStyle(height: 28 / 22, letterSpacing: 0),
                    ),
                  ),
                  const VGap.sm(),
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
          ],
        ),
      ),
    );
  }
}
