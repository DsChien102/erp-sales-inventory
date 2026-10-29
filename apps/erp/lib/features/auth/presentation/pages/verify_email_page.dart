import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';
import '../../../iam/data/models/password_reset_result.dart';
import '../../data/auth_repository.dart';
import '../widgets/verify_email_view.dart';
import '../auth_layout.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({
    super.key,
    required this.email,
    this.auth,
    this.session,
  });

  final String email;
  final AuthRepository? auth;
  final SessionController? session;

  @override
  Widget build(BuildContext context) {
    final sessionController = session ?? getIt<SessionController>();
    final colors = context.vColors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: VContentWidth(
          maxWidth: authMaxWidth,
          alignment: Alignment.topCenter,
          child: ListView(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            children: [
              const VGap.xl(),
              Semantics(
                header: true,
                child: VText(
                  'Xác minh email để tiếp tục',
                  variant: VTextVariant.headingH3,
                  color: colors.textPrimary,
                ),
              ),
              const VGap.lg(),
              VerifyEmailView(
                email: email,
                auth: auth ?? getIt<AuthRepository>(),
                session: sessionController,
                prompt: 'Mã 6 chữ số đã được gửi tới ${maskEmail(email)}.',
                allowImmediateResend: true,
                onVerified: (_) => context.go('/'),
              ),
              const VGap.md(),
              VButton(
                label: 'Đăng xuất',
                variant: VButtonVariant.link,
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
    );
  }
}
