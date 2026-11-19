import 'package:c45_shared_application/application.dart';

/// Configurable [IExecutionContext] for unit tests.
final class FakeExecutionContext implements IExecutionContext {
  FakeExecutionContext({
    this.userId = 'user-test',
    this.tenantId = 'tenant-test',
    this.correlationId = 'corr-test',
    this.failUser = false,
    this.failTenant = false,
  });

  String? userId;
  String? tenantId;
  @override
  final String correlationId;
  bool failUser;
  bool failTenant;

  @override
  Future<String> requireUserId() async {
    if (failUser || userId == null) {
      throw ApplicationException('User is required');
    }
    return userId!;
  }

  @override
  Future<String> requireTenantId() async {
    if (failTenant || tenantId == null) {
      throw ApplicationException('Tenant is required');
    }
    return tenantId!;
  }
}
