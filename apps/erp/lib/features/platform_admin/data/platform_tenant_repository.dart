import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/iam_json.dart';
import 'package:erp/features/iam/data/models/cursor_page.dart';

import 'models/platform_tenant.dart';

/// RPC quản trị nền tảng (schema `iam`). Mỗi RPC tự kiểm `has_platform_permission`
/// (BR-60). Không nhận callback tenant: Platform Admin không làm việc trong tổ
/// chức đang chọn.
class PlatformTenantRepository {
  PlatformTenantRepository({required SupabaseRpc rpc}) : _rpc = rpc;

  final SupabaseRpc _rpc;

  /// [status] ∈ `active | suspended | closed` hoặc `null` (tất cả).
  ///
  /// Luôn gửi đủ 6 tham số: PostgREST chọn hàm theo bộ tên tham số.
  Future<CursorPage<PlatformTenantSummary>> search({
    String? query,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    if (limit < 1 || limit > 100) {
      throw const AppException(AppErrorCode.validation);
    }
    final trimmedStatus = status?.trim();
    if (trimmedStatus != null &&
        trimmedStatus.isNotEmpty &&
        trimmedStatus != 'active' &&
        trimmedStatus != 'suspended' &&
        trimmedStatus != 'closed') {
      throw const AppException(AppErrorCode.validation);
    }
    final trimmedQuery = query?.trim();
    final page = iamJsonMap(
      await _rpc.call(
        'iam',
        'search_platform_tenants',
        params: <String, dynamic>{
          'p_query': (trimmedQuery == null || trimmedQuery.isEmpty) ? null : trimmedQuery,
          'p_status': (trimmedStatus == null || trimmedStatus.isEmpty) ? null : trimmedStatus,
          'p_readiness_state': null,
          'p_warning_code': null,
          'p_cursor': cursor,
          'p_page_size': limit,
        },
      ),
    );
    final rows = page['items'] as List? ?? const [];
    return CursorPage(
      items: rows
          .whereType<Map>()
          .map((raw) => PlatformTenantSummary.fromJson(Map<String, dynamic>.from(raw)))
          .toList(growable: false),
      nextCursor: page['next_cursor'] as String?,
    );
  }

  Future<PlatformTenantDetail> get(String tenantId) async {
    final row = iamJsonMap(
      await _rpc.call(
        'iam',
        'get_platform_tenant',
        params: <String, dynamic>{'p_tenant_id': tenantId},
      ),
    );
    if (row.isEmpty) throw const AppException(AppErrorCode.notFound);
    return PlatformTenantDetail.fromJson(row);
  }

  Future<List<PlatformTenantMember>> listMembers(String tenantId) async {
    final rows = await _rpc.rows(
      'iam',
      'list_platform_tenant_members',
      params: <String, dynamic>{'p_tenant_id': tenantId},
    );
    return rows.map(PlatformTenantMember.fromJson).toList(growable: false);
  }

  Future<void> suspend(
    String tenantId, {
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    await _rpc.call(
      'iam',
      'suspend_platform_tenant',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_reason': reason,
        'p_expected_version': expectedVersion,
        'p_idempotency_key': idempotencyKey,
      },
    );
  }

  /// RPC không nhận lý do (khác TH-01 US-09.3 FR-03; 8-B quyết định).
  Future<void> restore(
    String tenantId, {
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    await _rpc.call(
      'iam',
      'restore_platform_tenant',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_expected_version': expectedVersion,
        'p_idempotency_key': idempotencyKey,
      },
    );
  }

  Future<void> close(
    String tenantId, {
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    await _rpc.call(
      'iam',
      'close_platform_tenant',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_reason': reason,
        'p_expected_version': expectedVersion,
        'p_idempotency_key': idempotencyKey,
      },
    );
  }

  Future<void> transferOwnership(
    String tenantId, {
    required String newOwnerUserId,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    await _rpc.call(
      'iam',
      'transfer_platform_tenant_ownership',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_new_owner_user_id': newOwnerUserId,
        'p_expected_version': expectedVersion,
        'p_idempotency_key': idempotencyKey,
      },
    );
  }
}
