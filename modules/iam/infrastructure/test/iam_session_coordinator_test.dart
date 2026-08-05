import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_iam_infrastructure/src/configuration/session/iam_session_coordinator.dart';
import 'package:vet45_shared_application/application.dart';

class _FakeAuthenticator implements IAuthenticator {
  static const _userId = 'user-1';
  static const _email = 'owner@vet45.com';

  @override
  AuthSessionState get sessionState => AuthSessionState.active;

  @override
  String? get currentUserId => _userId;

  @override
  String? get currentEmail => _email;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}
}

class _SessionAccessGateway implements IIamAccessGateway {
  final requestedTenantIds = <String?>[];

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async {
    requestedTenantIds.add(tenantId);
    return null;
  }

  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {}

  @override
  Future<TenantContextDto> getValidatedTenantContext({
    String? sessionTenantId,
  }) async => throw UnimplementedError();

  @override
  Future<bool> hasPermission({
    required String tenantId,
    required String permission,
  }) async => false;

  @override
  Future<bool> isMember(String tenantId) async => false;

  @override
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async => const [];

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
  Future<TenantContextDto> switchTenantContext({
    required String targetTenantId,
  }) async => throw UnimplementedError();
}

void main() {
  group('IamSessionCoordinator', () {
    test('sign-in without a tenant context fails without bootstrap', () async {
      final gateway = _SessionAccessGateway();
      final coordinator = IamSessionCoordinator(
        session: IamSession(),
        accessGateway: gateway,
        authenticator: _FakeAuthenticator(),
      );

      await expectLater(
        coordinator.establishAfterSignIn(),
        throwsA(
          isA<ApplicationException>().having(
            (error) => error.message,
            'message',
            'Failed to establish IAM session',
          ),
        ),
      );

      expect(gateway.requestedTenantIds, [null]);
    });

    test('auth-only sign-in succeeds without tenant context', () async {
      final gateway = _SessionAccessGateway();
      final coordinator = IamSessionCoordinator(
        session: IamSession(),
        accessGateway: gateway,
        authenticator: _FakeAuthenticator(),
      );

      await coordinator.establishAfterSignIn(requireTenantContext: false);

      expect(gateway.requestedTenantIds, isEmpty);
      expect(coordinator.snapshot.isAuthenticated, isTrue);
      expect(coordinator.snapshot.userId, 'user-1');
      expect(coordinator.snapshot.email, 'owner@vet45.com');
      expect(coordinator.snapshot.tenantId, isNull);
      expect(coordinator.snapshot.role, isNull);
      expect(coordinator.snapshot.permissions, isEmpty);
    });

    test('restore without a tenant context clears session without bootstrap', () async {
      final session = IamSession()
        ..apply(
          const PrincipalAccessDto(
            userId: 'user-1',
            tenantId: 'tenant-1',
            role: 'owner',
            permissions: [],
          ),
        );
      final gateway = _SessionAccessGateway();
      final coordinator = IamSessionCoordinator(
        session: session,
        accessGateway: gateway,
        authenticator: _FakeAuthenticator(),
      );

      await coordinator.restoreFromPersistedAuth();

      expect(gateway.requestedTenantIds, [null]);
      expect(coordinator.snapshot.isAuthenticated, isFalse);
      expect(coordinator.snapshot.tenantId, isNull);
    });

    test('auth-only restore keeps authenticated user without tenant context', () async {
      final gateway = _SessionAccessGateway();
      final coordinator = IamSessionCoordinator(
        session: IamSession(),
        accessGateway: gateway,
        authenticator: _FakeAuthenticator(),
      );

      await coordinator.restoreFromPersistedAuth(requireTenantContext: false);

      expect(gateway.requestedTenantIds, isEmpty);
      expect(coordinator.snapshot.isAuthenticated, isTrue);
      expect(coordinator.snapshot.userId, 'user-1');
      expect(coordinator.snapshot.tenantId, isNull);
    });

    test('explicit tenant access denial still fails', () async {
      final gateway = _SessionAccessGateway();
      final coordinator = IamSessionCoordinator(
        session: IamSession(),
        accessGateway: gateway,
        authenticator: _FakeAuthenticator(),
      );

      await expectLater(
        coordinator.establishAfterSignIn(tenantId: 'tenant-2'),
        throwsA(
          isA<ApplicationException>().having(
            (error) => error.message,
            'message',
            'Tenant access denied',
          ),
        ),
      );

      expect(gateway.requestedTenantIds, ['tenant-2']);
    });
  });
}
