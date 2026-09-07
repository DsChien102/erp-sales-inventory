import '../electronic_invoice/shared/provider_interaction_direction.dart';
import '../electronic_invoice/shared/provider_interaction_outcome.dart';
import '../electronic_invoice/shared/provider_interaction_record.dart';

abstract interface class IProviderInteractionGateway {
  Future<ProviderInteractionRecord> start({
    required String tenantId,
    required String providerConnectionId,
    required ProviderInteractionDirection direction,
    required String operationType,
    required String targetType,
    required String targetId,
    required String correlationId,
    required String requestReference,
  });

  Future<ProviderInteractionRecord> finalize({
    required String tenantId,
    required String interactionReference,
    required int expectedVersion,
    required ProviderInteractionOutcome outcome,
    String? responseReference,
    String? providerReference,
    String? safeErrorCode,
  });
}
