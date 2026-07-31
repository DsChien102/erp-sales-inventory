import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

/// scn_e06_u01/u02/u03 — Identity self-service handlers (§S14).
final class _FakePlatformIdentitySelfServicePort implements IPlatformIdentitySelfServicePort {
  _FakePlatformIdentitySelfServicePort({this.getError, this.verifyError});

  Object? getError;
  Object? verifyError;
  int requestCount = 0;
  int completeCalls = 0;
  String? lastVerifiedCode;
  String? lastOperationId;

  MyAccountDto _account = const MyAccountDto(
    userId: 'user-1',
    email: 'lan@example.com',
    givenName: 'Lan',
    familyName: 'Le',
    phone: '+84901234567',
    emailVerified: true,
    avatarReference: 'avatar-1',
  );

  @override
  Future<MyAccountDto> getMyAccount() async {
    if (getError != null) throw getError!;
    return _account;
  }

  @override
  Future<MyAccountDto> updateMyAccount({
    required String? avatarReference,
    required String givenName,
    required String familyName,
    required String? phone,
  }) async {
    _account = MyAccountDto(
      userId: _account.userId,
      email: _account.email,
      givenName: givenName,
      familyName: familyName,
      phone: phone,
      emailVerified: _account.emailVerified,
      avatarReference: avatarReference,
    );
    return _account;
  }

  @override
  Future<PasswordResetRequestResultDto> requestPasswordReset() async {
    requestCount++;
    return PasswordResetRequestResultDto(
      operationId: 'op-1',
      maskedEmail: 'l***@example.com',
      expiresAt: DateTime.utc(2026, 7, 30, 11),
      resendAvailableAt: DateTime.utc(2026, 7, 30, 10, 1),
    );
  }

  @override
  Future<PasswordResetRequestResultDto> resendPasswordResetCode({
    required String operationId,
  }) async {
    requestCount++;
    return PasswordResetRequestResultDto(
      operationId: operationId,
      maskedEmail: 'l***@example.com',
      expiresAt: DateTime.utc(2026, 7, 30, 11, 5),
      resendAvailableAt: DateTime.utc(2026, 7, 30, 10, 6),
    );
  }

  @override
  Future<PasswordResetVerifyResultDto> verifyPasswordResetCode({
    required String operationId,
    required String code,
  }) async {
    if (verifyError != null) throw verifyError!;
    lastOperationId = operationId;
    lastVerifiedCode = code;
    return const PasswordResetVerifyResultDto(verified: true);
  }

  @override
  Future<PasswordResetCompletionResultDto> completePasswordReset({
    required String operationId,
    required String newPassword,
  }) async {
    completeCalls += 1;
    lastOperationId = operationId;
    return const PasswordResetCompletionResultDto(
      currentSessionRotated: true,
      otherSessionsRevoked: true,
    );
  }
}

