import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';

class _FakeAuthenticator implements IAuthenticator {
  _FakeAuthenticator({this.throwOnSignOut = false});

  final bool throwOnSignOut;

  @override
  AuthSessionState get sessionState => AuthSessionState.active;

  @override
  String? get currentEmail => 'owner@vet45.com';

  @override
  String? get currentUserId => 'user-1';

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {
    if (throwOnSignOut) {
      throw Exception('remote fail');
    }
  }
}

class _FakeSessionPort implements IIamSessionPort {
  _FakeSessionPort({this.throwOnClear = false});

  final bool throwOnClear;
  int clearCalls = 0;

  @override
  SessionDto get snapshot => const SessionDto(isAuthenticated: true);

  @override
  Future<void> clear() async {
    clearCalls++;
    if (throwOnClear) {
      throw Exception('local clear fail');
    }
  }

  @override
  Future<void> establishAfterSignIn({
    String? tenantId,
    bool requireTenantContext = true,
  }) async {}

  @override
  Future<void> restoreFromPersistedAuth({
    bool requireTenantContext = true,
  }) async {}
}

void main() {
  test('sign-out success clears local session once', () async {
    final session = _FakeSessionPort();
    final handler = SignOutCommandHandler(
      authenticator: _FakeAuthenticator(),
      sessionPort: session,
    );

    final result = await handler.handle(SignOutCommand());

    expect(result.localCleared, isTrue);
    expect(result.remoteSucceeded, isTrue);
    expect(session.clearCalls, 1);
  });

  test('remote sign-out failure still clears local session once', () async {
    final session = _FakeSessionPort();
    final handler = SignOutCommandHandler(
      authenticator: _FakeAuthenticator(throwOnSignOut: true),
      sessionPort: session,
    );

    final result = await handler.handle(SignOutCommand());

    expect(result.localCleared, isTrue);
    expect(result.remoteSucceeded, isFalse);
    expect(session.clearCalls, 1);
  });

  test('local clear failure is surfaced as error', () async {
    final session = _FakeSessionPort(throwOnClear: true);
    final handler = SignOutCommandHandler(
      authenticator: _FakeAuthenticator(),
      sessionPort: session,
    );

    await expectLater(
      () => handler.handle(SignOutCommand()),
      throwsA(isA<Exception>()),
    );
    expect(session.clearCalls, 1);
  });
}
