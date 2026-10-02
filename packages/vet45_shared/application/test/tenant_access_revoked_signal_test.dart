import 'package:test/test.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  test('emits code when error mentions TENANT_SUSPENDED or TENANT_CLOSED', () async {
    final events = <String>[];
    final sub = TenantAccessRevokedSignal.stream.listen(events.add);

    TenantAccessRevokedSignal.notifyFromError(
      Exception('PostgrestException(message: TENANT_SUSPENDED)'),
    );
    TenantAccessRevokedSignal.notifyFromError(Exception('{"code":"TENANT_CLOSED"}'));
    TenantAccessRevokedSignal.notifyFromError(Exception('PERMISSION_DENIED'));
    await Future<void>.delayed(Duration.zero);

    expect(events, [
      TenantAccessRevokedSignal.tenantSuspended,
      TenantAccessRevokedSignal.tenantClosed,
    ]);
    await sub.cancel();
  });

  test('emits platform user suspended code', () async {
    final events = <String>[];
    final sub = TenantAccessRevokedSignal.stream.listen(events.add);

    TenantAccessRevokedSignal.notifyFromError(
      Exception('PostgrestException(message: PLATFORM_USER_SUSPENDED)'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(events, [TenantAccessRevokedSignal.platformUserSuspended]);
    await sub.cancel();
  });
}
