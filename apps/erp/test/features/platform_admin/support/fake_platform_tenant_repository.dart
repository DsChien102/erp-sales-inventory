import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/features/iam/data/models/cursor_page.dart';
import 'package:erp/features/platform_admin/data/models/platform_tenant.dart';
import 'package:erp/features/platform_admin/data/platform_tenant_repository.dart';

PlatformTenantSummary summary(
  String id, {
  String? name,
  TenantStatus status = TenantStatus.active,
  String? ownerName = 'Lê Thị Lan',
  int memberCount = 3,
}) {
  return PlatformTenantSummary(
    tenantId: id,
    name: name ?? 'Tổ chức $id',
    code: id.toUpperCase(),
    status: status,
    createdAt: DateTime.utc(2026, 7, 10),
    ownerName: ownerName,
    ownerEmail: 'lan@example.com',
    memberCount: memberCount,
  );
}

PlatformTenantMember member(
  String userId, {
  String name = 'Thành viên',
  bool isOwner = false,
  String role = 'Nhân viên bán hàng',
}) {
  return PlatformTenantMember(
    userId: userId,
    fullName: name,
    email: '$userId@example.com',
    roleLabel: isOwner ? 'Chủ cửa hàng' : role,
    isOwner: isOwner,
  );
}

PlatformTenantDetail detail(
  String id, {
  TenantStatus status = TenantStatus.active,
  int version = 4,
  List<PlatformTenantMember>? members,
}) {
  final list = members ??
      [
        member('owner-1', name: 'Lê Thị Lan', isOwner: true),
        member('user-2', name: 'Trần Thị Hoa'),
        member('user-3', name: 'Nguyễn Văn Minh', role: 'Kế toán'),
      ];
  return PlatformTenantDetail(
    tenantId: id,
    name: 'Mậu Hiền',
    code: 'TEN-0001',
    status: status,
    createdAt: DateTime.utc(2026, 7, 10, 10),
    version: version,
    ownerUserId: 'owner-1',
    ownerName: 'Lê Thị Lan',
    ownerEmail: 'lan@example.com',
    ownerRoleLabel: 'Chủ cửa hàng',
    lastActivityAt: DateTime.utc(2026, 7, 13, 9, 18),
    suspendedAt: status == TenantStatus.suspended ? DateTime.utc(2026, 8, 1) : null,
    suspendedBy: status == TenantStatus.suspended ? 'Admin A' : null,
    suspendReason: status == TenantStatus.suspended ? 'Vi phạm' : null,
    members: list,
  );
}

/// Một lần gọi mutation đã ghi lại.
final class RecordedCall {
  const RecordedCall(this.name, this.args);

  final String name;
  final Map<String, Object?> args;
}

class FakePlatformTenantRepository implements PlatformTenantRepository {
  FakePlatformTenantRepository({
    List<PlatformTenantSummary>? tenants,
    PlatformTenantDetail? tenantDetail,
    List<PlatformTenantMember>? tenantMembers,
  }) : tenants = tenants ?? [summary('t-1'), summary('t-2', status: TenantStatus.suspended)],
       tenantDetail = tenantDetail ?? detail('t-1'),
       tenantMembers = tenantMembers ?? detail('t-1').members;

  List<PlatformTenantSummary> tenants;
  PlatformTenantDetail tenantDetail;
  List<PlatformTenantMember> tenantMembers;

  /// Số mục mỗi trang; `null` = một trang.
  int? pageSize;

  Object? searchError;
  Object? getError;
  Object? mutationError;

  final List<Map<String, Object?>> searches = [];
  final List<RecordedCall> calls = [];
  int getCount = 0;

  @override
  Future<CursorPage<PlatformTenantSummary>> search({
    String? query,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    searches.add({'query': query, 'status': status, 'cursor': cursor});
    final error = searchError;
    if (error != null) throw error;

    final needle = (query ?? '').trim().toLowerCase();
    var rows = tenants.where((t) {
      if (status != null && t.status.name != status) return false;
      if (needle.isEmpty) return true;
      return t.name.toLowerCase().contains(needle) || t.code.toLowerCase().contains(needle);
    }).toList();
    final size = pageSize;
    if (size == null) return CursorPage(items: rows);
    final offset = cursor == null ? 0 : int.parse(cursor);
    final end = offset + size;
    final next = end < rows.length ? '$end' : null;
    rows = rows.skip(offset).take(size).toList();
    return CursorPage(items: rows, nextCursor: next);
  }

  @override
  Future<PlatformTenantDetail> get(String tenantId) async {
    getCount++;
    final error = getError;
    if (error != null) throw error;
    return tenantDetail;
  }

  @override
  Future<List<PlatformTenantMember>> listMembers(String tenantId) async => tenantMembers;

  Future<void> _record(String name, Map<String, Object?> args) async {
    calls.add(RecordedCall(name, args));
    final error = mutationError;
    if (error != null) throw error;
  }

  @override
  Future<void> suspend(
    String tenantId, {
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  }) {
    return _record('suspend', {
      'tenantId': tenantId,
      'reason': reason,
      'expectedVersion': expectedVersion,
      'key': idempotencyKey,
    });
  }

  @override
  Future<void> restore(
    String tenantId, {
    required int expectedVersion,
    required String idempotencyKey,
  }) {
    return _record('restore', {
      'tenantId': tenantId,
      'expectedVersion': expectedVersion,
      'key': idempotencyKey,
    });
  }

  @override
  Future<void> close(
    String tenantId, {
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  }) {
    return _record('close', {
      'tenantId': tenantId,
      'reason': reason,
      'expectedVersion': expectedVersion,
      'key': idempotencyKey,
    });
  }

  @override
  Future<void> transferOwnership(
    String tenantId, {
    required String newOwnerUserId,
    required int expectedVersion,
    required String idempotencyKey,
  }) {
    return _record('transfer', {
      'tenantId': tenantId,
      'newOwnerUserId': newOwnerUserId,
      'expectedVersion': expectedVersion,
      'key': idempotencyKey,
    });
  }
}

/// Mã lỗi nghiệp vụ như máy chủ trả.
AppException serverError(String code) => AppException(code);
