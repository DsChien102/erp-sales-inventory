import 'package:vet45_iam_domain/domain.dart';

import 'tenant_legal_profile_dto.dart';

/// Tenant profile + lifecycle read model (EP-02/US-01).
final class TenantDto {
  const TenantDto({
    required this.tenantId,
    required this.displayName,
    required this.status,
    required this.version,
    required this.businessTimezone,
    required this.baseCurrencyCode,
    required this.createdAt,
    required this.updatedAt,
    this.contactEmail,
    this.contactPhone,
    this.contactAddressText,
    this.provinceCode,
    this.communeCode,
    this.activatedAt,
    this.legalProfile,
  });

  final String tenantId;
  final String displayName;
  final TenantLifecycleStatus status;
  final int version;
  final String businessTimezone;
  final String baseCurrencyCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? contactEmail;
  final String? contactPhone;
  final String? contactAddressText;
  final String? provinceCode;
  final String? communeCode;
  final DateTime? activatedAt;
  final TenantLegalProfileDto? legalProfile;
}
