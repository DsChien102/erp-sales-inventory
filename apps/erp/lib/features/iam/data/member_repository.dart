import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';

import 'iam_json.dart';
import 'models/cursor_page.dart';
import 'models/tenant_member.dart';

class MemberRepository {
  MemberRepository({required SupabaseRpc rpc, required Future<String> Function() tenantId})
    : _rpc = rpc,
      _tenantId = tenantId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;

  Future<CursorPage<TenantMember>> listMembers({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    _requireLimit(limit);
    final trimmedSearch = search?.trim();
    final trimmedStatus = status?.trim();
    if (trimmedStatus != null &&
        trimmedStatus.isNotEmpty &&
        trimmedStatus != 'active' &&
        trimmedStatus != 'inactive' &&
        trimmedStatus != 'removed') {
      throw const AppException(AppErrorCode.validation);
    }
    final page = iamJsonMap(
      await _rpc.call(
        'iam',
        'list_tenant_members',
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
          .map((raw) => TenantMember.fromJson(Map<String, dynamic>.from(raw as Map)))
          .toList(growable: false),
      nextCursor: page['next_cursor'] as String?,
    );
  }

  Future<TenantMemberDetail> getMember(String membershipId) async {
    final row = iamJsonMap(
      await _rpc.call(
        'iam',
        'get_tenant_member',
        params: {'p_tenant_id': await _tenantId(), 'p_membership_id': membershipId},
      ),
    );
    if (row.isEmpty) throw const AppException(AppErrorCode.notFound);
    return TenantMemberDetail.fromJson(row);
  }

  Future<void> assignRole({required String userId, required String role}) async {
    await _rpc.call(
      'iam',
      'assign_member_role',
      params: {'p_tenant_id': await _tenantId(), 'p_user_id': userId, 'p_role': role},
    );
  }

  Future<TenantMemberDetail> deactivate(String membershipId, {required int expectedVersion}) {
    return _mutate(
      'deactivate_membership',
      membershipId: membershipId,
      expectedVersion: expectedVersion,
    );
  }

  Future<TenantMemberDetail> reactivate(String membershipId, {required int expectedVersion}) {
    return _mutate(
      'reactivate_membership',
      membershipId: membershipId,
      expectedVersion: expectedVersion,
    );
  }

  Future<TenantMemberDetail> remove(String membershipId, {required int expectedVersion}) {
    return _mutate(
      'remove_membership',
      membershipId: membershipId,
      expectedVersion: expectedVersion,
    );
  }

  Future<TenantMemberDetail> _mutate(
    String fn, {
    required String membershipId,
    required int expectedVersion,
  }) async {
    final row = iamJsonMap(
      await _rpc.call(
        'iam',
        fn,
        params: {
          'p_tenant_id': await _tenantId(),
          'p_membership_id': membershipId,
          'p_expected_version': expectedVersion,
        },
      ),
    );
    if (row.isEmpty) throw const AppException(AppErrorCode.notFound);
    return TenantMemberDetail.fromJson(row);
  }
}

void _requireLimit(int limit) {
  if (limit < 1 || limit > 100) {
    throw const AppException(AppErrorCode.validation);
  }
}
