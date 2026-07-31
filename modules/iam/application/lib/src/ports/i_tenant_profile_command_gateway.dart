import '../dto/tenant_dto.dart';
import '../dto/upsert_legal_profile_result_dto.dart';

/// Command port for Tenant profile + Legal Profile mutations (§S12).
abstract interface class ITenantProfileCommandGateway {
  Future<TenantDto> updateProfile({
    required String tenantId,
    required String displayName,
    required String? contactEmail,
    required String? contactPhone,
    required String? contactAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
  });

  Future<UpsertLegalProfileResultDto> upsertLegalProfile({
    required String tenantId,
    required String legalEntityType,
    required String legalName,
    required String taxCode,
    required String? registeredAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
    required bool allowDuplicateTaxCode,
  });
}
