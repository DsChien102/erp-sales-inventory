import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

final class _StubIamAccessGateway implements IIamAccessGateway {
  _StubIamAccessGateway(this.response);

  final PrincipalAccessDto? response;
  String? requestedTenantId;

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async {
    requestedTenantId = tenantId;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('maps the authoritative active-store session context', () async {
    final gateway = _StubIamAccessGateway(
      const PrincipalAccessDto(
        userId: 'user-1',
        tenantId: 'tenant-1',
        activeStoreId: 'store-1',
        activeStoreCode: 'HCM-01',
        activeStoreDisplayName: 'Chi nhánh Hồ Chí Minh',
        role: 'staff',
        isOwner: false,
        permissions: <String>[],
      ),
    );
    final handler = GetActiveStoreContextQueryHandler(
      accessGateway: gateway,
    );

    final result = await handler.handle(
      GetActiveStoreContextQuery(tenantId: 'tenant-1'),
    );

    expect(gateway.requestedTenantId, 'tenant-1');
    expect(result.userId, 'user-1');
    expect(result.tenantId, 'tenant-1');
    expect(result.storeId, 'store-1');
    expect(result.storeCode, 'HCM-01');
    expect(result.displayName, 'Chi nhánh Hồ Chí Minh');
  });

  test('fails closed when the active-store session context is absent', () {
    final handler = GetActiveStoreContextQueryHandler(
      accessGateway: _StubIamAccessGateway(null),
    );

    expect(
      () => handler.handle(
        GetActiveStoreContextQuery(tenantId: 'tenant-1'),
      ),
      throwsA(isA<ApplicationException>()),
    );
  });

  test('fails closed when authoritative store display fields are blank', () {
    final handler = GetActiveStoreContextQueryHandler(
      accessGateway: _StubIamAccessGateway(
        const PrincipalAccessDto(
          userId: 'user-1',
          tenantId: 'tenant-1',
          activeStoreId: 'store-1',
          activeStoreCode: ' ',
          activeStoreDisplayName: '',
          role: 'staff',
          isOwner: false,
          permissions: <String>[],
        ),
      ),
    );

    expect(
      () => handler.handle(
        GetActiveStoreContextQuery(tenantId: 'tenant-1'),
      ),
      throwsA(isA<ApplicationException>()),
    );
  });
}
