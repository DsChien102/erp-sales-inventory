import 'package:vet45_shared_application/application.dart';

import '../ports/i_iam_access_gateway.dart';

/// Ensures the current principal is a member of the requested tenant.
final class IamTenantAccessChecker implements ITenantAccessChecker {
  IamTenantAccessChecker({required IIamAccessGateway accessGateway})
    : _accessGateway = accessGateway;

  final IIamAccessGateway _accessGateway;

  @override
  Future<void> ensureAccess(String tenantId) async {
    final isMember = await _accessGateway.isMember(tenantId);
    if (!isMember) {
      throw ApplicationException('Tenant access denied: $tenantId');
    }
  }
}
