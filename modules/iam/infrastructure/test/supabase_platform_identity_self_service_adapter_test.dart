import 'package:test/test.dart';
import 'package:gotrue/gotrue.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';

void main() {
  group('SupabasePlatformIdentitySelfServiceAdapter', () {
    test('getMyAccount joins IAM profile with Supabase Auth email', () async {
      final adapter = SupabasePlatformIdentitySelfServiceAdapter(
        profileGateway: _FakeProfileGateway(),
        authClient: _FakeAuthClient(
          userId: 'user-1',
          email: 'lan@gmail.com',
          verified: true,
        ),
      );

      final account = await adapter.getMyAccount();

      expect(account.userId, 'user-1');
      expect(account.email, 'lan@gmail.com');
      expect(account.givenName, 'Lan');
      expect(account.familyName, 'Le');
      expect(account.emailVerified, isTrue);
    });

    test('updateMyAccount persists profile and keeps Auth email', () async {
      final gateway = _FakeProfileGateway();
      final authClient = _FakeAuthClient(
        userId: 'user-1',
        email: 'lan@gmail.com',
        verified: false,
      );
      final adapter = SupabasePlatformIdentitySelfServiceAdapter(
        profileGateway: gateway,
        authClient: authClient,
      );

      final account = await adapter.updateMyAccount(
        avatarReference: 'ref-2',
        givenName: 'Lan',
        familyName: 'Nguyen',
        phone: '+84900000000',
      );

      expect(account.familyName, 'Nguyen');
      expect(account.avatarReference, 'ref-2');
      expect(account.email, 'lan@gmail.com');
      expect(account.emailVerified, isFalse);
      expect(gateway.updateCalls, 1);
      expect(authClient.sendRecoveryOtpCalls, 0);
      expect(authClient.verifyRecoveryOtpCalls, 0);
      expect(authClient.updatePasswordCalls, 0);
      expect(authClient.signOutOtherSessionsCalls, 0);
      expect(gateway.lastUpdate?.familyName, 'Nguyen');
    });

    test('reflects unverified Auth state', () async {
      final adapter = SupabasePlatformIdentitySelfServiceAdapter(
        profileGateway: _FakeProfileGateway(),
        authClient: _FakeAuthClient(
          userId: 'user-1',
          email: 'lan@gmail.com',
          verified: false,
        ),
      );

      final account = await adapter.getMyAccount();
      expect(account.emailVerified, isFalse);
    });

    test('throws AUTHENTICATION_REQUIRED when no current user', () async {
      final adapter = SupabasePlatformIdentitySelfServiceAdapter(
        profileGateway: _FakeProfileGateway(),
        authClient: _FakeAuthClient(userId: null, email: null, verified: false),
      );

      expect(
        () => adapter.getMyAccount(),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.authenticationRequired,
          ),
        ),
      );
    });

    test('password reset fails with SYSTEM_ERROR when no store wired', () {
      final adapter = SupabasePlatformIdentitySelfServiceAdapter(
        profileGateway: _FakeProfileGateway(),
        authClient: _FakeAuthClient(
          userId: 'user-1',
          email: 'lan@gmail.com',
          verified: true,
        ),
      );

      expect(
        () => adapter.requestPasswordReset(),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.systemError,
          ),
        ),
      );
    });

    test('request/resend/verify/complete use locked DTOs and side effects once', () async {
      final authClient = _FakeAuthClient(
        userId: 'user-1',
        email: 'lan@gmail.com',
        verified: true,
      );
      final store = _FakePasswordResetOperationStore();
      final adapter = SupabasePlatformIdentitySelfServiceAdapter(
        profileGateway: _FakeProfileGateway(),
        authClient: authClient,
        passwordResetStore: store,
      );

      final requestResult = await adapter.requestPasswordReset();
      final resendResult = await adapter.resendPasswordResetCode(
        operationId: requestResult.operationId,
      );
      final verifyResult = await adapter.verifyPasswordResetCode(
        operationId: requestResult.operationId,
        code: '123456',
      );
      final completeResult = await adapter.completePasswordReset(
        operationId: requestResult.operationId,
        newPassword: 'Password#123',
      );

      expect(requestResult, isA<PasswordResetRequestResultDto>());
      expect(
        resendResult.resendAvailableAt.isAfter(requestResult.resendAvailableAt),
        isTrue,
      );
      expect(verifyResult.verified, isTrue);
      expect(completeResult.currentSessionRotated, isTrue);
      expect(completeResult.otherSessionsRevoked, isTrue);
      expect(authClient.updatePasswordCalls, 1);
      expect(authClient.signOutOtherSessionsCalls, 1);
      expect(store.markVerifiedCalls, 1);
      expect(store.markCompletedCalls, 1);
      expect(authClient.lastPassword, isNull);
      expect(authClient.lastRecoveryCode, isNull);
    });

    test('verify maps known invalid/rotated OTP to RESET_CODE_INVALID', () async {
      final authClient = _FakeAuthClient(
        userId: 'user-1',
        email: 'lan@gmail.com',
        verified: true,
      )..verifyFailure = AuthException('invalid otp', code: 'invalid_otp');
      final adapter = SupabasePlatformIdentitySelfServiceAdapter(
        profileGateway: _FakeProfileGateway(),
        authClient: authClient,
        passwordResetStore: _FakePasswordResetOperationStore(),
      );
      final request = await adapter.requestPasswordReset();

      await expectLater(
        () => adapter.verifyPasswordResetCode(
          operationId: request.operationId,
          code: '000000',
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.resetCodeInvalid,
          ),
        ),
      );
    });

    test('verify maps provider attempts exceeded to RESET_CODE_ATTEMPTS_EXCEEDED', () async {
      final authClient = _FakeAuthClient(
        userId: 'user-1',
        email: 'lan@gmail.com',
        verified: true,
      )..verifyFailure = AuthException('too many attempts', code: 'otp_too_many_attempts');
      final adapter = SupabasePlatformIdentitySelfServiceAdapter(
        profileGateway: _FakeProfileGateway(),
        authClient: authClient,
        passwordResetStore: _FakePasswordResetOperationStore(),
      );
      final request = await adapter.requestPasswordReset();

      await expectLater(
        () => adapter.verifyPasswordResetCode(
          operationId: request.operationId,
          code: '000000',
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.resetCodeAttemptsExceeded,
          ),
        ),
      );
    });

    test('verify maps unknown provider failure to SYSTEM_ERROR', () async {
      final authClient = _FakeAuthClient(
        userId: 'user-1',
        email: 'lan@gmail.com',
        verified: true,
      )..verifyFailure = Exception('socket hang up');
      final adapter = SupabasePlatformIdentitySelfServiceAdapter(
        profileGateway: _FakeProfileGateway(),
        authClient: authClient,
        passwordResetStore: _FakePasswordResetOperationStore(),
      );
      final request = await adapter.requestPasswordReset();

      await expectLater(
        () => adapter.verifyPasswordResetCode(
          operationId: request.operationId,
          code: '000000',
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.systemError,
          ),
        ),
      );
    });

    test('complete maps weak password to PASSWORD_POLICY_VIOLATION', () async {
      final authClient = _FakeAuthClient(
        userId: 'user-1',
        email: 'lan@gmail.com',
        verified: true,
      )..updatePasswordFailure = AuthException('weak password', code: 'weak_password');
      final adapter = SupabasePlatformIdentitySelfServiceAdapter(
        profileGateway: _FakeProfileGateway(),
        authClient: authClient,
        passwordResetStore: _FakePasswordResetOperationStore(),
      );
      final request = await adapter.requestPasswordReset();
      await adapter.verifyPasswordResetCode(
        operationId: request.operationId,
        code: '123456',
      );

      await expectLater(
        () => adapter.completePasswordReset(
          operationId: request.operationId,
          newPassword: 'weak',
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.passwordPolicyViolation,
          ),
        ),
      );
    });

    test('complete maps revoke-other-sessions failure to SYSTEM_ERROR', () async {
      final authClient = _FakeAuthClient(
        userId: 'user-1',
        email: 'lan@gmail.com',
        verified: true,
      )..signOutOtherSessionsFailure = Exception('network');
      final adapter = SupabasePlatformIdentitySelfServiceAdapter(
        profileGateway: _FakeProfileGateway(),
        authClient: authClient,
        passwordResetStore: _FakePasswordResetOperationStore(),
      );
      final request = await adapter.requestPasswordReset();
      await adapter.verifyPasswordResetCode(
        operationId: request.operationId,
        code: '123456',
      );

      await expectLater(
        () => adapter.completePasswordReset(
          operationId: request.operationId,
          newPassword: 'Password#123',
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.systemError,
          ),
        ),
      );
    });
  });
}

