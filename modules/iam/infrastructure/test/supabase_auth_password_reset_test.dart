import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';

void main() {
  SupabasePlatformIdentitySelfServiceAdapter buildAdapter(
    _FakeStore store,
    _FakeAuth auth,
  ) {
    return SupabasePlatformIdentitySelfServiceAdapter(
      profileGateway: _StubProfileGateway(),
      authClient: auth,
      passwordResetStore: store,
    );
  }

  test('request -> verify -> complete happy path retains current session', () async {
    final store = _FakeStore();
    final auth = _FakeAuth();
    final adapter = buildAdapter(store, auth);

    final request = await adapter.requestPasswordReset();
    expect(request.maskedEmail, 'l***@gmail.com');
    expect(store.beginCalls, 1);

    await adapter.verifyPasswordResetCode(
      operationId: request.operationId,
      code: '123456',
    );
    expect(store.operations[request.operationId]!.status, 'verified');

    final completed = await adapter.completePasswordReset(
      operationId: request.operationId,
      newPassword: 'NewSecurePass1',
    );
    expect(completed.currentSessionRotated, isTrue);
    expect(completed.otherSessionsRevoked, isTrue);
    expect(auth.passwordUpdates, 1);
    expect(auth.otherSessionsSignedOut, 1);
    expect(store.operations[request.operationId]!.status, 'completed');
  });

  test('resend returns refreshed PasswordResetRequestResultDto', () async {
    final store = _FakeStore();
    final auth = _FakeAuth();
    final adapter = buildAdapter(store, auth);
    final request = await adapter.requestPasswordReset();
    // Unlock resend window.
    store.operations[request.operationId]!.resendAvailableAt =
        DateTime.now().toUtc().subtract(const Duration(seconds: 1));

    final resent = await adapter.resendPasswordResetCode(
      operationId: request.operationId,
    );
    expect(resent.operationId, request.operationId);
    expect(resent.maskedEmail, 'l***@gmail.com');
    expect(resent.expiresAt.isAfter(resent.resendAvailableAt), isTrue);
  });

  test('responses never include raw code/password/token', () async {
    final adapter = buildAdapter(_FakeStore(), _FakeAuth());
    final request = await adapter.requestPasswordReset();
    final blob = [
      request.operationId,
      request.maskedEmail,
      request.expiresAt.toIso8601String(),
      request.resendAvailableAt.toIso8601String(),
    ].join('|').toLowerCase();
    expect(blob, isNot(contains('123456')));
    expect(blob, isNot(contains('password')));
    expect(blob, isNot(contains('token')));
  });

  test('verify after expiry maps to RESET_CODE_EXPIRED', () async {
    final store = _FakeStore(expired: true);
    final adapter = buildAdapter(store, _FakeAuth());
    final request = await adapter.requestPasswordReset();

    expect(
      () => adapter.verifyPasswordResetCode(
        operationId: request.operationId,
        code: '123456',
      ),
      throwsA(
        isA<IamBlockedException>().having(
          (e) => e.code,
          'code',
          IamBlockedCodes.resetCodeExpired,
        ),
      ),
    );
  });

  test('invalid code maps to RESET_CODE_INVALID', () async {
    final store = _FakeStore(invalidCode: true);
    final adapter = buildAdapter(store, _FakeAuth());
    final request = await adapter.requestPasswordReset();

    expect(
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

  test('resend before window maps to RATE_LIMITED', () async {
    final store = _FakeStore(resendLocked: true);
    final adapter = buildAdapter(store, _FakeAuth());
    final request = await adapter.requestPasswordReset();

    expect(
      () => adapter.resendPasswordResetCode(operationId: request.operationId),
      throwsA(
        isA<IamBlockedException>().having(
          (e) => e.code,
          'code',
          IamBlockedCodes.resetRateLimited,
        ),
      ),
    );
  });

  test('complete on completed operation is terminal STATE_CHANGED', () async {
    final store = _FakeStore();
    final adapter = buildAdapter(store, _FakeAuth());
    final request = await adapter.requestPasswordReset();
    await adapter.verifyPasswordResetCode(
      operationId: request.operationId,
      code: '123456',
    );
    await adapter.completePasswordReset(
      operationId: request.operationId,
      newPassword: 'NewSecurePass1',
    );

    expect(
      () => adapter.completePasswordReset(
        operationId: request.operationId,
        newPassword: 'NewSecurePass2',
      ),
      throwsA(
        isA<IamBlockedException>().having(
          (e) => e.code,
          'code',
          IamBlockedCodes.stateChanged,
        ),
      ),
    );
  });

  test('weak password maps to PASSWORD_POLICY_VIOLATION', () async {
    final store = _FakeStore();
    final auth = _FakeAuth(
      updatePasswordError: Exception('Password should be at least 8 characters'),
    );
    final adapter = buildAdapter(store, auth);
    final request = await adapter.requestPasswordReset();
    await adapter.verifyPasswordResetCode(
      operationId: request.operationId,
      code: '123456',
    );

    expect(
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
}

final class _MutableOp {
  _MutableOp(this.status, this.expiresAt, this.resendAvailableAt);
  String status;
  DateTime expiresAt;
  DateTime resendAvailableAt;
}

/// Fake store that mirrors the RPC-owned validation of the B2 design: expiry,
/// invalid-code and resend rate-limit are decided here (not by the adapter).
final class _FakeStore implements PasswordResetOperationStore {
  _FakeStore({
    this.expired = false,
    this.resendLocked = false,
    this.invalidCode = false,
  });

  final bool expired;
  final bool resendLocked;
  final bool invalidCode;
  final Map<String, _MutableOp> operations = {};
  int _seq = 0;
  int beginCalls = 0;

  @override
  Future<PasswordResetOperation> begin() async {
    beginCalls++;
    final id = 'op-${_seq++}';
    final now = DateTime.now().toUtc();
    operations[id] = _MutableOp(
      'pending',
      expired
          ? now.subtract(const Duration(seconds: 1))
          : now.add(const Duration(minutes: 10)),
      resendLocked
          ? now.add(const Duration(seconds: 60))
          : now.subtract(const Duration(seconds: 1)),
    );
    return _toDto(id);
  }

  @override
  Future<PasswordResetOperation> get(String operationId) async =>
      _toDto(operationId);

  @override
  Future<bool> verifyCode(String operationId, String code) async {
    final op = operations[operationId]!;
    if (op.status == 'completed') {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    if (expired || DateTime.now().toUtc().isAfter(op.expiresAt)) {
      throw const IamBlockedException(IamBlockedCodes.resetCodeExpired);
    }
    if (invalidCode) {
      throw const IamBlockedException(IamBlockedCodes.resetCodeInvalid);
    }
    op.status = 'verified';
    return true;
  }

  @override
  Future<PasswordResetOperation> touchResend(String operationId) async {
    final op = operations[operationId]!;
    if (DateTime.now().toUtc().isBefore(op.resendAvailableAt)) {
      throw const IamBlockedException(IamBlockedCodes.resetRateLimited);
    }
    final now = DateTime.now().toUtc();
    op.expiresAt = now.add(const Duration(minutes: 10));
    op.resendAvailableAt = now.add(const Duration(seconds: 60));
    return _toDto(operationId);
  }

  @override
  Future<void> markVerified(String operationId) async {
    operations[operationId]!.status = 'verified';
  }

  @override
  Future<void> markCompleted(String operationId) async {
    operations[operationId]!.status = 'completed';
  }

  PasswordResetOperation _toDto(String id) {
    final op = operations[id]!;
    return PasswordResetOperation(
      operationId: id,
      userId: 'user-1',
      status: op.status,
      expiresAt: op.expiresAt,
      resendAvailableAt: op.resendAvailableAt,
    );
  }
}

final class _FakeAuth implements AuthAccountClient {
  _FakeAuth({this.updatePasswordError});

  final Object? updatePasswordError;
  int passwordUpdates = 0;
  int otherSessionsSignedOut = 0;

  @override
  String? get currentUserId => 'user-1';

  @override
  String? get currentEmail => 'lan@gmail.com';

  @override
  bool get isEmailVerified => true;

  @override
  Future<void> updatePassword(String newPassword) async {
    if (updatePasswordError != null) {
      throw updatePasswordError!;
    }
    passwordUpdates++;
  }

  @override
  Future<void> signOutOtherSessions() async {
    otherSessionsSignedOut++;
  }
}

final class _StubProfileGateway implements PlatformUserProfileGateway {
  @override
  Future<PlatformUserProfileSnapshot> getMyProfile() async {
    return const PlatformUserProfileSnapshot(
      userId: 'user-1',
      givenName: 'Lan',
      familyMiddleName: 'Le',
      phoneNumber: null,
      avatarReference: null,
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
    throw UnimplementedError();
  }
}
