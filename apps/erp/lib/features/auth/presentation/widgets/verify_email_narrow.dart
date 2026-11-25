import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/flow/flow_layout.dart';
import '../auth_layout.dart';

/// Bố cục iPhone của Xác minh email (prototype `app/verify.js` `verifyPage`, `.t1-vmail*`):
/// biểu tượng thư 64, tiêu đề + lời nhắc canh giữa, thẻ nhập mã, "Đăng xuất" (link) ở đáy màn.
/// [form] là `VerifyEmailView(showPrompt: false)`.
class VerifyEmailNarrow extends StatelessWidget {
  const VerifyEmailNarrow({
    super.key,
    required this.maskedEmail,
    required this.form,
    required this.onSignOut,
  });

  final String maskedEmail;
  final Widget form;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final bodyStyle = VTypography.bodyDefault.copyWith(
      color: colors.textSecondary,
    );
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: VContentWidth(
          maxWidth: authMaxWidth,
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VSpacing.screenMobile,
                    VSpacing.xl,
                    VSpacing.screenMobile,
                    0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: FlowIcon.large(VIcons.mail)),
                          const SizedBox(height: VSpacing.md),
                          Semantics(
                            header: true,
                            child: VText(
                              'Xác minh email để tiếp tục',
                              variant: VTextVariant.headingH2,
                              color: colors.textPrimary,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: VSpacing.xs),
                          Text.rich(
                            TextSpan(
                              style: bodyStyle,
                              children: [
                                const TextSpan(
                                  text: 'Mã 6 chữ số đã được gửi tới ',
                                ),
                                TextSpan(
                                  text: maskedEmail,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: VSpacing.lg),
                          VCard(
                            padding: const EdgeInsets.fromLTRB(
                              VSpacing.md,
                              VSpacing.space5,
                              VSpacing.md,
                              VSpacing.sm,
                            ),
                            child: form,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: VSpacing.md),
                        child: Center(
                          child: VButton(
                            label: 'Đăng xuất',
                            variant: VButtonVariant.link,
                            onPressed: onSignOut,
                          ),
                        ),
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
