import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/wide_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';
import '../../../iam/data/models/password_reset_result.dart';
import '../../data/auth_repository.dart';
import '../widgets/verify_email_narrow.dart';
import '../widgets/verify_email_view.dart';
import '../widgets/verify_email_wide.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({
    super.key,
    required this.email,
    this.auth,
    this.session,
    this.clock,
  });

  final String email;
  final AuthRepository? auth;
  final SessionController? session;

  /// Đồng hồ cho `VerifyEmailView` (test / golden cố định giờ).
  final DateTime Function()? clock;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  /// Giữ `VerifyEmailView` (cubit, bộ đếm, mã đang gõ) khi đổi bố cục iPhone / web.
  final _viewKey = GlobalKey<State<VerifyEmailView>>();

  @override
  Widget build(BuildContext context) {
    final sessionController = widget.session ?? getIt<SessionController>();
    final wide = isWideLayout(context);
    final form = VerifyEmailView(
      key: _viewKey,
      email: widget.email,
      auth: widget.auth ?? getIt<AuthRepository>(),
      session: sessionController,
      prompt: 'Mã 6 chữ số đã được gửi tới ${maskEmail(widget.email)}.',
      showPrompt: wide,
      clock: widget.clock,
      allowImmediateResend: true,
      onVerified: (_) => context.go('/'),
    );
    Future<void> signOut() async {
      await sessionController.signOut();
      if (!context.mounted) return;
      context.go('/login');
    }

    return wide
        ? VerifyEmailWide(form: form, onSignOut: signOut)
        : VerifyEmailNarrow(
            maskedEmail: maskEmail(widget.email),
            form: form,
            onSignOut: signOut,
          );
  }
}
