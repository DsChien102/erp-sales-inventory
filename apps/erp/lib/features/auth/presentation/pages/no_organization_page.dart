import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';

class NoOrganizationPage extends StatelessWidget {
  const NoOrganizationPage({super.key, this.session});

  final SessionController? session;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final sessionController = session ?? getIt<SessionController>();
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - VSpacing.screenMobile * 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: VText(
                      'Bạn chưa thuộc tổ chức nào',
                      variant: VTextVariant.headingH3,
                      color: colors.textPrimary,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const VGap.md(),
                  VText(
                    'Bạn chưa được cấp quyền truy cập tổ chức nào. Hãy kiểm tra lời mời hoặc liên hệ Chủ cửa hàng.',
                    variant: VTextVariant.bodyDefault,
                    color: colors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                  const VGap.xl(),
                  VButton(
                    key: const Key('no_organization_invite'),
                    label: 'Nhập mã lời mời',
                    fullWidth: true,
                    onPressed: () => context.go('/invitation'),
                  ),
                  const VGap.md(),
                  VButton(
                    key: const Key('no_organization_sign_out'),
                    label: 'Đăng xuất',
                    variant: VButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () async {
                      await sessionController.signOut();
                      if (!context.mounted) return;
                      context.go('/login');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
