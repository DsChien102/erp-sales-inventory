import 'package:c45_shared_application/application.dart';

/// Records tenant access checks in tests.
final class FakeTenantAccessChecker implements ITenantAccessChecker {
  FakeTenantAccessChecker({this.deny = const {}});

  final Set<String> deny;
  final List<String> checked = [];

  @override
  Future<void> ensureAccess(String tenantId) async {
    checked.add(tenantId);
    if (deny.contains(tenantId)) {
      throw ApplicationException('Tenant access denied: $tenantId');
    }
  }
}
