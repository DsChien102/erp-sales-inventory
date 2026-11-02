import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';

import '../logic/partner_rules.dart';
import 'models/partner_action_log.dart';
import 'models/partner_detail.dart';
import 'models/partner_duplicate_match.dart';
import 'models/partner_enums.dart';
import 'models/partner_inputs.dart';
import 'models/partner_list_item.dart';
import 'models/partner_write_results.dart';

/// Mọi RPC của schema `partner`. `p_tenant_id` và `p_actor_id` lấy từ phiên.
class PartnerRepository {
  PartnerRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
    required Future<String> Function() actorId,
  }) : _rpc = rpc,
       _tenantId = tenantId,
       _actorId = actorId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;
  final Future<String> Function() _actorId;

  static const _schema = 'partner';

  Future<PartnerSearchResultDto> search({
    String? query,
    PartnerType? partnerType,
    PartnerRoleType? role,
    bool requireBothRoles = false,
    bool requireAnyRole = false,
    PartnerStatus? status,
    int? updatedWithinDays,
    int page = 1,
    int limit = 20,
    String? sort,
  }) async {
    final rows = await _rpc.rows(
      _schema,
      'search_partners',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_query': query,
        'p_partner_type': partnerType?.name,
        'p_role': requireBothRoles ? 'both' : role?.name ?? (requireAnyRole ? 'any' : null),
        'p_status': status?.name,
        'p_updated_within_days': updatedWithinDays,
        'p_page': page,
        'p_limit': limit,
        'p_sort': sort,
      },
    );
    return PartnerSearchResultDto.fromJson(
      rows.isEmpty ? <String, dynamic>{} : rows.first,
    );
  }

  Future<PartnerDetailDto> getDetail(String partnerId) async {
    final result = await _rpc.call(
      _schema,
      'get_partner_detail',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_partner_id': partnerId,
      },
    );
    if (result is! Map || result.isEmpty) {
      throw const AppException(AppErrorCode.notFound);
    }
    return PartnerDetailDto.fromJson(Map<String, dynamic>.from(result));
  }

  Future<List<PartnerDuplicateMatchDto>> checkDuplicates({
    String? phone,
    String? email,
    String? taxCode,
    String? name,
    String? excludePartnerId,
  }) async {
    final rows = await _rpc.rows(
      _schema,
      'check_duplicate',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_phone': phone,
        'p_email': email,
        'p_tax_code': taxCode,
        'p_name': name,
        'p_exclude_partner_id': excludePartnerId,
      },
    );
    return rows.map(PartnerDuplicateMatchDto.fromJson).toList(growable: false);
  }

  Future<DeleteEligibilityDto> checkDeleteEligibility(String partnerId) async {
    final row = await _rpc.firstRow(
      _schema,
      'check_delete_eligibility',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_partner_id': partnerId,
      },
    );
    return DeleteEligibilityDto.fromJson(row);
  }

  Future<PartnerActionLogPage> getActionLogs(
    String partnerId, {
    int page = 1,
    int limit = 20,
  }) async {
    final row = await _rpc.firstRow(
      _schema,
      'get_partner_action_logs',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_partner_id': partnerId,
        'p_page': page,
        'p_limit': limit,
      },
    );
    return PartnerActionLogPage.fromJson(row);
  }

  Future<CreatePartnerResult> create({
    required PartnerType partnerType,
    required List<PartnerRoleType> roles,
    PersonProfileInput? personProfile,
    OrganizationProfileInput? organizationProfile,
    PersonProfileInput? organizationPrimaryContact,
    bool confirmDuplicate = false,
  }) async {
    if (personProfile != null) PartnerRules.checkPersonProfile(personProfile);
    if (organizationProfile != null) PartnerRules.checkOrganizationProfile(organizationProfile);
    PartnerRules.checkRoles(roles);
    PartnerRules.checkProfileMatchesType(
      partnerType,
      person: personProfile,
      organization: organizationProfile,
    );
    final row = await _rpc.firstRow(
      _schema,
      'create_partner',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        'p_partner_type': partnerType.name,
        'p_roles': roles.map((r) => r.name).toList(),
        'p_person_profile': personProfile?.toRpcJson(),
        'p_organization_profile': organizationProfile?.toRpcJson(),
        'p_organization_primary_contact': organizationPrimaryContact?.toRpcJson(),
        'p_confirm_duplicate': confirmDuplicate,
      },
    );
    return CreatePartnerResult.fromJson(row);
  }

  Future<UpdatePartnerProfileResult> update({
    required String partnerId,
    required int expectedVersion,
    required List<PartnerRoleType> roles,
    PersonProfileInput? personProfile,
    OrganizationProfileInput? organizationProfile,
    bool confirmDuplicate = false,
  }) async {
    PartnerRules.checkRoles(roles);
    if (personProfile != null) PartnerRules.checkPersonProfile(personProfile);
    if (organizationProfile != null) PartnerRules.checkOrganizationProfile(organizationProfile);
    final row = await _rpc.firstRow(
      _schema,
      'update_partner',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        'p_partner_id': partnerId,
        'p_roles': roles.map((r) => r.name).toList(),
        'p_person_profile': personProfile?.toRpcJson(),
        'p_organization_profile': organizationProfile?.toRpcJson(),
        'p_confirm_duplicate': confirmDuplicate,
        'p_expected_version': expectedVersion,
      },
    );
    return UpdatePartnerProfileResult.fromJson(row);
  }

  /// Trả `partnerId` của hồ sơ sau khi chuyển.
  Future<String> transformToOrganization({
    required String partnerId,
    required int expectedVersion,
    required OrganizationProfileInput organizationProfile,
    bool confirmDuplicate = false,
  }) async {
    PartnerRules.checkOrganizationProfile(organizationProfile);
    final row = await _rpc.firstRow(
      _schema,
      'transform_to_organization',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        'p_partner_id': partnerId,
        'p_organization_profile': organizationProfile.toRpcJson(),
        'p_expected_version': expectedVersion,
        'p_confirm_duplicate': confirmDuplicate,
      },
    );
    return row['partner_id'] as String;
  }

  Future<AddOrganizationContactResult> addContact({
    required String organizationPartnerId,
    String? personPartnerId,
    PersonProfileInput? newPersonProfile,
    String? contactRole,
    bool isPrimary = false,
  }) async {
    final row = await _rpc.firstRow(
      _schema,
      'add_organization_contact',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        'p_organization_partner_id': organizationPartnerId,
        'p_person_partner_id': personPartnerId,
        'p_new_person_profile': newPersonProfile?.toRpcJson(),
        'p_contact_role': contactRole,
        'p_is_primary': isPrimary,
      },
    );
    return AddOrganizationContactResult.fromJson(row);
  }

  Future<void> updateContact({
    required String organizationPartnerId,
    required String personPartnerId,
    String? contactRole,
    bool? isPrimary,
    String? note,
    PersonProfileInput? personProfile,
  }) async {
    await _rpc.call(
      _schema,
      'update_organization_contact',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        'p_organization_partner_id': organizationPartnerId,
        'p_person_partner_id': personPartnerId,
        'p_contact_role': contactRole,
        'p_is_primary': isPrimary,
        'p_note': note,
        'p_person_profile': personProfile?.toRpcJson(),
      },
    );
  }

  Future<void> removeContact({
    required String organizationPartnerId,
    required String personPartnerId,
  }) async {
    await _rpc.call(
      _schema,
      'remove_organization_contact',
      params: {
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        'p_organization_partner_id': organizationPartnerId,
        'p_person_partner_id': personPartnerId,
      },
    );
  }

  Future<PartnerVersionResult> deactivate(
    String partnerId, {
    required int expectedVersion,
    String? reason,
  }) => _changeStatus('deactivate_partner', partnerId, expectedVersion, reason);

  Future<PartnerVersionResult> reactivate(
    String partnerId, {
    required int expectedVersion,
    String? reason,
  }) => _changeStatus('reactivate_partner', partnerId, expectedVersion, reason);

  Future<PartnerVersionResult> softDelete(
    String partnerId, {
    required int expectedVersion,
    String? reason,
  }) => _changeStatus('soft_delete_partner', partnerId, expectedVersion, reason);

  Future<PartnerVersionResult> _changeStatus(
    String fn,
    String partnerId,
    int expectedVersion,
    String? reason,
  ) async {
    final row = await _rpc.firstRow(
      _schema,
      fn,
      params: {
        'p_tenant_id': await _tenantId(),
        'p_actor_id': await _actorId(),
        'p_partner_id': partnerId,
        'p_reason': reason,
        'p_expected_version': expectedVersion,
      },
    );
    return PartnerVersionResult.fromJson(row);
  }
}
