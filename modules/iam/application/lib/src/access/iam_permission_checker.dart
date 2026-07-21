import 'package:vet45_shared_application/application.dart';

import '../ports/i_iam_access_gateway.dart';
import '../ports/i_platform_admin_gateway.dart';
import '../ports/i_principal_snapshot.dart';

/// DB-backed permission checker for module command pipelines.
///
/// Platform-scoped codes (`platform.*`) are checked via [IPlatformAdminGateway]
/// without requiring a tenant context.
final class IamPermissionChecker implements IPermissionChecker {
  IamPermissionChecker({
    required IPrincipalSnapshot principalSnapshot,
    required IIamAccessGateway accessGateway,
    required IExecutionContext executionContext,
    IPlatformAdminGateway? platformGateway,
  }) : _principalSnapshot = principalSnapshot,
       _accessGateway = accessGateway,
       _executionContext = executionContext,
       _platformGateway = platformGateway;

  final IPrincipalSnapshot _principalSnapshot;
  final IIamAccessGateway _accessGateway;
  final IExecutionContext _executionContext;
  final IPlatformAdminGateway? _platformGateway;

  @override
  Future<void> require(String permissionCode) async {
    if (permissionCode.startsWith('platform.')) {
      final gateway = _platformGateway;
      if (gateway == null) {
        throw ApplicationException('Permission denied: $permissionCode');
      }
      final allowed = await gateway.hasPlatformPermission(permissionCode);
      if (!allowed) {
        throw ApplicationException('Permission denied: $permissionCode');
      }
      return;
    }

    if (_principalSnapshot.role == 'owner') {
      return;
    }

    if (_principalSnapshot.hasPermission(permissionCode)) {
      return;
    }

    final tenantId = await _executionContext.requireTenantId();
    final allowed = await _accessGateway.hasPermission(
      tenantId: tenantId,
      permission: permissionCode,
    );

    if (!allowed) {
      throw ApplicationException('Permission denied: $permissionCode');
    }
  }
}
