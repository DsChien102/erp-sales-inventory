import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/flow/flow_layout.dart';
import 'signup_steps.dart';

/// Thân trang Đăng ký trên web (prototype `app/web/signup.js`, `.t1-stepcol`):
/// cột 520, thanh tiến độ, thẻ trắng có tiêu đề = tên bước, [footer] dưới thẻ.
class SignupWide extends StatelessWidget {
  const SignupWide({
    super.key,
    required this.stepIndex,
    required this.banner,
    required this.content,
    required this.footer,
  });

  final int stepIndex;
  final Widget? banner;
  final Widget content;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return FlowColumn(
      children: [
        VStepProgress(titles: signupStepTitles, currentIndex: stepIndex),
        const VGap.lg(),
        FlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: VText(
                  signupStepTitles[stepIndex],
                  variant: VTextVariant.headingH2,
                  color: colors.textPrimary,
                  style: const TextStyle(height: 28 / 22, letterSpacing: 0),
                ),
              ),
              const SizedBox(height: VSpacing.space5),
              if (banner != null) ...[banner!, const VGap.md()],
              content,
            ],
          ),
        ),
        if (footer != null) ...[
          const VGap.md(),
          Center(child: footer),
        ],
      ],
    );
  }
}
