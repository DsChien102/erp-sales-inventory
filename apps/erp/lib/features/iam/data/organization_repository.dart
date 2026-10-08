import 'package:erp/core/supabase/supabase_rpc.dart';

import 'iam_json.dart';
import 'models/tenant_profile.dart';
import 'models/tenant_readiness.dart';
import 'models/upsert_legal_profile_result.dart';

class OrganizationRepository {
  OrganizationRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
  }) : _rpc = rpc,
       _tenantId = tenantId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;

  Future<TenantProfile> getTenant() async {
    final row = await _rpc.firstRow(
      'iam',
      'get_tenant',
      params: {'p_tenant_id': await _tenantId()},
    );
    return TenantProfile.fromJson(row);
  }

  Future<TenantProfile> updateProfile({
    required String displayName,
    required String? contactEmail,
    required String? contactPhone,
    required String? contactAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
  }) async {
    final row = await _rpc.firstRow(
      'iam',
      'update_tenant_profile',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_display_name': displayName,
        'p_contact_email': contactEmail,
        'p_contact_phone': contactPhone,
        'p_contact_address_text': contactAddressText,
        'p_province_code': provinceCode,
        'p_commune_code': communeCode,
        'p_expected_version': expectedVersion,
      },
    );
    return TenantProfile.fromJson(row);
  }

  Future<UpsertLegalProfileResult> upsertLegalProfile({
    required String legalEntityType,
    required String legalName,
    required String taxCode,
    required String? registeredAddressText,
    required String? provinceCode,
    required String? communeCode,
    required int expectedVersion,
    bool allowDuplicateTaxCode = false,
  }) async {
    final row = await _rpc.firstRow(
      'iam',
      'upsert_legal_profile',
      params: {
        'p_tenant_id': await _tenantId(),
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
    return UpsertLegalProfileResult.fromJson(row);
  }

  /// Giữ đến 2-B2 bỏ readiness.
  Future<TenantReadiness> getReadiness() async {
    final row = iamJsonMap(
      await _rpc.call(
        'iam',
        'get_tenant_readiness',
        params: {'p_tenant_id': await _tenantId()},
      ),
    );
    return TenantReadiness.fromJson(row);
  }
}
