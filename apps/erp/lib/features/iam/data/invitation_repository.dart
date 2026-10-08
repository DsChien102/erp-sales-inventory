import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';

import 'iam_json.dart';
import 'models/cursor_page.dart';
import 'models/tenant_invitation.dart';

class InvitationRepository {
  InvitationRepository({required SupabaseRpc rpc, required Future<String> Function() tenantId})
    : _rpc = rpc,
      _tenantId = tenantId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;

  static const _allowedStatus = <String>{
    'pending',
    'accepted',
    'declined',
    'revoked',
    'expired',
  };

  Future<CursorPage<TenantInvitation>> listInvitations({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    if (limit < 1 || limit > 100) {
      throw const AppException(AppErrorCode.validation);
    }
    final trimmedSearch = search?.trim();
    final trimmedStatus = status?.trim();
    if (trimmedStatus != null &&
        trimmedStatus.isNotEmpty &&
        !_allowedStatus.contains(trimmedStatus)) {
      throw const AppException(AppErrorCode.validation);
    }
    final page = iamJsonMap(
      await _rpc.call(
        'iam',
        'list_tenant_invitations',
        params: {
          'p_tenant_id': await _tenantId(),
          'p_search': (trimmedSearch == null || trimmedSearch.isEmpty) ? null : trimmedSearch,
          'p_status': (trimmedStatus == null || trimmedStatus.isEmpty) ? null : trimmedStatus,
          'p_cursor': cursor,
          'p_limit': limit,
        },
      ),
    );
    final rows = page['items'] as List? ?? const [];
    return CursorPage(
      items: rows
          .map((raw) => TenantInvitation.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList(growable: false),
      nextCursor: page['next_cursor'] as String?,
    );
  }

  Future<TenantInvitationDetail> getInvitation(String invitationId) async {
    final row = iamJsonMap(
      await _rpc.call(
        'iam',
        'get_tenant_invitation',
        params: {'p_tenant_id': await _tenantId(), 'p_invitation_id': invitationId},
      ),
    );
    if (row.isEmpty) throw const AppException(AppErrorCode.notFound);
    return TenantInvitationDetail.fromJson(row, defaultDeliveryStatus: 'unknown');
  }

  Future<TenantInvitationDetail> create({
    required String email,
    required String roleCode,
    required String idempotencyKey,
  }) {
    return _detail('create_tenant_invitation', {
      'p_tenant_id': null,
      'p_invitee_email': email,
      'p_initial_role_id': roleCode,
      'p_idempotency_key': idempotencyKey,
    });
  }

  Future<TenantInvitationDetail> resend(
    String invitationId, {
    required int expectedVersion,
    required String idempotencyKey,
  }) {
    return _detail('resend_tenant_invitation', {
      'p_invitation_id': invitationId,
      'p_expected_version': expectedVersion,
      'p_idempotency_key': idempotencyKey,
    });
  }

  Future<TenantInvitationDetail> revoke(
    String invitationId, {
    required int expectedVersion,
    required String reason,
    required String idempotencyKey,
  }) {
    return _detail('revoke_tenant_invitation', {
      'p_invitation_id': invitationId,
      'p_expected_version': expectedVersion,
      'p_reason': reason,
      'p_idempotency_key': idempotencyKey,
    });
  }

  Future<List<AssignableInvitationRole>> listAssignableRoles() async {
    final rows = await _rpc.rows(
      'iam',
      'list_assignable_invitation_roles',
      params: {'p_tenant_id': await _tenantId()},
    );
    return rows
        .map(AssignableInvitationRole.fromJson)
        .where((row) => row.roleId.isNotEmpty && row.label.isNotEmpty)
        .toList(growable: false);
  }

  Future<TenantInvitationDetail> _detail(String fn, Map<String, dynamic> params) async {
    params['p_tenant_id'] = await _tenantId();
    final row = iamJsonMap(await _rpc.call('iam', fn, params: params));
    if (row.isEmpty) throw const AppException(AppErrorCode.notFound);
    return TenantInvitationDetail.fromJson(row);
  }
}
