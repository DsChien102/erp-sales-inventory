import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/session/session_state.dart';

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
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.screenMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              VText(
                'Bạn chưa thuộc tổ chức nào',
                variant: VTextVariant.headingH3,
                color: colors.textPrimary,
                textAlign: TextAlign.center,
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
              BlocBuilder<SessionController, SessionState>(
                bloc: sessionController,
                buildWhen: (previous, current) =>
                    previous.isPlatformAdmin != current.isPlatformAdmin,
                builder: (context, state) {
                  if (!state.isPlatformAdmin) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: VSpacing.space3),
                    child: VButton(
                      key: const Key('no_organization_platform_admin'),
                      label: 'Quản trị nền tảng',
                      variant: VButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () => context.push('/more/platform/organizations'),
                    ),
                  );
                },
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
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
