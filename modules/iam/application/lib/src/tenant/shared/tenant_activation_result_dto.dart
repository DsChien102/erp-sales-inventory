import 'package:vet45_iam_domain/domain.dart';

/// Result of Tenant activation (§S11).
final class TenantActivationResultDto {
  const TenantActivationResultDto({
    required this.tenantId,
    required this.status,
    required this.activatedAt,
    required this.version,
  });

  final String tenantId;
  final TenantLifecycleStatus status;
  final DateTime activatedAt;
  final int version;
}
