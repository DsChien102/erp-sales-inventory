import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/flow/flow_layout.dart';

/// Bố cục web của Xác minh email (prototype `app/web/verify.js` `verifyPage`):
/// cột 520 giữa màn, thẻ trắng (ô thư 48, tiêu đề, [form]), "Đăng xuất" (link) dưới thẻ.
/// [form] là `VerifyEmailView` có lời nhắc.
class VerifyEmailWide extends StatelessWidget {
  const VerifyEmailWide({
    super.key,
    required this.form,
    required this.onSignOut,
  });

  final Widget form;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: FlowColumn(
          centerVertically: true,
          children: [
            FlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: FlowIcon.medium(VIcons.mail),
                  ),
                  const SizedBox(height: VSpacing.md),
                  Semantics(
                    header: true,
                    child: VText(
                      'Xác minh email để tiếp tục',
                      variant: VTextVariant.headingH2,
                      color: colors.textPrimary,
                      style: const TextStyle(height: 28 / 22, letterSpacing: 0),
                    ),
                  ),
                  const SizedBox(height: VSpacing.sm),
                  form,
                ],
              ),
            ),
            const SizedBox(height: VSpacing.md),
            Center(
              child: VButton(
                label: 'Đăng xuất',
                variant: VButtonVariant.link,
                onPressed: onSignOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
