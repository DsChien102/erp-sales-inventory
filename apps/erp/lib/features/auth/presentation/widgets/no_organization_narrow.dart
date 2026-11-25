import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/flow/flow_layout.dart';
import '../auth_layout.dart';

/// Bố cục iPhone của Chưa thuộc tổ chức (prototype `app/verify.js` `noOrgPage`, `.t1-noorgm*`):
/// biểu tượng + tiêu đề + mô tả canh giữa vùng trên, "Nhập mã lời mời" và "Đăng xuất" (link) ở đáy.
class NoOrganizationNarrow extends StatelessWidget {
  const NoOrganizationNarrow({
    super.key,
    required this.onEnterCode,
    required this.onSignOut,
  });

  final VoidCallback onEnterCode;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: VContentWidth(
          maxWidth: authMaxWidth,
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.screenMobile,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(VSpacing.lg).copyWith(
                              left: VSpacing.md,
                              right: VSpacing.md,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const FlowIcon.large(VIcons.apartment),
                                const SizedBox(height: VSpacing.md),
                                Semantics(
                                  header: true,
                                  child: VText(
                                    'Bạn chưa thuộc tổ chức nào',
                                    variant: VTextVariant.headingH2,
                                    color: colors.textPrimary,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: VSpacing.sm),
                                VText(
                                  'Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.',
                                  variant: VTextVariant.bodyDefault,
                                  color: colors.textSecondary,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        VButton(
                          key: const Key('no_organization_invite'),
                          label: 'Nhập mã lời mời',
                          fullWidth: true,
                          onPressed: onEnterCode,
                        ),
                        const SizedBox(height: VSpacing.xs),
                        Center(
                          child: VButton(
                            key: const Key('no_organization_sign_out'),
                            label: 'Đăng xuất',
                            variant: VButtonVariant.link,
                            onPressed: onSignOut,
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
      ),
    );
  }
}
