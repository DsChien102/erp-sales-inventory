import 'tenant_onboarding_operation_status.dart';

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
