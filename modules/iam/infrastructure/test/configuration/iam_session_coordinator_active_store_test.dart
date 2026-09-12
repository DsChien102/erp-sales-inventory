import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_iam_infrastructure/src/configuration/session/iam_session_coordinator.dart';
import 'package:vet45_shared_application/application.dart';

final class _FakeAuthenticator implements IAuthenticator {
  var signedOut = false;

  @override
  AuthSessionState get sessionState => AuthSessionState.active;

  @override
  String? get currentEmail => signedOut ? null : 'user@example.com';

  @override
  String? get currentUserId => signedOut ? null : 'user-1';

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

final class _FakeAccessGateway implements IIamAccessGateway {
  _FakeAccessGateway({
    required this.onGetSessionContext,
    this.accessibleTenants = const [_accessibleTenant],
  });

  final Future<PrincipalAccessDto?> Function(String? tenantId) onGetSessionContext;
  final List<AccessibleTenantDto> accessibleTenants;

  @override
  Future<void> assignMemberRole({
    required String tenantId,
    required String userId,
    required String role,
  }) async {}

  @override
  Future<PrincipalAccessDto?> getSessionContext({String? tenantId}) =>
      onGetSessionContext(tenantId);

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
  Future<List<AccessibleTenantDto>> listAccessibleTenants() async => accessibleTenants;

  @override
  Future<CursorPageDto<TenantMemberDto>> listTenantMembers({
    required String tenantId,
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async => const CursorPageDto<TenantMemberDto>(items: []);

  @override
  Future<TenantContextDto> switchTenantContext({required String targetTenantId}) {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantMembershipDto>> listUserTenants() async => const [];
}

const _accessibleTenant = AccessibleTenantDto(
  tenantId: 'tenant-1',
  name: 'My Store',
  roleLabel: 'member',
  status: TenantLifecycleStatus.active,
);

void main() {
  test('no active membership on establish clears the prior active store', () async {
    final session = _sessionWithOldContext();
    final authenticator = _FakeAuthenticator();
    final coordinator = IamSessionCoordinator(
      session: session,
      authenticator: authenticator,
      accessGateway: _FakeAccessGateway(
        accessibleTenants: const [],
        onGetSessionContext: (_) async =>
            throw ApplicationException('Session context unavailable.'),
      ),
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

    expect(authenticator.signedOut, isTrue);
    _expectCleared(session);
  });

  test('failed explicit tenant switch does not apply a new store', () async {
    final session = _sessionWithOldContext();
    final coordinator = IamSessionCoordinator(
      session: session,
      authenticator: _FakeAuthenticator(),
      accessGateway: _FakeAccessGateway(
        onGetSessionContext: (_) async => null,
      ),
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

    // Explicit tenant path throws before apply; prior snapshot remains until
    // a successful establish/restore or clear.
    expect(session.tenantId, 'tenant-1');
    expect(session.activeStoreId, 'store-1');
  });

  test('successful refresh replaces the active store', () async {
    final session = _sessionWithOldContext();
    final coordinator = IamSessionCoordinator(
      session: session,
      authenticator: _FakeAuthenticator(),
      accessGateway: _FakeAccessGateway(
        onGetSessionContext: (tenantId) async {
          expect(tenantId, isNull);
          return _context(tenantId: 'tenant-2', storeId: 'store-2');
        },
      ),
    );

    await coordinator.establishAfterSignIn();

    expect(session.tenantId, 'tenant-2');
    expect(session.activeStoreId, 'store-2');
  });

  test('failed restore clears the prior active store', () async {
    final session = _sessionWithOldContext();
    final coordinator = IamSessionCoordinator(
      session: session,
      authenticator: _FakeAuthenticator(),
      accessGateway: _FakeAccessGateway(
        onGetSessionContext: (_) async =>
            throw ApplicationException('Session context unavailable.'),
      ),
    );

    await coordinator.restoreFromPersistedAuth();

    _expectCleared(session);
  });

  test('restore without active membership clears the prior active store', () async {
    final session = _sessionWithOldContext();
    final authenticator = _FakeAuthenticator();
    final coordinator = IamSessionCoordinator(
      session: session,
      authenticator: authenticator,
      accessGateway: _FakeAccessGateway(
        accessibleTenants: const [],
        onGetSessionContext: (_) async => _context(
          tenantId: 'tenant-2',
          storeId: 'store-2',
        ),
      ),
    );

    await coordinator.restoreFromPersistedAuth();

    expect(authenticator.signedOut, isTrue);
    _expectCleared(session);
  });
}

IamSession _sessionWithOldContext() {
  final session = IamSession();
  session.apply(_context(tenantId: 'tenant-1', storeId: 'store-1'));
  return session;
}

PrincipalAccessDto _context({
  required String tenantId,
  required String storeId,
}) => PrincipalAccessDto(
  userId: 'user-1',
  tenantId: tenantId,
  activeStoreId: storeId,
  role: 'member',
  isOwner: false,
  permissions: const [],
);

void _expectCleared(IamSession session) {
  expect(session.userId, isNull);
  expect(session.tenantId, isNull);
  expect(session.activeStoreId, isNull);
}
