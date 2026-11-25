import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/flow/flow_layout.dart';

/// Bố cục web của Chưa thuộc tổ chức (prototype `app/web/verify.js` `noOrgPage`, `.t1-noorg*`):
/// thẻ ngang cột 560 giữa màn — ô tòa nhà 48 | tiêu đề, mô tả, hai nút (chính bên phải).
class NoOrganizationWide extends StatelessWidget {
  const NoOrganizationWide({
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
      backgroundColor: colors.background,
      body: SafeArea(
        child: FlowColumn(
          maxWidth: 560,
          centerVertically: true,
          children: [
            FlowCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FlowIcon.medium(VIcons.apartment),
                  const SizedBox(width: VSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: VText(
                            'Bạn chưa thuộc tổ chức nào',
                            variant: VTextVariant.headingH2,
                            color: colors.textPrimary,
                            style: const TextStyle(
                              fontSize: 20,
                              height: 28 / 20,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: VSpacing.sm),
                        VText(
                          'Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.',
                          variant: VTextVariant.bodyDefault,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(height: VSpacing.lg),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            alignment: WrapAlignment.end,
                            spacing: VSpacing.cozy,
                            runSpacing: VSpacing.cozy,
                            children: [
                              VButton(
                                key: const Key('no_organization_sign_out'),
                                label: 'Đăng xuất',
                                variant: VButtonVariant.secondary,
                                onPressed: onSignOut,
                              ),
                              VButton(
                                key: const Key('no_organization_invite'),
                                label: 'Nhập mã lời mời',
                                onPressed: onEnterCode,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
