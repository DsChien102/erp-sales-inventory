final class AutoIssuanceReevaluationRequest {
  const AutoIssuanceReevaluationRequest({
    required this.tenantId,
    required this.processId,
    required this.sourceEventId,
  });

  final String tenantId;
  final String processId;
  final String sourceEventId;
}
