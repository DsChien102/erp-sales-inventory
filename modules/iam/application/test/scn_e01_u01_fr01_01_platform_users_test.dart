import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

class _FakePlatformGateway implements IPlatformAdminGateway {
  _FakePlatformGateway({
    this.allowed = true,
    List<PlatformUserSummaryDto>? summaries,
    this.detail,
  }) : summaries = summaries ?? const [];

  final bool allowed;
  final List<PlatformUserSummaryDto> summaries;
  final PlatformUserDetailDto? detail;

  String? lastSearchQuery;
  PlatformUserStatus? lastSearchStatus;
  String? lastGetUserId;

  @override
  Future<bool> hasPlatformPermission(String permission) async => allowed;

  @override
  Future<List<PlatformUserSummaryDto>> searchPlatformUsers({
    String? query,
    PlatformUserStatus? status,
  }) async {
    lastSearchQuery = query;
    lastSearchStatus = status;
    return summaries;
  }

  @override
  Future<PlatformUserDetailDto> getPlatformUser(String userId) async {
    lastGetUserId = userId;
    return detail ??
        PlatformUserDetailDto(
          userId: userId,
          fullName: 'User',
          email: 'u@example.com',
          status: PlatformUserStatus.active,
          emailVerified: true,
          createdAt: DateTime.utc(2026, 1, 1),
        );
  }

  @override
  Future<void> sendActivationInvitation(String userId) async {}

  @override
  Future<void> requestPasswordReset(String userId) async {}

  @override
  Future<void> suspendPlatformUser({
    required String userId,
    required String reason,
  }) async {}

  @override
  Future<void> restorePlatformUser(String userId) async {}

  @override
  Future<TenantOnboardingResultDto> createTenantOnboarding({
    required OnboardingOwnerInput owner,
    required String organizationName,
    required String idempotencyKey,
    String? correlationId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<PlatformTenantSummaryDto>> searchPlatformTenants({
    String? query,
    TenantLifecycleStatus? status,
  }) async =>
      throw UnimplementedError();

  @override
  Future<PlatformTenantDetailDto> getPlatformTenant(String tenantId) async =>
      throw UnimplementedError();

  @override
  Future<List<PlatformTenantMemberDto>> listPlatformTenantMembers(
    String tenantId,
  ) async =>
      throw UnimplementedError();

  @override
  Future<void> suspendPlatformTenant({
    required String tenantId,
    required String reason,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> restorePlatformTenant(String tenantId) async =>
      throw UnimplementedError();

  @override
  Future<void> transferPlatformTenantOwnership({
    required String tenantId,
    required String newOwnerUserId,
    required String idempotencyKey,
  }) async =>
      throw UnimplementedError();

  @override
  Future<List<PlatformAuditLogSummaryDto>> searchPlatformAuditLogs({
    String? query,
    PlatformAuditLogStatus? status,
  }) async =>
      throw UnimplementedError();

  @override
  Future<PlatformAuditLogDetailDto> getPlatformAuditLog(String auditLogId) async =>
      throw UnimplementedError();

}

void main() {
  group('scn_e01_u01_fr01_01 platform users', () {
    test('users_search_ok — SearchPlatformUsersQuery delegates', () async {
      final gateway = _FakePlatformGateway(
        summaries: [
          PlatformUserSummaryDto(
            userId: 'u-1',
            fullName: 'Nguyen A',
            email: 'a@vet45.local',
            status: PlatformUserStatus.active,
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );
      final handler = SearchPlatformUsersQueryHandler(
        platformGateway: gateway,
      );

      final result = await handler.handle(
        SearchPlatformUsersQuery(
          query: 'a@vet45',
          status: PlatformUserStatus.active,
        ),
      );

      expect(gateway.lastSearchQuery, 'a@vet45');
      expect(gateway.lastSearchStatus, PlatformUserStatus.active);
      expect(result, hasLength(1));
      expect(result.single.email, 'a@vet45.local');
    });

    test('user_detail_ok — GetPlatformUserQuery maps memberships', () async {
      final gateway = _FakePlatformGateway(
        detail: PlatformUserDetailDto(
          userId: 'u-1',
          fullName: 'Nguyen A',
          email: 'a@vet45.local',
          status: PlatformUserStatus.active,
          emailVerified: true,
          createdAt: DateTime.utc(2026, 1, 1),
          memberships: const [
            PlatformUserMembershipDto(
              tenantId: 't-1',
              tenantName: 'Store',
              roleLabel: 'owner',
              isOwner: true,
            ),
          ],
        ),
      );
      final handler = GetPlatformUserQueryHandler(platformGateway: gateway);

      final result = await handler.handle(
        GetPlatformUserQuery(userId: 'u-1'),
      );

      expect(gateway.lastGetUserId, 'u-1');
      expect(result.memberships, hasLength(1));
      expect(result.memberships.single.isOwner, isTrue);
      expect(result.memberships.single.roleLabel, 'owner');
    });

    test('platform permission branch denies missing platform admin', () async {
      final checker = IamPermissionChecker(
        principalSnapshot: _StaffSnapshot(),
        accessGateway: _UnusedAccessGateway(),
        executionContext: _UnusedExecutionContext(),
        platformGateway: _FakePlatformGateway(allowed: false),
      );

      expect(
        () => checker.require(IamPlatformPermissions.userView),
        throwsA(isA<ApplicationException>()),
      );
    });

    test('platform permission branch allows platform admin', () async {
      final checker = IamPermissionChecker(
        principalSnapshot: _StaffSnapshot(),
        accessGateway: _UnusedAccessGateway(),
        executionContext: _UnusedExecutionContext(),
        platformGateway: _FakePlatformGateway(allowed: true),
      );

      await checker.require(IamPlatformPermissions.userView);
    });
  });
}

class _StaffSnapshot implements IPrincipalSnapshot {
  @override
  String? get role => 'staff';

  @override
  bool hasPermission(String code) => false;
}

class _UnusedAccessGateway implements IIamAccessGateway {
  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {}

  @override
  Future<String> bootstrapOwner({String tenantName = 'My Store'}) async =>
      't';

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async =>
      null;

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async =>
      false;

  @override
  Future<bool> isMember(String tenantId) async => false;

  @override
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async => const [];

  @override
  Future<List<TenantMemberDto>> listTenantMembers(String tenantId) async =>
      const [];

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async => const [];

  @override
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) async =>
      throw UnimplementedError();
}

class _UnusedExecutionContext implements IExecutionContext {
  @override
  String get correlationId => 'c';

  @override
  Future<String> requireTenantId() async =>
      throw StateError('tenant must not be required for platform.*');

  @override
  Future<String> requireUserId() async => 'u';
}
