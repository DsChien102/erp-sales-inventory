import 'package:vet45_einvoice_application/application.dart';

abstract final class ProviderInteractionRpcMapper {
  static Map<String, dynamic> startParams({
    required String tenantId,
    required String providerConnectionId,
    required ProviderInteractionDirection direction,
    required String operationType,
    required String targetType,
    required String targetId,
    required String correlationId,
    required String requestReference,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_provider_connection_id': providerConnectionId,
      'p_direction': direction.toWire(),
      'p_operation_type': operationType,
      'p_target_type': targetType,
      'p_target_id': targetId,
      'p_correlation_id': correlationId,
      'p_request_reference': requestReference,
    };
  }

  static Map<String, dynamic> finalizeParams({
    required String tenantId,
    required String interactionReference,
    required int expectedVersion,
    required ProviderInteractionOutcome outcome,
    String? responseReference,
    String? providerReference,
    String? safeErrorCode,
  }) {
    return {
      'p_tenant_id': tenantId,
      'p_interaction_reference': interactionReference,
      'p_expected_version': expectedVersion,
      'p_outcome': outcome.toWire(),
      'p_response_reference': responseReference,
      'p_provider_reference': providerReference,
      'p_safe_error_code': safeErrorCode,
    };
  }

  static ProviderInteractionRecord interactionFromRow(
    Map<String, dynamic> row,
  ) {
    final status = ProviderInteractionStatus.fromWire(row['status'] as String);
    final outcomeRaw = row['outcome'] as String?;
    return ProviderInteractionRecord(
      interactionReference: row['interaction_reference'] as String,
      tenantId: row['tenant_id'] as String,
      version: (row['version'] as num).toInt(),
      providerConnectionId: row['provider_connection_id'] as String,
      direction: ProviderInteractionDirection.fromWire(
        row['direction'] as String,
      ),
      operationType: row['operation_type'] as String,
      targetType: row['target_type'] as String,
      targetId: row['target_id'] as String,
      correlationId: row['correlation_id'] as String,
      requestReference: row['request_reference'] as String,
      responseReference: row['response_reference'] as String?,
      providerReference: row['provider_reference'] as String?,
      status: status,
      outcome: outcomeRaw == null
          ? null
          : ProviderInteractionOutcome.fromWire(outcomeRaw),
      safeErrorCode: row['safe_error_code'] as String?,
      startedAt: DateTime.parse(row['started_at'] as String),
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at'] as String),
    );
  }
}
