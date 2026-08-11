import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';

final class SupabaseTenantProfileReadGateway
    implements ITenantProfileReadGateway {
  SupabaseTenantProfileReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<TenantDto?> getTenant({required String tenantId}) async {
    try {
      final result = await _rpcClient.callMap(
        'get_tenant',
        params: <String, dynamic>{'p_tenant_id': tenantId},
      );
      if (result.isEmpty) {
        return null;
      }
      return mapTenantDto(result);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }
}

TenantDto mapTenantDto(Map<String, dynamic> row) {
  final legalRaw = row['legal_profile'];
  TenantLegalProfileDto? legalProfile;
  if (legalRaw is Map<String, dynamic> && legalRaw.isNotEmpty) {
    legalProfile = mapTenantLegalProfile(legalRaw);
  }

  return TenantDto(
    tenantId: row['tenant_id'] as String,
    displayName: row['display_name'] as String? ?? row['name'] as String? ?? '',
    status: _mapLifecycle(row['status'] as String?),
    version: (row['version'] as num?)?.toInt() ?? 1,
    businessTimezone:
        row['business_timezone'] as String? ?? 'Asia/Ho_Chi_Minh',
    baseCurrencyCode: row['base_currency_code'] as String? ?? 'VND',
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
    contactEmail: row['contact_email'] as String?,
    contactPhone: row['contact_phone'] as String?,
    contactAddressText: row['contact_address_text'] as String?,
    provinceCode: row['province_code'] as String?,
    communeCode: row['commune_code'] as String?,
    activatedAt: row['activated_at'] == null
        ? null
        : DateTime.parse(row['activated_at'] as String),
    legalProfile: legalProfile,
  );
}

TenantLegalProfileDto mapTenantLegalProfile(Map<String, dynamic> row) {
  return TenantLegalProfileDto(
    tenantId: row['tenant_id'] as String,
    legalEntityType:
        LegalEntityTypeCodes.fromCode(row['legal_entity_type'] as String?) ??
        LegalEntityType.enterprise,
    legalName: row['legal_name'] as String,
    taxCode: row['tax_code'] as String,
    version: (row['version'] as num?)?.toInt() ?? 1,
    createdAt: DateTime.parse(row['created_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
    registeredAddressText: row['registered_address_text'] as String?,
    provinceCode: row['province_code'] as String?,
    communeCode: row['commune_code'] as String?,
  );
}

TenantLifecycleStatus _mapLifecycle(String? raw) {
  return switch (raw) {
    'provisioning' => TenantLifecycleStatus.provisioning,
    'suspended' => TenantLifecycleStatus.suspended,
    'closed' => TenantLifecycleStatus.closed,
    _ => TenantLifecycleStatus.active,
  };
}
