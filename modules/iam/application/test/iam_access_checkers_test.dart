import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

class _FakeAccessGateway implements IIamAccessGateway {
  _FakeAccessGateway({
    this.member = true,
    this.allowed = true,
  });

  final bool member;
  final bool allowed;

  @override
  Future<String> bootstrapOwner({String tenantName = 'My Store'}) async =>
      'tenant-1';

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async =>
      PrincipalAccessDto(
        userId: 'user-1',
        tenantId: tenantId ?? 'tenant-1',
        role: 'staff',
        permissions: const ['partner.read'],
      );

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async =>
      allowed;

  @override
  Future<bool> isMember(String tenantId) async => member;

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async => const [];
}

class _FakePrincipalSnapshot implements IPrincipalSnapshot {
  _FakePrincipalSnapshot({
    this.role = 'staff',
    Set<String> permissions = const {},
  }) : _permissions = permissions;

  @override
  final String? role;

  final Set<String> _permissions;

  @override
  bool hasPermission(String code) => _permissions.contains(code);
}

void main() {
  group('IamPermissionChecker', () {
    test('allows owner without gateway call', () async {
      final checker = IamPermissionChecker(
        principalSnapshot: _FakePrincipalSnapshot(role: 'owner'),
        accessGateway: _FakeAccessGateway(allowed: false),
        executionContext: FakeExecutionContext(),
      );

      await checker.require('partner.write');
    });

    test('denies when permission missing', () async {
      final checker = IamPermissionChecker(
        principalSnapshot: _FakePrincipalSnapshot(
          role: 'staff',
          permissions: const {},
        ),
        accessGateway: _FakeAccessGateway(allowed: false),
        executionContext: FakeExecutionContext(),
      );

      expect(
        () => checker.require('partner.write'),
        throwsA(isA<ApplicationException>()),
      );
    });
  });

  group('IamTenantAccessChecker', () {
    test('denies non-member tenant', () async {
      final checker = IamTenantAccessChecker(
        accessGateway: _FakeAccessGateway(member: false),
      );

      expect(
        () => checker.ensureAccess('tenant-x'),
        throwsA(isA<ApplicationException>()),
      );
    });
  });
}
