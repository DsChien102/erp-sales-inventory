import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/wide_layout.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';
import '../widgets/no_organization_narrow.dart';
import '../widgets/no_organization_wide.dart';

class NoOrganizationPage extends StatelessWidget {
  const NoOrganizationPage({super.key, this.session});

  final SessionController? session;

  @override
  Widget build(BuildContext context) {
    final sessionController = session ?? getIt<SessionController>();
    void enterCode() => context.go('/invitation');
    Future<void> signOut() async {
      await sessionController.signOut();
      if (!context.mounted) return;
      context.go('/login');
    }

    return isWideLayout(context)
        ? NoOrganizationWide(onEnterCode: enterCode, onSignOut: signOut)
        : NoOrganizationNarrow(onEnterCode: enterCode, onSignOut: signOut);
  }
}
