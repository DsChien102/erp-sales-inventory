import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
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
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async => PrincipalAccessDto(
    userId: 'user-1',
    tenantId: tenantId ?? 'tenant-1',
    role: 'staff',
    isOwner: false,
    permissions: const [InterimPermissionCodes.partnerRead],
  );

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async => allowed;

  @override
  Future<bool> isMember(String tenantId) async => member;

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async => const [];

  @override
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async => const [];

  @override
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async => throw UnimplementedError('S2 BE');

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) async => throw UnimplementedError('S3 BE');

  @override
  Future<CursorPageDto<TenantMemberDto>> listTenantMembers({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async => const CursorPageDto<TenantMemberDto>(items: []);

  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {}
}

class _FakePrincipalSnapshot implements IPrincipalSnapshot {
  _FakePrincipalSnapshot({
    this.role = 'staff',
    this.isOwner = false,
    Set<String> permissions = const {},
  }) : _permissions = permissions;

  @override
  final String? role;

  @override
  final bool isOwner;

  final Set<String> _permissions;

  @override
  bool hasPermission(String code) => _permissions.contains(code);
}

void main() {
  group('IamPermissionChecker', () {
    test('allows owner without gateway call', () async {
      final checker = IamPermissionChecker(
        principalSnapshot: _FakePrincipalSnapshot(isOwner: true),
        accessGateway: _FakeAccessGateway(allowed: false),
        executionContext: FakeExecutionContext(),
      );

      await checker.require(InterimPermissionCodes.partnerWrite);
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
        () => checker.require(InterimPermissionCodes.partnerWrite),
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
