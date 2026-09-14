import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

class _RecordingAuthenticator implements IAuthenticator {
  String? signedInEmail;
  var signedOut = false;

  @override
  AuthSessionState get sessionState =>
      signedInEmail == null ? AuthSessionState.absent : AuthSessionState.active;

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
    signedOut = true;
    signedInEmail = null;
  }
}

class _RecordingSessionPort implements IIamSessionPort {
  String? appliedUserId;
  PrincipalAccessDto? appliedPrincipal;
  var cleared = false;

  @override
  SessionDto get snapshot => SessionDto(
    isAuthenticated: appliedUserId != null || appliedPrincipal != null,
    userId: appliedUserId ?? appliedPrincipal?.userId,
  );

  @override
  void applyAuthenticatedUser(String userId) {
    appliedUserId = userId;
    appliedPrincipal = null;
  }

  @override
  void apply(PrincipalAccessDto context) {
    appliedPrincipal = context;
    appliedUserId = context.userId;
  }

  @override
  void clear() {
    cleared = true;
    appliedUserId = null;
    appliedPrincipal = null;
  }
}

class _FakePlatformGateway implements IPlatformAdminGateway {
  _FakePlatformGateway({this.allowed = true});

  final bool allowed;

  @override
  Future<bool> hasPlatformPermission(String permission) async => allowed;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  test('SignInTenantUserCommandHandler applies auth-only session', () async {
    final authenticator = _RecordingAuthenticator();
    final sessionPort = _RecordingSessionPort();
    final handler = SignInTenantUserCommandHandler(
      authenticator: authenticator,
      sessionPort: sessionPort,
    );

    await handler.handle(
      SignInTenantUserCommand(email: 'owner@vet45.com', password: 'secret'),
    );

    expect(authenticator.signedInEmail, 'owner@vet45.com');
    expect(sessionPort.appliedUserId, 'user-1');
    expect(sessionPort.appliedPrincipal, isNull);
  });

  test('SignInPlatformAdminCommandHandler allows platform admin', () async {
    final authenticator = _RecordingAuthenticator();
    final sessionPort = _RecordingSessionPort();
    final handler = SignInPlatformAdminCommandHandler(
      authenticator: authenticator,
      sessionPort: sessionPort,
      platformAdminGateway: _FakePlatformGateway(allowed: true),
    );

    await handler.handle(
      SignInPlatformAdminCommand(email: 'admin@vet45.com', password: 'secret'),
    );

    expect(authenticator.signedInEmail, 'admin@vet45.com');
    expect(sessionPort.appliedUserId, 'user-1');
    expect(authenticator.signedOut, isFalse);
  });

  test('SignInPlatformAdminCommandHandler denies without platform permission', () async {
    final authenticator = _RecordingAuthenticator();
    final sessionPort = _RecordingSessionPort();
    final handler = SignInPlatformAdminCommandHandler(
      authenticator: authenticator,
      sessionPort: sessionPort,
      platformAdminGateway: _FakePlatformGateway(allowed: false),
    );

    await expectLater(
      handler.handle(
        SignInPlatformAdminCommand(email: 'user@vet45.com', password: 'secret'),
      ),
      throwsA(
        isA<IamBlockedException>().having(
          (e) => e.code,
          'code',
          IamBlockedCodes.platformPermissionDenied,
        ),
      ),
    );
    expect(authenticator.signedOut, isTrue);
    expect(sessionPort.cleared, isTrue);
  });
}
