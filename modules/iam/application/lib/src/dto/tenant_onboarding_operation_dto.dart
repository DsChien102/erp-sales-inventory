/// Status of a platform tenant onboarding operation (§S15 / OQ-02).
enum TenantOnboardingOperationStatus {
  inProgress,
  completed,
  partialFailure,
  failed,
}

extension TenantOnboardingOperationStatusCodes
    on TenantOnboardingOperationStatus {
  String get code => switch (this) {
    TenantOnboardingOperationStatus.inProgress => 'inProgress',
    TenantOnboardingOperationStatus.completed => 'completed',
    TenantOnboardingOperationStatus.partialFailure => 'partialFailure',
    TenantOnboardingOperationStatus.failed => 'failed',
  };

  static TenantOnboardingOperationStatus? fromCode(String? raw) =>
      switch (raw) {
        'inProgress' => TenantOnboardingOperationStatus.inProgress,
        'completed' => TenantOnboardingOperationStatus.completed,
        'partialFailure' => TenantOnboardingOperationStatus.partialFailure,
        'failed' => TenantOnboardingOperationStatus.failed,
        _ => null,
      };
}

/// Durable onboarding operation progress (§S15).
final class TenantOnboardingOperationDto {
  const TenantOnboardingOperationDto({
    required this.operationId,
    required this.status,
    required this.completedSteps,
    required this.correlationId,
    this.failedStep,
    this.tenantId,
    this.ownerUserId,
  });

  final String operationId;
  final TenantOnboardingOperationStatus status;
  final List<String> completedSteps;
  final String? failedStep;
  final String correlationId;
  final String? tenantId;
  final String? ownerUserId;
}
