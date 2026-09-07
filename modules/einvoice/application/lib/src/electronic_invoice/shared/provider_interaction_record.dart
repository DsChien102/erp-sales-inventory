import 'provider_interaction_direction.dart';
import 'provider_interaction_outcome.dart';
import 'provider_interaction_status.dart';

/// Canonical provider-call audit row (one per outbound attempt or inbound callback).
final class ProviderInteractionRecord {
  ProviderInteractionRecord({
    required this.interactionReference,
    required this.tenantId,
    required this.version,
    required this.providerConnectionId,
    required this.direction,
    required this.operationType,
    required this.targetType,
    required this.targetId,
    required this.correlationId,
    required this.requestReference,
    required this.status,
    required this.startedAt,
    this.responseReference,
    this.providerReference,
    this.outcome,
    this.safeErrorCode,
    this.completedAt,
  }) {
    if (version < 0) {
      throw ArgumentError.value(version, 'version', 'must be >= 0');
    }
    _requireNonEmpty('interactionReference', interactionReference);
    _requireNonEmpty('tenantId', tenantId);
    _requireNonEmpty('providerConnectionId', providerConnectionId);
    _requireNonEmpty('operationType', operationType);
    _requireNonEmpty('targetType', targetType);
    _requireNonEmpty('targetId', targetId);
    _requireNonEmpty('correlationId', correlationId);
    _requireNonEmpty('requestReference', requestReference);

    if (status == ProviderInteractionStatus.started) {
      if (outcome != null || completedAt != null) {
        throw ArgumentError(
          'STARTED interaction cannot have outcome or completedAt',
        );
      }
    } else {
      if (outcome == null || completedAt == null) {
        throw ArgumentError(
          'COMPLETED interaction requires outcome and completedAt',
        );
      }
    }
  }

  final String interactionReference;
  final String tenantId;
  final int version;
  final String providerConnectionId;
  final ProviderInteractionDirection direction;
  final String operationType;
  final String targetType;
  final String targetId;
  final String correlationId;
  final String requestReference;
  final String? responseReference;
  final String? providerReference;
  final ProviderInteractionStatus status;
  final ProviderInteractionOutcome? outcome;
  final String? safeErrorCode;
  final DateTime startedAt;
  final DateTime? completedAt;

  static void _requireNonEmpty(String field, String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, field, 'must not be blank');
    }
  }
}
