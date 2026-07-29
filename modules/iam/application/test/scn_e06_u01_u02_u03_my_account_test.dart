import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

/// scn_e06_u01/u02/u03 — Identity self-service handlers (§S14).
class _FakeIdentityGateway implements IIdentitySelfServiceGateway {
  _FakeIdentityGateway({
    this.profile,
    this.getError,
    this.updateError,
    this.requestError,
    this.verifyError,
    this.completeError,
  });

  MyIdentityProfileDto? profile;
  Object? getError;
  Object? updateError;
  Object? requestError;
  Object? verifyError;
  Object? completeError;
  int requestCount = 0;
  String? lastVerifiedCode;
  String? lastNewPassword;

  @override
  Future<MyIdentityProfileDto> getMyIdentityProfile() async {
    if (getError != null) throw getError!;
    return profile!;
  }

  @override
  Future<MyIdentityProfileDto> updateMyIdentityProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    if (updateError != null) throw updateError!;
    profile = MyIdentityProfileDto(
      userId: profile?.userId ?? 'u1',
      firstName: firstName,
      lastName: lastName,
      email: profile?.email ?? 'minh@gmail.com',
      emailVerified: profile?.emailVerified ?? true,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
    );
    return profile!;
  }

  @override
  Future<PasswordResetOperationDto> requestMyPasswordReset() async {
    if (requestError != null) throw requestError!;
    requestCount++;
    return const PasswordResetOperationDto(
      operationId: 'op-1',
      maskedEmail: 'mi***@gmail.com',
      resendAfterSeconds: 45,
    );
  }

  @override
  Future<PasswordResetOperationDto> resendMyPasswordReset({
    required String operationId,
  }) async {
    if (requestError != null) throw requestError!;
    requestCount++;
    return PasswordResetOperationDto(
      operationId: operationId,
      maskedEmail: 'mi***@gmail.com',
      resendAfterSeconds: 45,
    );
  }

  @override
  Future<void> verifyMyPasswordReset({
    required String operationId,
    required String code,
  }) async {
    if (verifyError != null) throw verifyError!;
    lastVerifiedCode = code;
  }

  @override
  Future<void> completeMyPasswordReset({
    required String operationId,
    required String newPassword,
  }) async {
    if (completeError != null) throw completeError!;
    lastNewPassword = newPassword;
  }
}

void main() {
  const sample = MyIdentityProfileDto(
    userId: 'u1',
    firstName: 'Nguyễn Văn',
    lastName: 'Minh',
    email: 'minh@gmail.com',
    emailVerified: true,
    phoneNumber: '0901 234 567',
  );

  group('scn_e06_u01_fr01_01 GetMyIdentityProfileQueryHandler', () {
    test('my_profile_ok — returns profile', () async {
      final gateway = _FakeIdentityGateway(profile: sample);
      final handler = GetMyIdentityProfileQueryHandler(
        identityGateway: gateway,
      );

      final dto = await handler.handle(GetMyIdentityProfileQuery());

      expect(dto.email, 'minh@gmail.com');
      expect(dto.firstName, 'Nguyễn Văn');
      expect(dto.lastName, 'Minh');
    });

    test('my_profile_load_fail — propagates gateway error', () async {
      final gateway = _FakeIdentityGateway(
        getError: ApplicationException('SYSTEM_ERROR'),
      );
      final handler = GetMyIdentityProfileQueryHandler(
        identityGateway: gateway,
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
      final gateway = _FakeIdentityGateway(profile: sample);
      final handler = UpdateMyIdentityProfileCommandHandler(
        identityGateway: gateway,
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
      expect(dto.email, 'minh@gmail.com');
    });

    test('update_validation_error — empty firstName rejected by validator',
        () async {
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
    test('reset_request_ok — returns operation without code', () async {
      final gateway = _FakeIdentityGateway(profile: sample);
      final handler = RequestMyPasswordResetCommandHandler(
        identityGateway: gateway,
      );

      final op = await handler.handle(RequestMyPasswordResetCommand());

      expect(op.operationId, 'op-1');
      expect(op.maskedEmail, 'mi***@gmail.com');
      expect(gateway.requestCount, 1);
    });

    test('reset_code_invalid — verify propagates error', () async {
      final gateway = _FakeIdentityGateway(
        profile: sample,
        verifyError: ApplicationException('RESET_CODE_INVALID'),
      );
      final handler = VerifyMyPasswordResetCommandHandler(
        identityGateway: gateway,
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

    test('reset_complete_ok — completes after verify', () async {
      final gateway = _FakeIdentityGateway(profile: sample);
      final verify = VerifyMyPasswordResetCommandHandler(
        identityGateway: gateway,
      );
      final complete = CompleteMyPasswordResetCommandHandler(
        identityGateway: gateway,
      );

      await verify.handle(
        VerifyMyPasswordResetCommand(operationId: 'op-1', code: '123456'),
      );
      await complete.handle(
        CompleteMyPasswordResetCommand(
          operationId: 'op-1',
          newPassword: 'password1',
        ),
      );

      expect(gateway.lastVerifiedCode, '123456');
      expect(gateway.lastNewPassword, 'password1');
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
