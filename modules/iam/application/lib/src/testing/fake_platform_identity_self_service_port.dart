import '../dto/my_account_dto.dart';
import '../dto/password_reset_completion_result_dto.dart';
import '../dto/password_reset_request_result_dto.dart';
import '../dto/password_reset_verify_result_dto.dart';
import '../ports/i_platform_identity_self_service_port.dart';
import '../shared/iam_blocked_codes.dart';
import '../shared/iam_blocked_exception.dart';
import 'fake_iam_scenario.dart';

/// In-memory Platform Identity self-service for FE/tests (§S14).
final class FakePlatformIdentitySelfServicePort
    implements IPlatformIdentitySelfServicePort {
  FakePlatformIdentitySelfServicePort({
    this.scenario = FakeIamScenario.myAccountOk,
    MyAccountDto? account,
  }) : _account =
           account ??
           const MyAccountDto(
             userId: 'user-1',
             email: 'lan@gmail.com',
             givenName: 'Lan',
             familyName: 'Le',
             phone: '+84901234567',
             emailVerified: true,
             avatarReference: 'avatar-ref-1',
           );

  final FakeIamScenario scenario;
  MyAccountDto _account;
  String? _operationId;
  bool _verified = false;
  DateTime? _expiresAt;
  DateTime? _resendAvailableAt;

  @override
  Future<MyAccountDto> getMyAccount() async {
    if (scenario == FakeIamScenario.identityUnavailable) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    return _account;
  }

  @override
  Future<MyAccountDto> updateMyAccount({
    required String? avatarReference,
    required String givenName,
    required String familyName,
    required String? phone,
  }) async {
    if (scenario == FakeIamScenario.identityUnavailable) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
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
    if (scenario == FakeIamScenario.identityUnavailable) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    _operationId = 'op-reset-1';
    _verified = false;
    final now = DateTime.now();
    _expiresAt = now.add(const Duration(minutes: 10));
    _resendAvailableAt = now.add(const Duration(seconds: 60));
    return PasswordResetRequestResultDto(
      operationId: 'op-reset-1',
      maskedEmail: 'l***@gmail.com',
      expiresAt: _expiresAt!,
      resendAvailableAt: _resendAvailableAt!,
    );
  }

  @override
  Future<PasswordResetRequestResultDto> resendPasswordResetCode({
    required String operationId,
  }) async {
    if (_operationId != operationId) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    final now = DateTime.now();
    _expiresAt = now.add(const Duration(minutes: 10));
    _resendAvailableAt = now.add(const Duration(seconds: 60));
    return PasswordResetRequestResultDto(
      operationId: operationId,
      maskedEmail: 'l***@gmail.com',
      expiresAt: _expiresAt!,
      resendAvailableAt: _resendAvailableAt!,
    );
  }

  @override
  Future<PasswordResetVerifyResultDto> verifyPasswordResetCode({
    required String operationId,
    required String code,
  }) async {
    if (scenario == FakeIamScenario.passwordResetInvalidCode) {
      throw const IamBlockedException(IamBlockedCodes.resetCodeInvalid);
    }
    if (_operationId != operationId || code != '123456') {
      throw const IamBlockedException(IamBlockedCodes.resetCodeInvalid);
    }
    _verified = true;
    return const PasswordResetVerifyResultDto(verified: true);
  }

  @override
  Future<PasswordResetCompletionResultDto> completePasswordReset({
    required String operationId,
    required String newPassword,
  }) async {
    if (!_verified || _operationId != operationId) {
      throw const IamBlockedException(IamBlockedCodes.stateChanged);
    }
    return const PasswordResetCompletionResultDto(
      currentSessionRotated: true,
      otherSessionsRevoked: true,
    );
  }
}
