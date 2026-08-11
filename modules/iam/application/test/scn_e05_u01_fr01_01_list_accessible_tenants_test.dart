import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// scn_e05_u01_fr01_01 — ListAccessibleTenantsQueryHandler scenarios (§S1).
class _FakeCurrentTenant implements ICurrentTenant {
  _FakeCurrentTenant(this.tenantId);

  @override
  final String? tenantId;
}

class _ScenarioAccessGateway implements IIamAccessGateway {
  _ScenarioAccessGateway(this.tenants);

  final List<AccessibleTenantDto> tenants;

  @override
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async => tenants;

  @override
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async => throw UnimplementedError('S2 BE');

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) async => throw UnimplementedError('S3 BE');

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async => null;

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async => true;

  @override
  Future<bool> isMember(String tenantId) async => true;

  @override
  Future<CursorPageDto<TenantMemberDto>> listTenantMembers({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async => const CursorPageDto<TenantMemberDto>(items: []);

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async => const [];

  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {}
}

void main() {
  group('scn_e05_u01_fr01_01 ListAccessibleTenantsQueryHandler', () {
    test('tenants_single — one membership marked current', () async {
      final gateway = _ScenarioAccessGateway(const [
        AccessibleTenantDto(
          tenantId: 'tenant-1',
          name: 'Store A',
          roleLabel: 'owner',
          status: TenantLifecycleStatus.active,
        ),
      ]);
      final handler = ListAccessibleTenantsQueryHandler(
        accessGateway: gateway,
        currentTenant: _FakeCurrentTenant('tenant-1'),
      );

      final result = await handler.handle(ListAccessibleTenantsQuery());

      expect(result, hasLength(1));
      expect(result.single.tenantId, 'tenant-1');
      expect(result.single.name, 'Store A');
      expect(result.single.roleLabel, 'owner');
      expect(result.single.status, TenantLifecycleStatus.active);
      expect(result.single.isCurrent, isTrue);
    });

    test('tenants_multi — many active memberships, current marked', () async {
      final gateway = _ScenarioAccessGateway(const [
        AccessibleTenantDto(
          tenantId: 'tenant-a',
          name: 'Alpha',
          roleLabel: 'owner',
          status: TenantLifecycleStatus.active,
        ),
        AccessibleTenantDto(
          tenantId: 'tenant-b',
          name: 'Beta',
          roleLabel: 'staff',
          status: TenantLifecycleStatus.active,
        ),
        AccessibleTenantDto(
          tenantId: 'tenant-c',
          name: 'Gamma',
          roleLabel: 'staff',
          status: TenantLifecycleStatus.active,
        ),
      ]);
      final handler = ListAccessibleTenantsQueryHandler(
        accessGateway: gateway,
        currentTenant: _FakeCurrentTenant('tenant-b'),
      );

      final result = await handler.handle(ListAccessibleTenantsQuery());

      expect(result, hasLength(3));
      expect(result.where((t) => t.isCurrent), hasLength(1));
      expect(
        result.firstWhere((t) => t.tenantId == 'tenant-b').isCurrent,
        isTrue,
      );
      expect(
        result.firstWhere((t) => t.tenantId == 'tenant-a').isCurrent,
        isFalse,
      );
      expect(
        result.firstWhere((t) => t.tenantId == 'tenant-c').isCurrent,
        isFalse,
      );
    });

    test('tenants_suspended_disabled — suspended item returned', () async {
      final gateway = _ScenarioAccessGateway(const [
        AccessibleTenantDto(
          tenantId: 'tenant-live',
          name: 'Live',
          roleLabel: 'owner',
          status: TenantLifecycleStatus.active,
        ),
        AccessibleTenantDto(
          tenantId: 'tenant-paused',
          name: 'Paused',
          roleLabel: 'staff',
          status: TenantLifecycleStatus.suspended,
        ),
      ]);
      final handler = ListAccessibleTenantsQueryHandler(
        accessGateway: gateway,
        currentTenant: _FakeCurrentTenant('tenant-live'),
      );

      final result = await handler.handle(ListAccessibleTenantsQuery());

      final suspended = result.firstWhere(
        (t) => t.tenantId == 'tenant-paused',
      );
      expect(suspended.status, TenantLifecycleStatus.suspended);
      expect(suspended.isCurrent, isFalse);
      expect(suspended.isSelectable, isFalse);
      expect(
        result.firstWhere((t) => t.tenantId == 'tenant-live').isCurrent,
        isTrue,
      );
    });

    test('tenants_provisioning — provisioning status mapped', () async {
      final gateway = _ScenarioAccessGateway(const [
        AccessibleTenantDto(
          tenantId: 'tenant-new',
          name: 'New Org',
          roleLabel: 'owner',
          status: TenantLifecycleStatus.provisioning,
        ),
      ]);
      final handler = ListAccessibleTenantsQueryHandler(
        accessGateway: gateway,
        currentTenant: _FakeCurrentTenant('tenant-new'),
      );

      final result = await handler.handle(ListAccessibleTenantsQuery());

      expect(result.single.status, TenantLifecycleStatus.provisioning);
      expect(result.single.isCurrent, isTrue);
      expect(result.single.isSelectable, isFalse);
    });

    test('tenants_closed_disabled — closed is not selectable', () async {
      final gateway = _ScenarioAccessGateway(const [
        AccessibleTenantDto(
          tenantId: 'tenant-closed',
          name: 'Closed Co',
          roleLabel: 'owner',
          status: TenantLifecycleStatus.closed,
        ),
      ]);
      final handler = ListAccessibleTenantsQueryHandler(
        accessGateway: gateway,
        currentTenant: _FakeCurrentTenant(null),
      );

      final result = await handler.handle(ListAccessibleTenantsQuery());
      expect(result.single.isSelectable, isFalse);
      expect(result.single.status, TenantLifecycleStatus.closed);
    });

    test('tenants_excludes_inactive_membership — gateway omits inactive', () async {
      // Contract: inactive memberships never appear in accessible list.
      final gateway = _ScenarioAccessGateway(const [
        AccessibleTenantDto(
          tenantId: 'tenant-active-only',
          name: 'Active',
          roleLabel: 'staff',
          status: TenantLifecycleStatus.active,
        ),
      ]);
      final handler = ListAccessibleTenantsQueryHandler(
        accessGateway: gateway,
        currentTenant: _FakeCurrentTenant('tenant-active-only'),
      );

      final result = await handler.handle(ListAccessibleTenantsQuery());
      expect(result, hasLength(1));
      expect(result.single.isSelectable, isTrue);
      expect(result.any((t) => t.tenantId == 'tenant-inactive'), isFalse);
    });

    test('tenants_authentication_required — gateway auth error propagates', () async {
      final handler = ListAccessibleTenantsQueryHandler(
        accessGateway: _AuthFailAccessGateway(),
        currentTenant: _FakeCurrentTenant(null),
      );
      expect(
        () => handler.handle(ListAccessibleTenantsQuery()),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.authenticationRequired,
          ),
        ),
      );
    });

    test('isSelectable true only for active tenants', () async {
      final gateway = _ScenarioAccessGateway(const [
        AccessibleTenantDto(
          tenantId: 'a',
          name: 'A',
          roleLabel: 'owner',
          status: TenantLifecycleStatus.active,
        ),
        AccessibleTenantDto(
          tenantId: 's',
          name: 'S',
          roleLabel: 'staff',
          status: TenantLifecycleStatus.suspended,
        ),
      ]);
      final handler = ListAccessibleTenantsQueryHandler(
        accessGateway: gateway,
        currentTenant: _FakeCurrentTenant('a'),
      );
      final result = await handler.handle(ListAccessibleTenantsQuery());
      expect(
        result.firstWhere((t) => t.tenantId == 'a').isSelectable,
        isTrue,
      );
      expect(
        result.firstWhere((t) => t.tenantId == 's').isSelectable,
        isFalse,
      );
    });
  });
}

class _AuthFailAccessGateway implements IIamAccessGateway {
  @override
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async {
    throw const IamBlockedException(IamBlockedCodes.authenticationRequired);
  }

  @override
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async => throw UnimplementedError();

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) async => throw UnimplementedError();

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async => null;

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async => true;

  @override
  Future<bool> isMember(String tenantId) async => true;

  @override
  Future<CursorPageDto<TenantMemberDto>> listTenantMembers({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async => const CursorPageDto<TenantMemberDto>(items: []);

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async => const [];

  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {}
}
