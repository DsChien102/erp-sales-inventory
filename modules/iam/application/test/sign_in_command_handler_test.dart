import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';

class _RecordingAuthenticator implements IAuthenticator {
  String? signedInEmail;

  @override
  String? get currentEmail => signedInEmail;

  @override
  String? get currentUserId => signedInEmail == null ? null : 'user-1';

  @override
  Future<void> signIn({required String email, required String password}) async {
    signedInEmail = email;
  }

  @override
  Future<void> signOut() async {
    signedInEmail = null;
  }
}

class _RecordingSessionPort implements IIamSessionPort {
  var established = false;

  @override
  SessionDto get snapshot => SessionDto(
    isAuthenticated: established,
    userId: established ? 'user-1' : null,
    email: 'test@vet45.com',
  );

  @override
  Future<void> clear() async {
    established = false;
  }

  @override
  Future<void> establishAfterSignIn({String? tenantId}) async {
    established = true;
  }

  @override
  Future<void> restoreFromPersistedAuth() async {}
}

void main() {
  test('SignInCommandHandler signs in and establishes session', () async {
    final authenticator = _RecordingAuthenticator();
    final sessionPort = _RecordingSessionPort();
    final handler = SignInCommandHandler(
      authenticator: authenticator,
      sessionPort: sessionPort,
    );

    await handler.handle(
      SignInCommand(email: 'owner@vet45.com', password: 'secret'),
    );

    expect(authenticator.signedInEmail, 'owner@vet45.com');
    expect(sessionPort.established, isTrue);
  });
}
