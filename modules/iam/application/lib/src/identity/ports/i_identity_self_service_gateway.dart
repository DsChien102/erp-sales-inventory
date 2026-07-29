import '../shared/my_identity_profile_dto.dart';
import '../shared/password_reset_operation_dto.dart';

/// Port for Platform Identity self-service (EP-06 / S14).
///
/// Theme 1 orchestrates only — no local credential / code persistence.
abstract interface class IIdentitySelfServiceGateway {
  Future<MyIdentityProfileDto> getMyIdentityProfile();

  Future<MyIdentityProfileDto> updateMyIdentityProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? avatarUrl,
  });

  Future<PasswordResetOperationDto> requestMyPasswordReset();

  Future<PasswordResetOperationDto> resendMyPasswordReset({
    required String operationId,
  });

  Future<void> verifyMyPasswordReset({
    required String operationId,
    required String code,
  });

  Future<void> completeMyPasswordReset({
    required String operationId,
    required String newPassword,
  });
}
