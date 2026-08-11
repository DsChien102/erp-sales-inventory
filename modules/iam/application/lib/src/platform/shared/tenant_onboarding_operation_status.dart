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
