import 'package:vet45_iam_domain/domain.dart';

/// List-row DTO for platform tenant search (EP-02/US-08).
final class PlatformTenantSummaryDto {
  const PlatformTenantSummaryDto({
    required this.tenantId,
    required this.name,
    required this.code,
    required this.status,
    required this.createdAt,
    this.ownerName,
    this.ownerEmail,
    this.memberCount = 0,
    this.readinessState,
    this.warningCode,
  });

  final String tenantId;
  final String name;
  final String code;
  final TenantLifecycleStatus status;
  final DateTime createdAt;
  final String? ownerName;
  final String? ownerEmail;
  final int memberCount;
  final String? readinessState;
  final String? warningCode;
}
