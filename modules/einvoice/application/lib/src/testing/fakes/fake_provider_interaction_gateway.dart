import 'package:vet45_einvoice_application/application.dart';

/// In-memory provider interaction audit for handler tests.
final class FakeProviderInteractionGateway implements IProviderInteractionGateway {
  final List<
    ({
      String tenantId,
      String providerConnectionId,
      ProviderInteractionDirection direction,
      String operationType,
      String targetType,
      String targetId,
      String correlationId,
      String requestReference,
    })
  >
  startCalls = [];

  final List<
    ({
      String tenantId,
      String interactionReference,
      int expectedVersion,
      ProviderInteractionOutcome outcome,
      String? safeErrorCode,
    })
  >
  finalizeCalls = [];

  final Map<String, ProviderInteractionRecord> _startedByCorrelation = {};

  bool throwOnStart = false;
  bool throwOnFinalize = false;

  @override
  Future<ProviderInteractionRecord> start({
    required String tenantId,
    required String providerConnectionId,
    required ProviderInteractionDirection direction,
    required String operationType,
    required String targetType,
    required String targetId,
    required String correlationId,
    required String requestReference,
  }) async {
    startCalls.add((
      tenantId: tenantId,
      providerConnectionId: providerConnectionId,
      direction: direction,
      operationType: operationType,
      targetType: targetType,
      targetId: targetId,
      correlationId: correlationId,
      requestReference: requestReference,
    ));

    if (throwOnStart) {
      throw StateError('simulated interaction start failure');
    }

    final record = ProviderInteractionRecord(
      interactionReference: 'int-$correlationId',
      tenantId: tenantId,
      version: 0,
      providerConnectionId: providerConnectionId,
      direction: direction,
      operationType: operationType,
      targetType: targetType,
      targetId: targetId,
      correlationId: correlationId,
      requestReference: requestReference,
      status: ProviderInteractionStatus.started,
      startedAt: DateTime.utc(2026, 8, 31),
    );
    _startedByCorrelation[correlationId] = record;
    return record;
  }

  @override
  Future<ProviderInteractionRecord> finalize({
    required String tenantId,
    required String interactionReference,
    required int expectedVersion,
    required ProviderInteractionOutcome outcome,
    String? responseReference,
    String? providerReference,
    String? safeErrorCode,
  }) async {
    finalizeCalls.add((
      tenantId: tenantId,
      interactionReference: interactionReference,
      expectedVersion: expectedVersion,
      outcome: outcome,
      safeErrorCode: safeErrorCode,
    ));

    if (throwOnFinalize) {
      throw StateError('simulated interaction finalize failure');
    }

    final started = _startedByCorrelation.values.firstWhere(
      (record) => record.interactionReference == interactionReference,
      orElse: () => ProviderInteractionRecord(
        interactionReference: interactionReference,
        tenantId: tenantId,
        version: expectedVersion,
        providerConnectionId: 'conn-1',
        direction: ProviderInteractionDirection.outbound,
        operationType: 'unknown',
        targetType: 'UNKNOWN',
        targetId: 'unknown',
        correlationId: 'corr-fallback',
        requestReference: 'cmd-fallback',
        status: ProviderInteractionStatus.started,
        startedAt: DateTime.utc(2026, 8, 31),
      ),
    );

    return ProviderInteractionRecord(
      interactionReference: interactionReference,
      tenantId: tenantId,
      version: expectedVersion + 1,
      providerConnectionId: started.providerConnectionId,
      direction: started.direction,
      operationType: started.operationType,
      targetType: started.targetType,
      targetId: started.targetId,
      correlationId: started.correlationId,
      requestReference: started.requestReference,
      status: ProviderInteractionStatus.completed,
      startedAt: started.startedAt,
      outcome: outcome,
      completedAt: DateTime.utc(2026, 8, 31, 0, 1),
      providerReference: providerReference,
      safeErrorCode: safeErrorCode,
    );
  }
}
