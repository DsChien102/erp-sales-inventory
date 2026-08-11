import '../identity/shared/password_reset_completion_result_dto.dart';
import '../identity/shared/password_reset_request_result_dto.dart';
import '../identity/shared/password_reset_verify_result_dto.dart';
import '../ports/i_password_reset_public_port.dart';
import '../shared/iam_blocked_codes.dart';
import '../shared/iam_blocked_exception.dart';
import 'fake_iam_scenario.dart';

/// In-memory public reset port. Always succeeds request (no email leak).
final class FakePasswordResetPublicPort implements IPasswordResetPublicPort {
  FakePasswordResetPublicPort({
    this.scenario = FakeIamScenario.passwordResetByEmailOk,
  });

  final FakeIamScenario scenario;
  String? lastEmail;
  String? operationId;
  bool verified = false;

  static String maskEmail(String email) {
    final trimmed = email.trim();
    final at = trimmed.indexOf('@');
    if (at <= 0) return '***';
    return '${trimmed[0]}***${trimmed.substring(at)}';
  }

  @override
  Future<PasswordResetRequestResultDto> requestByEmail({
    required String email,
  }) async {
    if (scenario == FakeIamScenario.identityUnavailable) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    lastEmail = email.trim();
    operationId = 'op-public-reset-1';
    verified = false;
    final now = DateTime.now().toUtc();
    return PasswordResetRequestResultDto(
      operationId: operationId!,
      maskedEmail: maskEmail(lastEmail!),
      expiresAt: now.add(const Duration(minutes: 10)),
      resendAvailableAt: now.add(const Duration(seconds: 45)),
    );
  }

  @override
  Future<PasswordResetRequestResultDto> resend({
    required String operationId,
  }) async {
    if (this.operationId != operationId) {
      throw const IamBlockedException(IamBlockedCodes.resetCodeInvalid);
    }
    verified = false;
    final now = DateTime.now().toUtc();
    return PasswordResetRequestResultDto(
      operationId: operationId,
      maskedEmail: maskEmail(lastEmail ?? 'u@example.com'),
      expiresAt: now.add(const Duration(minutes: 10)),
      resendAvailableAt: now.add(const Duration(seconds: 45)),
    );
  }

  @override
  Future<PasswordResetVerifyResultDto> verify({
    required String operationId,
    required String code,
  }) async {
    if (scenario == FakeIamScenario.passwordResetInvalidCode ||
        code.trim() != '123456' ||
        this.operationId != operationId) {
      throw const IamBlockedException(IamBlockedCodes.resetCodeInvalid);
    }
    verified = true;
    return const PasswordResetVerifyResultDto(verified: true);
  }

  @override
  Future<PasswordResetCompletionResultDto> complete({
    required String operationId,
    required String newPassword,
  }) async {
    if (!verified || this.operationId != operationId) {
      throw const IamBlockedException(IamBlockedCodes.resetCodeInvalid);
    }
    this.operationId = null;
    verified = false;
    return const PasswordResetCompletionResultDto(
      currentSessionRotated: false,
      otherSessionsRevoked: true,
    );
  }
}
