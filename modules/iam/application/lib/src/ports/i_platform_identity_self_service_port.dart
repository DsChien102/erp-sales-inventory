import '../dto/my_account_dto.dart';
import '../dto/password_reset_completion_result_dto.dart';
import '../dto/password_reset_request_result_dto.dart';
import '../dto/password_reset_verify_result_dto.dart';

/// Platform Identity self-service port (§S14, plan §3.2/§3.3).
///
/// Owned by IAM. The concrete implementation lives in IAM infrastructure
/// (`SupabasePlatformIdentitySelfServiceAdapter`) which composes the IAM
/// platform-user profile RPC with the Supabase Auth client:
///   - profile fields come from `iam.platform_user_profiles`;
///   - login email + verified state come from Supabase Auth (read-only);
///   - password/recovery OTP/session stay authoritative in Supabase Auth.
///
/// The port never accepts `userId`/email as input (self-only, resolved from
/// `auth.uid()`) and never returns raw credentials, recovery codes or tokens.
abstract interface class IPlatformIdentitySelfServicePort {
  Future<MyAccountDto> getMyAccount();

  Future<MyAccountDto> updateMyAccount({
    required String? avatarReference,
    required String givenName,
    required String familyName,
    required String? phone,
  });

  Future<PasswordResetRequestResultDto> requestPasswordReset();

  Future<PasswordResetRequestResultDto> resendPasswordResetCode({
    required String operationId,
  });

  Future<PasswordResetVerifyResultDto> verifyPasswordResetCode({
    required String operationId,
    required String code,
  });

  Future<PasswordResetCompletionResultDto> completePasswordReset({
    required String operationId,
    required String newPassword,
  });
}
