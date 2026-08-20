import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_iam_infrastructure/src/configuration/session/iam_session_coordinator.dart';
import 'package:vet45_shared_application/application.dart';

class _FakeAuthenticator implements IAuthenticator {
  static const _userId = 'user-1';
  static const _email = 'owner@vet45.com';

  var signedOut = false;

  @override
  AuthSessionState get sessionState =>
      signedOut ? AuthSessionState.absent : AuthSessionState.active;

  @override
  String? get currentUserId => signedOut ? null : _userId;

  @override
  String? get currentEmail => signedOut ? null : _email;

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

class _SessionAccessGateway implements IIamAccessGateway {
  _SessionAccessGateway({
    this.accessibleTenants = const [],
    this.sessionContext,
  });

  final List<AccessibleTenantDto> accessibleTenants;
  final PrincipalAccessDto? sessionContext;
  final requestedTenantIds = <String?>[];
  var listAccessibleCallCount = 0;

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) async {
    requestedTenantIds.add(tenantId);
    return sessionContext;
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
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async {
    listAccessibleCallCount++;
    return accessibleTenants;
  }

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

const _accessibleTenant = AccessibleTenantDto(
  tenantId: 'tenant-1',
  name: 'Clinic',
  roleLabel: 'store_owner',
  status: TenantLifecycleStatus.active,
);

const _principal = PrincipalAccessDto(
  userId: 'user-1',
  tenantId: 'tenant-1',
  role: 'store_owner',
  isOwner: true,
  permissions: [],
);

void main() {
  group('IamSessionCoordinator', () {
    test('ERP sign-in with no active membership signs out and blocks', () async {
      final authenticator = _FakeAuthenticator();
      final gateway = _SessionAccessGateway();
      final coordinator = IamSessionCoordinator(
        session: IamSession(),
        accessGateway: gateway,
        authenticator: authenticator,
      );

      await expectLater(
        coordinator.establishAfterSignIn(),
        throwsA(
          isA<IamBlockedException>().having(
            (error) => error.code,
            'code',
            IamBlockedCodes.noActiveMembership,
          ),
        ),
      );

      expect(gateway.listAccessibleCallCount, 1);
      expect(gateway.requestedTenantIds, isEmpty);
      expect(authenticator.signedOut, isTrue);
      expect(coordinator.snapshot.isAuthenticated, isFalse);
    });

    test('ERP sign-in with active membership establishes session', () async {
      final gateway = _SessionAccessGateway(
        accessibleTenants: const [_accessibleTenant],
        sessionContext: _principal,
      );
      final coordinator = IamSessionCoordinator(
        session: IamSession(),
        accessGateway: gateway,
        authenticator: _FakeAuthenticator(),
      );

      await coordinator.establishAfterSignIn();

      expect(gateway.listAccessibleCallCount, 1);
      expect(gateway.requestedTenantIds, [null]);
      expect(coordinator.snapshot.isAuthenticated, isTrue);
      expect(coordinator.snapshot.tenantId, 'tenant-1');
    });

    test('auth-only sign-in succeeds without tenant context', () async {
      final authenticator = _FakeAuthenticator();
      final gateway = _SessionAccessGateway();
      final coordinator = IamSessionCoordinator(
        session: IamSession(),
        accessGateway: gateway,
        authenticator: authenticator,
      );

      await coordinator.establishAfterSignIn(requireTenantContext: false);

      expect(gateway.listAccessibleCallCount, 0);
      expect(gateway.requestedTenantIds, isEmpty);
      expect(authenticator.signedOut, isFalse);
      expect(coordinator.snapshot.isAuthenticated, isTrue);
      expect(coordinator.snapshot.userId, 'user-1');
      expect(coordinator.snapshot.email, 'owner@vet45.com');
      expect(coordinator.snapshot.tenantId, isNull);
      expect(coordinator.snapshot.role, isNull);
      expect(coordinator.snapshot.permissions, isEmpty);
    });

    test('restore without active membership signs out and clears session', () async {
      final authenticator = _FakeAuthenticator();
      final session = IamSession()..apply(_principal);
      final gateway = _SessionAccessGateway();
      final coordinator = IamSessionCoordinator(
        session: session,
        accessGateway: gateway,
        authenticator: authenticator,
      );

      await coordinator.restoreFromPersistedAuth();

      expect(gateway.listAccessibleCallCount, 1);
      expect(gateway.requestedTenantIds, isEmpty);
      expect(authenticator.signedOut, isTrue);
      expect(coordinator.snapshot.isAuthenticated, isFalse);
      expect(coordinator.snapshot.tenantId, isNull);
    });

    test(
      'auth-only restore keeps authenticated user when memberships exist',
      () async {
        final gateway = _SessionAccessGateway(
          accessibleTenants: const [_accessibleTenant],
        );
        final coordinator = IamSessionCoordinator(
          session: IamSession(),
          accessGateway: gateway,
          authenticator: _FakeAuthenticator(),
        );

        await coordinator.restoreFromPersistedAuth(requireTenantContext: false);

        expect(gateway.listAccessibleCallCount, 1);
        expect(gateway.requestedTenantIds, isEmpty);
        expect(coordinator.snapshot.isAuthenticated, isTrue);
        expect(coordinator.snapshot.userId, 'user-1');
        expect(coordinator.snapshot.tenantId, isNull);
      },
    );

    test(
      'auth-only restore signs out when there is no active membership',
      () async {
        final authenticator = _FakeAuthenticator();
        final gateway = _SessionAccessGateway();
        final coordinator = IamSessionCoordinator(
          session: IamSession(),
          accessGateway: gateway,
          authenticator: authenticator,
        );

        await coordinator.restoreFromPersistedAuth(requireTenantContext: false);

        expect(gateway.listAccessibleCallCount, 1);
        expect(authenticator.signedOut, isTrue);
        expect(coordinator.snapshot.isAuthenticated, isFalse);
      },
    );

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
      expect(gateway.listAccessibleCallCount, 0);
    });
  });
}
