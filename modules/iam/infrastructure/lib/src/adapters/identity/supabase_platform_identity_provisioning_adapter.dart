import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_error_mapper.dart';

/// Resolves or provisions the Platform Identity owner used by tenant onboarding.
final class SupabasePlatformIdentityProvisioningAdapter
    implements IPlatformIdentityProvisioningPort {
  SupabasePlatformIdentityProvisioningAdapter({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<PlatformOwnerIdentityResolutionDto> resolveOrCreateOwnerForOnboarding({
    required OnboardingOwnerInput owner,
    required String idempotencyKey,
    String? correlationId,
  }) async {
    if (owner.isExisting) {
      return PlatformOwnerIdentityResolutionDto(
        ownerUserId: owner.existingUserId!,
        isNewUser: false,
        status: 'active',
        activationDeliveryRequested: false,
      );
    }

    try {
      final result = await _rpcClient.callMap(
        'resolve_or_create_platform_user_for_onboarding',
        params: <String, dynamic>{
          'p_email': owner.email?.trim().toLowerCase(),
          'p_first_name': owner.firstName?.trim(),
          'p_last_name': owner.lastName?.trim(),
          'p_phone': owner.phone?.trim(),
          'p_idempotency_key': idempotencyKey,
          'p_correlation_id': correlationId,
        },
      );
      final ownerUserId = result['owner_user_id'] as String?;
      if (ownerUserId == null || ownerUserId.isEmpty) {
        throw ApplicationException(
          'Platform Identity did not return owner_user_id.',
        );
      }
      return PlatformOwnerIdentityResolutionDto(
        ownerUserId: ownerUserId,
        isNewUser: result['is_new_user'] as bool? ?? true,
        status: result['status'] as String? ?? 'pending_activation',
        activationDeliveryRequested: result['activation_delivery_requested'] as bool? ?? false,
      );
    } on RpcException catch (error) {
      throw mapIamRpcError(error);
    }
  }
}