final class _FakeAuthClient implements AuthAccountClient {
  _FakeAuthClient({
    required this.userId,
    required this.email,
    required this.verified,
  });

  final String? userId;
  final String? email;
  final bool verified;
  int updatePasswordCalls = 0;
  int sendRecoveryOtpCalls = 0;
  int verifyRecoveryOtpCalls = 0;
  int signOutOtherSessionsCalls = 0;
  String? lastPassword;
  String? lastRecoveryCode;
  Object? verifyFailure;
  Object? updatePasswordFailure;
  Object? signOutOtherSessionsFailure;

  @override
  String? get currentUserId => userId;

  @override
  String? get currentEmail => email;

  @override
  bool get isEmailVerified => verified;

  @override
  Future<void> sendRecoveryOtp({required String email}) async {
    sendRecoveryOtpCalls++;
  }

  @override
  Future<void> verifyRecoveryOtp({
    required String email,
    required String code,
  }) async {
    if (verifyFailure != null) {
      throw verifyFailure!;
    }
    verifyRecoveryOtpCalls++;
    lastRecoveryCode = code;
    // do not keep sensitive raw values after call
    lastRecoveryCode = null;
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    if (updatePasswordFailure != null) {
      throw updatePasswordFailure!;
    }
    updatePasswordCalls++;
    lastPassword = newPassword;
    // do not keep sensitive raw values after call
    lastPassword = null;
  }

