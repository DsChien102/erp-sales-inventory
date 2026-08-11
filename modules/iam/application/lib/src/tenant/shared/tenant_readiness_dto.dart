import 'package:vet45_iam_domain/domain.dart';

/// Derived Tenant readiness read model (§S11).
final class TenantReadinessDto {
  const TenantReadinessDto({
    required this.tenantId,
    required this.status,
    required this.blockers,
    required this.warnings,
    required this.evaluatedAt,
    required this.tenantVersion,
    required this.canActivate,
  });

  final String tenantId;
  final TenantLifecycleStatus status;
  final List<String> blockers;
  final List<String> warnings;
  final DateTime evaluatedAt;
  final int tenantVersion;
  final bool canActivate;
}
