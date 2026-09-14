enum SalesFakeOutcomeFamily {
  success,
  blocked,
  permissionDenied,
  staleVersion,
  idempotencyConflict,
  dependencyUnavailable,
  notFound,
  projectionPending,
  uncertainResult,
}

final class SalesFakeScenarioDefinition {
  const SalesFakeScenarioDefinition({
    required this.id,
    required this.resultFamily,
    required this.outcomeFamily,
  });

  final String id;
  final String resultFamily;
  final SalesFakeOutcomeFamily outcomeFamily;
}
