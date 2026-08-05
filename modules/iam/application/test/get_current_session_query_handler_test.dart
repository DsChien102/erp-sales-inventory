import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

class _FakeAuthenticator implements IAuthenticator {
  _FakeAuthenticator(this._state);

  final AuthSessionState _state;

  @override
  AuthSessionState get sessionState => _state;

  @override
  String? get currentEmail => 'owner@vet45.com';

  @override
  String? get currentUserId => 'user-1';

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeSessionPort implements IIamSessionPort {
  var clearCalled = 0;

  @override
  SessionDto get snapshot => const SessionDto(
    isAuthenticated: true,
    userId: 'user-1',
    email: 'owner@vet45.com',
  );

  @override
  Future<void> clear() async {
    clearCalled++;
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
  test('returns unauthenticated snapshot when session is absent', () async {
    final sessionPort = _FakeSessionPort();
    final handler = GetCurrentSessionQueryHandler(
      authenticator: _FakeAuthenticator(AuthSessionState.absent),
      sessionPort: sessionPort,
    );

    final result = await handler.handle(GetCurrentSessionQuery());

    expect(result.isAuthenticated, isFalse);
    expect(sessionPort.clearCalled, 0);
  });

  test('returns current snapshot when session is active', () async {
    final sessionPort = _FakeSessionPort();
    final handler = GetCurrentSessionQueryHandler(
      authenticator: _FakeAuthenticator(AuthSessionState.active),
      sessionPort: sessionPort,
    );

    final result = await handler.handle(GetCurrentSessionQuery());

    expect(result.isAuthenticated, isTrue);
    expect(result.userId, 'user-1');
    expect(sessionPort.clearCalled, 0);
  });

  test('clears local session and throws SESSION_EXPIRED when expired', () async {
    final sessionPort = _FakeSessionPort();
    final handler = GetCurrentSessionQueryHandler(
      authenticator: _FakeAuthenticator(AuthSessionState.expired),
      sessionPort: sessionPort,
    );

    expect(
      () => handler.handle(GetCurrentSessionQuery()),
      throwsA(
        predicate(
          (e) => e is ApplicationException && e.toString().contains('SESSION_EXPIRED'),
        ),
      ),
    );
    expect(sessionPort.clearCalled, 1);
  });
}
