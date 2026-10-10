import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'fake_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';

class _MockAuth extends Mock implements GoTrueClient {}

class _MockUser extends Mock implements User {}

class _MockAuthSession extends Mock implements Session {}

void main() {
  late _MockAuth auth;
  late StreamController<AuthState> events;

  setUp(() {
    auth = _MockAuth();
    events = StreamController<AuthState>.broadcast();
    when(() => auth.onAuthStateChange).thenAnswer((_) => events.stream);
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await events.close();
  });

  SessionController controller({
    FakeSessionRepository? repository,
    IamSession? iamSession,
    SessionState? initialState,
    Stream<String>? tenantAccessRevoked,
    DateTime Function()? clock,
  }) {
    return SessionController(
      repository: repository ?? FakeSessionRepository(),
      auth: auth,
      iamSession: iamSession,
      initialState: initialState,
      tenantAccessRevoked: tenantAccessRevoked,
      clock: clock,
    );
  }

  test('start with a current user signs in and applies the user once', () {
    final user = _MockUser();
    when(() => user.id).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);
    final iam = IamSession();

    final cubit = controller(iamSession: iam);
    cubit.start();

    expect(cubit.state.authStatus, AuthStatus.signedIn);
    expect(cubit.state.userId, 'user-1');
    expect(iam.userId, 'user-1');

    cubit.close();
  });

  test('start without a current user signs out and clears the session', () {
    when(() => auth.currentUser).thenReturn(null);
    final iam = IamSession()..applyAuthenticatedUser('old');

    final cubit = controller(iamSession: iam);
    cubit.start();

    expect(cubit.state.authStatus, AuthStatus.signedOut);
    expect(iam.userId, isNull);

    cubit.close();
  });

  test('signedOut event resets state', () async {
    final user = _MockUser();
    when(() => user.id).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);

    final cubit = controller(
      initialState: const SessionState(
        authStatus: AuthStatus.signedIn,
        userId: 'user-1',
        userDisplayName: 'Lan',
        branchDisplayName: 'Cũ',
      ),
    );
    cubit.start();

    events.add(const AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.authStatus, AuthStatus.signedOut);
    expect(cubit.state.userId, isNull);
    expect(cubit.state.branchDisplayName, isNull);
    expect(cubit.state.userDisplayName, isEmpty);

    await cubit.close();
  });

  test('repeated signedIn for the same user does not clear tenant', () async {
    final user = _MockUser();
    when(() => user.id).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(user);
    final authSession = _MockAuthSession();
    when(() => authSession.user).thenReturn(user);
    final iam = IamSession();

    final cubit = controller(iamSession: iam);
    cubit.start();
    iam.apply(
      const PrincipalAccessDto(
        userId: 'user-1',
        tenantId: 'org-001',
        role: 'staff',
        isOwner: false,
        permissions: ['tenant.access'],
      ),
    );

    events.add(AuthState(AuthChangeEvent.signedIn, authSession));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.authStatus, AuthStatus.signedIn);
    expect(iam.tenantId, 'org-001');

    await cubit.close();
  });

  test('signing in a different user drops the previous organization', () async {
    final iam = IamSession()..applyAuthenticatedUser('user-a');
    final repository = FakeSessionRepository();
    final cubit = controller(
      repository: repository,
      iamSession: iam,
      initialState: const SessionState(
        authStatus: AuthStatus.signedIn,
        userId: 'user-a',
      ),
    );
    await cubit.bootstrap();
    expect(cubit.state.current?.tenantId, 'org-001');
    expect(cubit.state.tenants, isNotEmpty);

    cubit.applySignedInUser('user-b');

    expect(cubit.state.authStatus, AuthStatus.signedIn);
    expect(cubit.state.userId, 'user-b');
    expect(cubit.state.current, isNull);
    expect(cubit.state.tenants, isEmpty);
    expect(cubit.tenantId, isNull);

    await cubit.close();
  });

  test('requireTenantId without a tenant throws AUTHENTICATION_REQUIRED', () async {
    final cubit = controller(iamSession: IamSession());

    expect(
      cubit.requireTenantId,
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          AppErrorCode.authRequired,
        ),
      ),
    );

    await cubit.close();
  });

  test('signOut clears local session even when remote sign-out fails', () async {
    when(() => auth.signOut()).thenThrow(Exception('sign-out failed'));
    final iam = IamSession()..applyAuthenticatedUser('user-1');
    final cubit = controller(
      iamSession: iam,
      initialState: const SessionState(
        authStatus: AuthStatus.signedIn,
        userId: 'user-1',
      ),
    );

    final result = await cubit.signOut();

    expect(result.localCleared, isTrue);
    expect(result.remoteSucceeded, isFalse);
    expect(cubit.state.authStatus, AuthStatus.signedOut);
    expect(iam.userId, isNull);

    await cubit.close();
  });

  test('switchTo the current organization is a validation error', () async {
    final iam = IamSession()..applyAuthenticatedUser('user-1');
    final cubit = controller(iamSession: iam);
    await cubit.bootstrap();

    final ok = await cubit.switchTo('org-001');

    expect(ok, isFalse);
    expect(cubit.state.switchFailure?.code, AppErrorCode.validation);
    expect(
      cubit.state.switchFailure?.message,
      'Target tenant must differ from the current tenant context',
    );

    await cubit.close();
  });

  test('setLastSelected failure rolls the session back to the previous tenant', () async {
    final iam = IamSession()..applyAuthenticatedUser('user-1');
    final repository = FakeSessionRepository();
    final cubit = controller(repository: repository, iamSession: iam);
    await cubit.bootstrap();
    expect(iam.tenantId, 'org-001');

    repository.failSetLastSelected = true;
    final ok = await cubit.switchTo('org-002');

    expect(ok, isFalse);
    expect(cubit.state.switchFailure?.code, AppErrorCode.unknown);
    expect(iam.tenantId, 'org-001');
    expect(repository.lastSelectedTenantId, 'org-001');

    await cubit.close();
  });

  test('bootstrap without a last selected tenant adopts the first selectable one', () async {
    final repository = FakeSessionRepository(scenario: FakeIamScenario.contextNone);
    final cubit = controller(repository: repository, iamSession: IamSession());

    await cubit.bootstrap();

    expect(cubit.state.isValid, isTrue);
    expect(cubit.state.current?.tenantId, 'org-001');
    expect(repository.lastSelectedTenantId, 'org-001');

    await cubit.close();
  });

  test('bootstrap with only a suspended tenant stays invalidated', () async {
    final repository = FakeSessionRepository(suspendedOnly: true);
    final cubit = controller(repository: repository);

    await cubit.bootstrap();

    expect(cubit.state.isBlocked, isTrue);
    expect(cubit.state.hasNoOrganization, isFalse);
    expect(cubit.state.current?.tenantId, 'org-003');
    expect(cubit.state.emptyStateType, OrganizationEmptyStateType.inaccessible);

    await cubit.close();
  });

  test('bootstrap with no tenants is blocked as no organization', () async {
    final repository = FakeSessionRepository(noTenants: true);
    final cubit = controller(repository: repository);

    await cubit.bootstrap();

    expect(cubit.state.hasNoOrganization, isTrue);
    expect(cubit.state.current?.status, TenantContextStatus.none);

    await cubit.close();
  });

  test('PERMISSION_DENIED with a valid context does not bootstrap', () async {
    final revoked = StreamController<String>.broadcast();
    final repository = FakeSessionRepository();
    final cubit = controller(
      repository: repository,
      iamSession: IamSession(),
      tenantAccessRevoked: revoked.stream,
    );
    await cubit.bootstrap();
    final reads = repository.tenantContextReads;
    final statuses = <TenantLoadStatus>[];
    final sub = cubit.stream.listen((state) => statuses.add(state.status));

    revoked.add(TenantAccessRevokedSignal.permissionDenied);
    await Future<void>.delayed(Duration.zero);

    expect(repository.tenantContextReads, reads + 1);
    expect(statuses, isEmpty);
    expect(cubit.state.status, TenantLoadStatus.ready);
    expect(cubit.state.current?.tenantId, 'org-001');

    await sub.cancel();
    await cubit.close();
    await revoked.close();
  });

  test('PERMISSION_DENIED after membership removal bootstraps another organization', () async {
    final revoked = StreamController<String>.broadcast();
    final repository = FakeSessionRepository();
    final cubit = controller(
      repository: repository,
      iamSession: IamSession(),
      tenantAccessRevoked: revoked.stream,
    );
    await cubit.bootstrap();
    expect(cubit.state.current?.tenantId, 'org-001');
    repository.removeMembership('org-001');

    revoked.add(TenantAccessRevokedSignal.permissionDenied);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, TenantLoadStatus.ready);
    expect(cubit.state.current?.tenantId, 'org-002');
    expect(cubit.state.hasNoOrganization, isFalse);

    await cubit.close();
    await revoked.close();
  });

  test('PERMISSION_DENIED with no remaining organization is hasNoOrganization', () async {
    final revoked = StreamController<String>.broadcast();
    final repository = FakeSessionRepository();
    final cubit = controller(
      repository: repository,
      iamSession: IamSession(),
      tenantAccessRevoked: revoked.stream,
    );
    await cubit.bootstrap();
    repository.removeMembership('org-001');
    repository.removeMembership('org-002');
    repository.removeMembership('org-003');

    revoked.add(TenantAccessRevokedSignal.permissionDenied);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.hasNoOrganization, isTrue);

    await cubit.close();
    await revoked.close();
  });

  test('two PERMISSION_DENIED signals within 30 seconds check context once', () async {
    var now = DateTime.utc(2026, 10, 10, 8);
    final revoked = StreamController<String>.broadcast();
    final repository = FakeSessionRepository();
    final cubit = controller(
      repository: repository,
      iamSession: IamSession(),
      tenantAccessRevoked: revoked.stream,
      clock: () => now,
    );
    await cubit.bootstrap();
    final reads = repository.tenantContextReads;

    revoked.add(TenantAccessRevokedSignal.permissionDenied);
    await Future<void>.delayed(Duration.zero);
    revoked.add(TenantAccessRevokedSignal.permissionDenied);
    await Future<void>.delayed(Duration.zero);

    expect(repository.tenantContextReads, reads + 1);

    now = now.add(const Duration(seconds: 30));
    revoked.add(TenantAccessRevokedSignal.permissionDenied);
    await Future<void>.delayed(Duration.zero);

    expect(repository.tenantContextReads, reads + 2);

    await cubit.close();
    await revoked.close();
  });

  test('holdSignedInApply ignores auth signedIn until applySignedInUser', () async {
    final user = _MockUser();
    when(() => user.id).thenReturn('user-1');
    when(() => auth.currentUser).thenReturn(null);
    final authSession = _MockAuthSession();
    when(() => authSession.user).thenReturn(user);

    final cubit = controller();
    cubit.start();
    cubit.holdSignedInApply();

    events.add(AuthState(AuthChangeEvent.signedIn, authSession));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.authStatus, AuthStatus.signedOut);

    cubit.applySignedInUser('user-1');
    expect(cubit.state.authStatus, AuthStatus.signedIn);
    expect(cubit.state.userId, 'user-1');

    await cubit.close();
  });

  test('bootstrap while held then applySignedInUser keeps the tenant and store', () async {
    final repository = FakeSessionRepository(scenario: FakeIamScenario.contextNone);
    final iam = IamSession();
    final cubit = controller(repository: repository, iamSession: iam);
    cubit.holdSignedInApply();

    await cubit.bootstrap();
    expect(cubit.tenantId, 'org-001');

    cubit.applySignedInUser('user-1');

    expect(cubit.state.authStatus, AuthStatus.signedIn);
    expect(cubit.state.isValid, isTrue);
    expect(cubit.tenantId, 'org-001');
    expect(cubit.activeStoreId, 'store-org-001');

    await cubit.close();
  });
}
