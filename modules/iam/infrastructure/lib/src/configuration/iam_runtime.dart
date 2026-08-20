import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'session/iam_session.dart';

/// Host-facing bundle returned by [IamStartup.initialize].
final class IamRuntime {
  const IamRuntime({
    required this.module,
    required this.executionContext,
    required this.permissionChecker,
    required this.tenantAccessChecker,
    required this.session,
    required this.sessionPort,
  });

  final IIamModule module;
  final IExecutionContext executionContext;
  final IPermissionChecker permissionChecker;
  final ITenantAccessChecker tenantAccessChecker;
  final IamSession session;

  /// Exposed so host apps can call [IIamSessionPort.restoreFromPersistedAuth]
  /// after DI is complete, rather than relying on [IamStartup] to do it
  /// internally. This keeps session bootstrap outside the module boundary.
  final IIamSessionPort sessionPort;
}