void main() {
  group('scn_e06_u01_fr01_01 GetMyIdentityProfileQueryHandler', () {
    test('my_profile_ok — returns profile', () async {
      final port = _FakePlatformIdentitySelfServicePort();
      final handler = GetMyIdentityProfileQueryHandler(
        identityPort: port,
      );

      final dto = await handler.handle(GetMyIdentityProfileQuery());

      expect(dto.email, 'lan@example.com');
      expect(dto.firstName, 'Lan');
      expect(dto.lastName, 'Le');
      expect(dto.phoneNumber, '+84901234567');
      expect(dto.avatarUrl, 'avatar-1');
    });

    test('my_profile_load_fail — propagates gateway error', () async {
      final port = _FakePlatformIdentitySelfServicePort(
        getError: ApplicationException('SYSTEM_ERROR'),
      );
      final handler = GetMyIdentityProfileQueryHandler(
        identityPort: port,
      );

      expect(
        () => handler.handle(GetMyIdentityProfileQuery()),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            'SYSTEM_ERROR',
          ),
        ),
      );
    });
  });

  group('scn_e06_u02_fr01_01 UpdateMyIdentityProfileCommandHandler', () {
    test('update_profile_ok — updates names and phone', () async {
      final port = _FakePlatformIdentitySelfServicePort();
      final handler = UpdateMyIdentityProfileCommandHandler(
        identityPort: port,
      );

      final dto = await handler.handle(
        UpdateMyIdentityProfileCommand(
          firstName: 'Trần Văn',
          lastName: 'A',
          phoneNumber: '0911 111 111',
        ),
      );

      expect(dto.firstName, 'Trần Văn');
      expect(dto.lastName, 'A');
      expect(dto.phoneNumber, '0911 111 111');
      expect(dto.email, 'lan@example.com');
    });

    test('update_validation_error — empty firstName rejected by validator', () async {
      final validator = UpdateMyIdentityProfileCommandValidator();

      expect(
        () => validator.validate(
          UpdateMyIdentityProfileCommand(firstName: '  ', lastName: 'A'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('scn_e06_u03_fr01_01 password reset handlers', () {
    test('reset_request_ok — returns typed metadata result', () async {
      final port = _FakePlatformIdentitySelfServicePort();
      final handler = RequestMyPasswordResetCommandHandler(
        identityPort: port,
      );

      final op = await handler.handle(RequestMyPasswordResetCommand());

      expect(op.operationId, 'op-1');
      expect(op.maskedEmail, 'l***@example.com');
      expect(op.expiresAt, DateTime.utc(2026, 7, 30, 11));
      expect(op.resendAvailableAt, DateTime.utc(2026, 7, 30, 10, 1));
      expect(port.requestCount, 1);
    });

    test('reset_resend_ok — returns refreshed result metadata', () async {
      final port = _FakePlatformIdentitySelfServicePort();
      final handler = ResendMyPasswordResetCommandHandler(identityPort: port);

      final op = await handler.handle(
        ResendMyPasswordResetCommand(operationId: 'op-1'),
      );

      expect(op.operationId, 'op-1');
      expect(op.maskedEmail, 'l***@example.com');
      expect(op.expiresAt, DateTime.utc(2026, 7, 30, 11, 5));
      expect(op.resendAvailableAt, DateTime.utc(2026, 7, 30, 10, 6));
      expect(port.requestCount, 1);
    });

    test('reset_code_invalid — verify propagates error', () async {
      final port = _FakePlatformIdentitySelfServicePort(
        verifyError: ApplicationException('RESET_CODE_INVALID'),
      );
      final handler = VerifyMyPasswordResetCommandHandler(
        identityPort: port,
      );

      expect(
        () => handler.handle(
          VerifyMyPasswordResetCommand(operationId: 'op-1', code: '000000'),
        ),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            'RESET_CODE_INVALID',
          ),
        ),
      );
    });

    test('reset_verify_ok — returns verified true', () async {
      final port = _FakePlatformIdentitySelfServicePort();
      final verify = VerifyMyPasswordResetCommandHandler(
        identityPort: port,
      );

      final result = await verify.handle(
        VerifyMyPasswordResetCommand(operationId: 'op-1', code: '123456'),
      );

      expect(result.verified, isTrue);
      expect(port.lastVerifiedCode, '123456');
    });

    test('reset_complete_ok — completes once and returns policy flags', () async {
      final port = _FakePlatformIdentitySelfServicePort();
      final complete = CompleteMyPasswordResetCommandHandler(
        identityPort: port,
      );

      final result = await complete.handle(
        CompleteMyPasswordResetCommand(
          operationId: 'op-1',
          newPassword: 'password1',
        ),
      );

      expect(result.currentSessionRotated, isTrue);
      expect(result.otherSessionsRevoked, isTrue);
      expect(port.completeCalls, 1);
    });

    test('reset_password_policy — validator rejects short password', () async {
      final validator = CompleteMyPasswordResetCommandValidator();

      expect(
        () => validator.validate(
          CompleteMyPasswordResetCommand(
            operationId: 'op-1',
            newPassword: 'short',
          ),
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'PASSWORD_POLICY_VIOLATION',
          ),
        ),
      );
    });
  });
}
