import 'package:vet45_iam_domain/domain.dart';

/// Current Legal Profile for a Tenant (0..1).
final class TenantLegalProfileDto {
  const TenantLegalProfileDto({
    required this.tenantId,
    required this.legalEntityType,
    required this.legalName,
    required this.taxCode,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.registeredAddressText,
    this.provinceCode,
    this.communeCode,
  });

  final String tenantId;
  final LegalEntityType legalEntityType;
  final String legalName;
  final String taxCode;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? registeredAddressText;
  final String? provinceCode;
  final String? communeCode;
}