  @override
  Future<void> signOutOtherSessions() async {
    if (signOutOtherSessionsFailure != null) {
      throw signOutOtherSessionsFailure!;
    }
    signOutOtherSessionsCalls++;
  }
}

final class _FakeProfileGateway implements PlatformUserProfileGateway {
  ({String givenName, String familyName})? lastUpdate;
  int updateCalls = 0;

  @override
  Future<PlatformUserProfileSnapshot> getMyProfile() async {
    return const PlatformUserProfileSnapshot(
      userId: 'user-1',
      givenName: 'Lan',
      familyMiddleName: 'Le',
      phoneNumber: '+84901234567',
      avatarReference: 'ref-1',
      status: 'active',
    );
  }

  @override
  Future<PlatformUserProfileSnapshot> updateMyProfile({
    required String? avatarReference,
    required String givenName,
    required String familyName,
    required String? phone,
  }) async {
    updateCalls++;
    lastUpdate = (givenName: givenName, familyName: familyName);
    return PlatformUserProfileSnapshot(
      userId: 'user-1',
      givenName: givenName,
      familyMiddleName: familyName,
      phoneNumber: phone,
      avatarReference: avatarReference,
      status: 'active',
    );
  }
}

final class _FakePasswordResetOperationStore implements PasswordResetOperationStore {
  String _status = 'pending';
  int markVerifiedCalls = 0;
  int markCompletedCalls = 0;

  @override
  Future<PasswordResetOperation> begin() async {
    _status = 'pending';
    final now = DateTime.now().toUtc();
    return PasswordResetOperation(
      operationId: 'op-1',
      userId: 'user-1',
      status: _status,
      expiresAt: now.add(const Duration(minutes: 10)),
      resendAvailableAt: now.subtract(const Duration(seconds: 1)),
    );
  }

  @override
  Future<PasswordResetOperation> get(String operationId) async {
    final now = DateTime.now().toUtc();
    return PasswordResetOperation(
      operationId: operationId,
      userId: 'user-1',
      status: _status,
      expiresAt: now.add(const Duration(minutes: 10)),
      resendAvailableAt: now.subtract(const Duration(seconds: 1)),
    );
  }

  @override
  Future<void> markCompleted(String operationId) async {
    markCompletedCalls++;
    _status = 'completed';
  }

  @override
  Future<void> markVerified(String operationId) async {
    markVerifiedCalls++;
    _status = 'verified';
  }

  @override
  Future<PasswordResetOperation> touchResend(String operationId) async {
    final now = DateTime.now().toUtc();
    return PasswordResetOperation(
      operationId: operationId,
      userId: 'user-1',
      status: _status,
      expiresAt: now.add(const Duration(minutes: 15)),
      resendAvailableAt: now.add(const Duration(minutes: 1)),
    );
  }
}
