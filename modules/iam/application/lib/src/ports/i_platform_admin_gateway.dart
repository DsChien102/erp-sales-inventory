import '../dto/onboarding_owner_input.dart';
import '../dto/platform_user_detail_dto.dart';
import '../dto/platform_user_status.dart';
import '../dto/platform_user_summary_dto.dart';
import '../dto/tenant_onboarding_result_dto.dart';

/// Port for platform-scoped Admin reads/mutations (TH-01 S15).
///
/// Infrastructure implements via Supabase RPCs under `iam.*`.
abstract interface class IPlatformAdminGateway {
  Future<bool> hasPlatformPermission(String permission);

  Future<List<PlatformUserSummaryDto>> searchPlatformUsers({
    String? query,
    PlatformUserStatus? status,
  });

  Future<PlatformUserDetailDto> getPlatformUser(String userId);

  Future<void> sendActivationInvitation(String userId);

  Future<void> requestPasswordReset(String userId);

  Future<void> suspendPlatformUser({
    required String userId,
    required String reason,
  });

  Future<void> restorePlatformUser(String userId);

  Future<TenantOnboardingResultDto> createTenantOnboarding({
    required OnboardingOwnerInput owner,
    required String organizationName,
    required String idempotencyKey,
    String? correlationId,
  });
}
