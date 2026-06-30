import 'package:vet45_shared_application/application.dart';

import '../ports/i_iam_access_gateway.dart';
import '../ports/i_principal_snapshot.dart';

/// DB-backed permission checker for module command pipelines.
final class IamPermissionChecker implements IPermissionChecker {
  IamPermissionChecker({
    required IPrincipalSnapshot principalSnapshot,
    required IIamAccessGateway accessGateway,
    required IExecutionContext executionContext,
  }) : _principalSnapshot = principalSnapshot,
       _accessGateway = accessGateway,
       _executionContext = executionContext;

  final IPrincipalSnapshot _principalSnapshot;
  final IIamAccessGateway _accessGateway;
  final IExecutionContext _executionContext;

  @override
  Future<void> require(String permissionCode) async {
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
