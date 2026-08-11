import '../identity/shared/password_reset_completion_result_dto.dart';
import '../identity/shared/password_reset_request_result_dto.dart';
import '../identity/shared/password_reset_verify_result_dto.dart';

/// Logged-out forgot-password (login). Separate from
/// [IPlatformIdentitySelfServicePort] which is self-only (`auth.uid()`).
///
/// Implementations must not leak whether [email] exists: request/resend
/// always return the same DTO shape; verify/complete map unknown
/// operation → `RESET_CODE_INVALID`.
abstract interface class IPasswordResetPublicPort {
  Future<PasswordResetRequestResultDto> requestByEmail({required String email});

  Future<PasswordResetRequestResultDto> resend({required String operationId});

  Future<PasswordResetVerifyResultDto> verify({
    required String operationId,
    required String code,
  });

  Future<PasswordResetCompletionResultDto> complete({
    required String operationId,
    required String newPassword,
  });
}
