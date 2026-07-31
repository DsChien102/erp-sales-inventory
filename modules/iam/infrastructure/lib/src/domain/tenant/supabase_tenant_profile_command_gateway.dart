import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';
import 'supabase_tenant_profile_read_gateway.dart';

final class SupabaseTenantProfileCommandGateway
    implements ITenantProfileCommandGateway {
  SupabaseTenantProfileCommandGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<TenantDto> updateProfile({
    required String tenantId,
    required String displayName,
    required String? contactEmail,
    required String? contactPhone,
    required String? contactAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'update_tenant_profile',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_display_name': displayName,
          'p_contact_email': contactEmail,
          'p_contact_phone': contactPhone,
          'p_contact_address_text': contactAddressText,
          'p_province_code': provinceCode,
          'p_commune_code': communeCode,
          'p_expected_version': expectedVersion,
        },
      );
      return mapTenantDto(result);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  @override
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
  }) async {
    try {
      final result = await _rpcClient.callMap(
        'upsert_legal_profile',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_legal_entity_type': legalEntityType,
          'p_legal_name': legalName,
          'p_tax_code': taxCode,
          'p_registered_address_text': registeredAddressText,
          'p_province_code': provinceCode,
          'p_commune_code': communeCode,
          'p_expected_version': expectedVersion,
          'p_allow_duplicate_tax_code': allowDuplicateTaxCode,
        },
      );
      return _mapUpsertResult(result);
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  UpsertLegalProfileResultDto _mapUpsertResult(Map<String, dynamic> row) {
    final tenantVersion = (row['tenant_version'] as num?)?.toInt() ?? 1;
    final warningRaw = row['warning'];
    if (warningRaw is Map<String, dynamic> && warningRaw.isNotEmpty) {
      return UpsertLegalProfileResultDto.warning(
        tenantVersion: tenantVersion,
        warning: DuplicateTaxCodeWarningDto(
          code: warningRaw['code'] as String? ?? DuplicateTaxCodeWarningDto.codeValue,
          message: warningRaw['message'] as String? ?? 'Duplicate tax code',
        ),
      );
    }
    final profileRaw = row['profile'] as Map<String, dynamic>? ?? row;
    return UpsertLegalProfileResultDto.saved(
      tenantVersion: tenantVersion,
      profile: mapTenantLegalProfile(profileRaw),
    );
  }
}
