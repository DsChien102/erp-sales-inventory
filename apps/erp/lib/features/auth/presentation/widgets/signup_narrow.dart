import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../auth_layout.dart';
import 'signup_steps.dart';

/// Thân trang Đăng ký trên iPhone (prototype `app/signup.js`): thanh tiến độ,
/// khe 24, banner lỗi máy chủ (nếu có) + khe 16, rồi nội dung bước. `VAppBar` và ← do trang giữ.
class SignupNarrow extends StatelessWidget {
  const SignupNarrow({
    super.key,
    required this.stepIndex,
    required this.banner,
    required this.content,
  });

  final int stepIndex;
  final Widget? banner;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return VContentWidth(
      maxWidth: authMaxWidth,
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VStepProgress(
              titles: signupStepTitles,
              currentIndex: stepIndex,
              variant: VStepProgressVariant.mobile,
            ),
            const VGap.lg(),
            if (banner != null) ...[banner!, const VGap.md()],
            content,
          ],
        ),
      ),
    );
  }
}
