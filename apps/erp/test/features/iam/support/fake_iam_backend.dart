import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/audit_log_repository.dart';
import 'package:erp/features/iam/data/invitation_repository.dart';
import 'package:erp/features/iam/data/member_repository.dart';
import 'package:erp/features/iam/data/models/cursor_page.dart';
import 'package:erp/features/iam/data/models/tenant_audit_log.dart';
import 'package:erp/features/iam/data/models/tenant_invitation.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import 'package:supabase/supabase.dart';

/// Kịch bản của backend IAM giả. Tên giữ theo bảng kịch bản của TH-01 / EP-05
/// để test và tài liệu cùng một cách gọi.
enum FakeIamScenario {
  /// Mặc định: danh sách + chi tiết + vòng đời hoạt động bình thường.
  usersSearchOk,

  // ── S10 vòng đời thành viên ──
  memberDetailOk,
  memberNotFound,
  memberDeactivateOk,
  memberReactivateOk,
  memberRemoveOk,
  memberLastOwnerProtected,
  memberStateChanged,
  memberRemovedTerminal,
  memberForbidden,

  // ── S13 nhật ký tổ chức ──
  tenantAuditSearchOk,
  tenantAuditDetailOk,
  tenantAuditEmpty,
  tenantAuditForbidden,
  tenantAuditProviderError,
  tenantAuditActorUnavailable,
  tenantAuditCrossTenant,

  // ── S6 thành viên + lời mời ──
  membersSearchOk,
  membersFilterInactive,
  invitationsSearchOk,
  invitationsExpired,
  invitationDetailOk,
  memberInvitationForbidden,
  memberInvitationCrossTenantNotFound,

  // ── S7 tạo lời mời ──
  inviteOk,
  inviteDuplicateMembership,
  inviteInactiveMembership,
  invitePendingExists,
  inviteRoleNotAssignable,
  inviteDeliveryFailed,
  inviteIdempotentRetry,
  inviteIdempotencyConflict,
  inviteForbidden,

  // ── S1–S3 ngữ cảnh tổ chức (đọc bởi FakeSessionRepository) ──
  tenantsSingle,
  tenantsMulti,
  tenantsSuspendedDisabled,
  tenantsProvisioning,
  tenantsClosedDisabled,
  tenantsExcludesInactiveMembership,
  switchOk,
  switchDenied,
  switchSuspended,
  switchClosed,
  bootstrapValid,
  bootstrapInvalid,
  contextNone,
  contextInvalidated,

  // ── S8 nhận / từ chối lời mời (đọc bởi ScriptedInvitations) ──
  inspectExistingAccount,
  inspectNewAccount,
  inspectInvalidNoLeak,
  acceptExistingAccountOk,
  registerAndAcceptOk,
  registerIdentityConflict,
  acceptEmailMismatch,
  acceptExpired,
  acceptRotatedToken,
  acceptDeclined,
  acceptConcurrent,
  acceptTenantSuspended,
  acceptRetryAfterIdentityCreated,
  declineOk,

  // ── S9 gửi lại / thu hồi ──
  invitationResendOk,
  invitationRevokeOk,
  invitationStateChanged,
  invitationTerminalReject,
  invitationCrossTenantNotFound,
  invitationResendDeliveryFailed,

  // ── S14 tài khoản của tôi ──
  myAccountOk,
  myAccountUpdateOk,
  passwordResetCompleteOk,
  signOutRemoteError,
  authSessionOk,
}

// ─── Lời gọi được ghi lại ─────────────────────────────────────────────────
// Cùng tên trường với tham số RPC để test đọc lại đối số một cách tự nhiên.

final class ListTenantMembersQuery {
  const ListTenantMembersQuery({
    required this.tenantId,
    this.search,
    this.status,
    this.cursor,
    this.limit = 20,
  });

  final String tenantId;
  final String? search;
  final String? status;
  final String? cursor;
  final int limit;
}

final class GetTenantMemberQuery {
  const GetTenantMemberQuery({required this.tenantId, required this.membershipId});

  final String tenantId;
  final String membershipId;
}

final class AssignMemberRoleCommand {
  const AssignMemberRoleCommand({
    required this.tenantId,
    required this.userId,
    required this.role,
  });

  final String tenantId;
  final String userId;
  final String role;
}

final class DeactivateMembershipCommand {
  const DeactivateMembershipCommand({
    required this.tenantId,
    required this.membershipId,
    required this.expectedVersion,
  });

  final String tenantId;
  final String membershipId;
  final int expectedVersion;
}

final class ReactivateMembershipCommand {
  const ReactivateMembershipCommand({
    required this.tenantId,
    required this.membershipId,
    required this.expectedVersion,
  });

  final String tenantId;
  final String membershipId;
  final int expectedVersion;
}

final class RemoveMembershipCommand {
  const RemoveMembershipCommand({
    required this.tenantId,
    required this.membershipId,
    required this.expectedVersion,
  });

  final String tenantId;
  final String membershipId;
  final int expectedVersion;
}

final class ListInvitationsQuery {
  const ListInvitationsQuery({
    required this.tenantId,
    this.search,
    this.status,
    this.cursor,
    this.limit = 20,
  });

  final String tenantId;
  final String? search;
  final String? status;
  final String? cursor;
  final int limit;
}

final class GetInvitationQuery {
  const GetInvitationQuery({required this.tenantId, required this.invitationId});

  final String tenantId;
  final String invitationId;
}

final class ListAssignableInvitationRolesQuery {
  const ListAssignableInvitationRolesQuery({required this.tenantId});

  final String tenantId;
}

final class CreateInvitationCommand {
  const CreateInvitationCommand({
    required this.tenantId,
    required this.inviteeEmail,
    required this.initialRoleId,
    required this.idempotencyKey,
  });

  final String tenantId;
  final String inviteeEmail;
  final String initialRoleId;
  final String idempotencyKey;
}

final class ResendInvitationCommand {
  const ResendInvitationCommand({
    required this.tenantId,
    required this.invitationId,
    required this.expectedVersion,
    required this.idempotencyKey,
  });

  final String tenantId;
  final String invitationId;
  final int expectedVersion;
  final String idempotencyKey;
}

final class RevokeInvitationCommand {
  const RevokeInvitationCommand({
    required this.tenantId,
    required this.invitationId,
    required this.expectedVersion,
    required this.reason,
    required this.idempotencyKey,
  });

  final String tenantId;
  final String invitationId;
  final int expectedVersion;
  final String reason;
  final String idempotencyKey;
}

final class SearchTenantAuditLogsQuery {
  const SearchTenantAuditLogsQuery({
    required this.tenantId,
    required this.fromUtc,
    required this.toUtc,
    this.query,
    this.result,
    this.eventCategory,
    this.subjectType,
    this.eventCodes,
    this.cursor,
    this.limit = 20,
  });

  final String tenantId;
  final DateTime fromUtc;
  final DateTime toUtc;
  final String? query;
  final String? result;
  final String? eventCategory;
  final String? subjectType;
  final List<String>? eventCodes;
  final String? cursor;
  final int limit;
}

final class GetTenantAuditLogQuery {
  const GetTenantAuditLogQuery({required this.tenantId, required this.auditLogId});

  final String tenantId;
  final String auditLogId;
}

// ─── Backend giả ──────────────────────────────────────────────────────────

/// Backend IAM giả cho test cubit / trang: dữ liệu mẫu + hành vi theo
/// [FakeIamScenario], ghi lại mọi lời gọi (`queriesOf` / `commandsOf`).
///
/// Ba repository giả bên dưới ([FakeMemberRepository], [FakeInvitationRepository],
/// [FakeAuditLogRepository]) chỉ chuyển lời gọi vào đây.
final class FakeIamBackend {
  FakeIamBackend({
    this.scenario = FakeIamScenario.usersSearchOk,
    this.tenantId = 'org-001',
    this.onListMembers,
    this.onListInvitations,
    this.onSearchAudit,
    this.onGetAuditDetail,
  }) {
    _seed();
  }

  final FakeIamScenario scenario;
  final String tenantId;

  /// Thay thế kết quả danh sách thành viên bằng dữ liệu của test (vẫn ghi lại lời gọi).
  final Future<CursorPage<TenantMember>> Function(ListTenantMembersQuery query)? onListMembers;

  /// Thay thế kết quả danh sách lời mời bằng dữ liệu của test (vẫn ghi lại lời gọi).
  final Future<CursorPage<TenantInvitation>> Function(ListInvitationsQuery query)?
  onListInvitations;

  /// Thay thế kết quả tìm / chi tiết nhật ký bằng dữ liệu của test (vẫn ghi lại lời gọi).
  final Future<TenantAuditLogPage> Function(SearchTenantAuditLogsQuery query)? onSearchAudit;
  final Future<TenantAuditLogDetail> Function(GetTenantAuditLogQuery query)? onGetAuditDetail;

  final List<Object> queries = <Object>[];
  final List<Object> commands = <Object>[];

  Iterable<T> queriesOf<T>() => queries.whereType<T>();

  Iterable<T> commandsOf<T>() => commands.whereType<T>();

  late List<TenantMemberDetail> _memberships;
  late List<TenantMember> _memberSummaries;
  late List<TenantInvitationDetail> _invitations;
  late List<TenantAuditLogItem> _auditSummaries;
  late TenantAuditLogDetail _auditDetail;
  final Map<String, TenantInvitationDetail> _invitationByIdempotency = {};
  final Map<String, String> _invitationPayloadByKey = {};

  static AppException _blocked(String code) => AppException(code);

  // ── Thành viên ──

  Future<CursorPage<TenantMember>> listMembers(ListTenantMembersQuery query) async {
    queries.add(query);
    final scripted = onListMembers;
    if (scripted != null) return scripted(query);
    if (scenario == FakeIamScenario.memberInvitationForbidden) {
      throw _blocked(IamBlockedCodes.permissionDenied);
    }
    var rows = _memberSummaries.toList(growable: false);
    final search = query.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) {
      rows = rows
          .where(
            (m) =>
                m.displayName.toLowerCase().contains(search) ||
                m.email.toLowerCase().contains(search),
          )
          .toList(growable: false);
    }
    final status = query.status?.trim();
    if (status != null && status.isNotEmpty) {
      rows = rows.where((m) => m.status == status).toList(growable: false);
    }
    if (scenario == FakeIamScenario.membersFilterInactive) {
      rows = rows.where((m) => m.status == 'inactive').toList(growable: false);
    }
    final limit = query.limit.clamp(1, 100);
    return CursorPage(
      items: rows.take(limit).toList(growable: false),
      nextCursor: rows.length > limit ? 'next' : null,
    );
  }

  Future<TenantMemberDetail> getMember(GetTenantMemberQuery query) async {
    queries.add(query);
    if (scenario == FakeIamScenario.memberNotFound) {
      throw _blocked(IamBlockedCodes.resourceNotFound);
    }
    return _memberships[_membershipIndex(query.membershipId)];
  }

  Future<TenantMemberDetail> deactivate(DeactivateMembershipCommand command) async {
    commands.add(command);
    if (scenario == FakeIamScenario.memberForbidden) {
      throw _blocked(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.memberLastOwnerProtected) {
      throw _blocked(IamBlockedCodes.lastOwnerProtected);
    }
    if (scenario == FakeIamScenario.memberStateChanged) {
      throw _blocked(IamBlockedCodes.stateChanged);
    }
    final index = _membershipIndex(command.membershipId);
    final current = _memberships[index];
    if (current.version != command.expectedVersion) {
      throw _blocked(IamBlockedCodes.stateChanged);
    }
    if (current.isSoleOwner) {
      throw _blocked(IamBlockedCodes.lastOwnerProtected);
    }
    return _memberships[index] = _withStatus(current, MembershipStatus.inactive);
  }

  Future<TenantMemberDetail> reactivate(ReactivateMembershipCommand command) async {
    commands.add(command);
    if (scenario == FakeIamScenario.memberForbidden) {
      throw _blocked(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.memberRemovedTerminal) {
      throw _blocked(IamBlockedCodes.membershipRemoved);
    }
    if (scenario == FakeIamScenario.memberStateChanged) {
      throw _blocked(IamBlockedCodes.stateChanged);
    }
    final index = _membershipIndex(command.membershipId);
    final current = _memberships[index];
    if (current.status == MembershipStatus.removed) {
      throw _blocked(IamBlockedCodes.membershipRemoved);
    }
    if (current.version != command.expectedVersion) {
      throw _blocked(IamBlockedCodes.stateChanged);
    }
    return _memberships[index] = _withStatus(current, MembershipStatus.active);
  }

  Future<TenantMemberDetail> remove(RemoveMembershipCommand command) async {
    commands.add(command);
    if (scenario == FakeIamScenario.memberForbidden) {
      throw _blocked(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.memberLastOwnerProtected) {
      throw _blocked(IamBlockedCodes.lastOwnerProtected);
    }
    final index = _membershipIndex(command.membershipId);
    final current = _memberships[index];
    if (current.isSoleOwner) {
      throw _blocked(IamBlockedCodes.lastOwnerProtected);
    }
    if (current.version != command.expectedVersion) {
      throw _blocked(IamBlockedCodes.stateChanged);
    }
    return _memberships[index] = _withStatus(current, MembershipStatus.removed);
  }

  Future<void> assignRole(AssignMemberRoleCommand command) async {
    commands.add(command);
    if (scenario == FakeIamScenario.memberForbidden) {
      throw _blocked(IamBlockedCodes.permissionDenied);
    }
    final index = _memberships.indexWhere(
      (m) => m.tenantId == command.tenantId && m.userId == command.userId,
    );
    if (index == -1) return;
    final current = _memberships[index];
    final roleLabel = switch (command.role) {
      'store_owner' => 'Chủ cửa hàng',
      'staff' => 'Nhân viên bán hàng',
      'accountant' => 'Kế toán',
      'warehouse' => 'Thủ kho',
      _ => command.role,
    };
    _memberships[index] = TenantMemberDetail(
      membershipId: current.membershipId,
      tenantId: current.tenantId,
      userId: current.userId,
      displayName: current.displayName,
      email: current.email,
      role: command.role,
      roleLabel: roleLabel,
      isOwner: current.isOwner,
      isSoleOwner: current.isSoleOwner,
      status: current.status,
      version: current.version + 1,
      joinedAt: current.joinedAt,
      lastActivityAt: current.lastActivityAt,
      statusChangedAt: DateTime.now(),
      removedAt: current.removedAt,
    );
  }

  int _membershipIndex(String membershipId) {
    final index = _memberships.indexWhere(
      (m) => m.tenantId == tenantId && m.membershipId == membershipId,
    );
    if (index == -1) throw _blocked(IamBlockedCodes.resourceNotFound);
    return index;
  }

  /// Chỉ giữ các trường mà RPC vòng đời trả về (không có tên / email).
  TenantMemberDetail _withStatus(TenantMemberDetail current, MembershipStatus status) {
    final now = DateTime.now();
    return TenantMemberDetail(
      membershipId: current.membershipId,
      tenantId: current.tenantId,
      userId: current.userId,
      role: current.role,
      isOwner: current.isOwner,
      isSoleOwner: current.isSoleOwner,
      status: status,
      version: current.version + 1,
      joinedAt: current.joinedAt,
      statusChangedAt: now,
      removedAt: status == MembershipStatus.removed ? now : null,
    );
  }

  // ── Lời mời ──

  Future<CursorPage<TenantInvitation>> listInvitations(ListInvitationsQuery query) async {
    queries.add(query);
    final scripted = onListInvitations;
    if (scripted != null) return scripted(query);
    if (scenario == FakeIamScenario.memberInvitationForbidden) {
      throw _blocked(IamBlockedCodes.permissionDenied);
    }
    var rows = _invitations.map((i) => i.toSummary()).toList(growable: false);
    final search = query.search?.trim().toLowerCase();
    if (search != null && search.isNotEmpty) {
      rows = rows
          .where((i) => i.inviteeEmail.toLowerCase().contains(search))
          .toList(growable: false);
    }
    final status = query.status?.trim();
    if (status != null && status.isNotEmpty) {
      rows = rows.where((i) => i.status == status).toList(growable: false);
    }
    if (scenario == FakeIamScenario.invitationsExpired) {
      rows = rows.where((i) => i.status == 'expired').toList(growable: false);
    }
    final limit = query.limit.clamp(1, 100);
    return CursorPage(
      items: rows.take(limit).toList(growable: false),
      nextCursor: rows.length > limit ? 'next' : null,
    );
  }

  Future<TenantInvitationDetail> getInvitation(GetInvitationQuery query) async {
    queries.add(query);
    if (scenario == FakeIamScenario.memberInvitationForbidden) {
      throw _blocked(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.memberInvitationCrossTenantNotFound) {
      throw _blocked(IamBlockedCodes.resourceNotFound);
    }
    final found = _findInvitation(query.invitationId);
    if (found == null) throw _blocked(IamBlockedCodes.resourceNotFound);
    return found;
  }

  Future<List<AssignableInvitationRole>> listAssignableRoles(
    ListAssignableInvitationRolesQuery query,
  ) async {
    queries.add(query);
    if (scenario == FakeIamScenario.memberInvitationForbidden ||
        scenario == FakeIamScenario.inviteForbidden) {
      throw _blocked(IamBlockedCodes.permissionDenied);
    }
    return const [
      AssignableInvitationRole(roleId: 'role-staff', label: 'Nhân viên bán hàng'),
      AssignableInvitationRole(roleId: 'role-warehouse', label: 'Thủ kho'),
      AssignableInvitationRole(roleId: 'role-accountant', label: 'Kế toán'),
      AssignableInvitationRole(roleId: 'role-manager', label: 'Quản lý'),
    ];
  }

  Future<TenantInvitationDetail> createInvitation(CreateInvitationCommand command) async {
    commands.add(command);
    if (scenario == FakeIamScenario.inviteForbidden ||
        scenario == FakeIamScenario.memberInvitationForbidden) {
      throw _blocked(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.inviteDuplicateMembership) {
      throw _blocked(IamBlockedCodes.duplicateMembership);
    }
    if (scenario == FakeIamScenario.inviteInactiveMembership) {
      throw _blocked(IamBlockedCodes.membershipInactive);
    }
    if (scenario == FakeIamScenario.invitePendingExists) {
      throw _blocked(IamBlockedCodes.invitationPendingExists);
    }
    if (scenario == FakeIamScenario.inviteRoleNotAssignable) {
      throw _blocked(IamBlockedCodes.roleNotAssignable);
    }
    if (scenario == FakeIamScenario.inviteIdempotencyConflict) {
      throw _blocked(IamBlockedCodes.idempotencyConflict);
    }

    final email = command.inviteeEmail.trim().toLowerCase();
    final roleId = command.initialRoleId.trim();
    final key = command.idempotencyKey.trim();
    final payload = '${command.tenantId}|$email|$roleId';

    final existing = _invitationByIdempotency[key];
    if (existing != null) {
      if (_invitationPayloadByKey[key] != payload) {
        throw _blocked(IamBlockedCodes.idempotencyConflict);
      }
      return existing;
    }

    final now = DateTime.utc(2026, 7, 29, 12);
    final created = TenantInvitationDetail(
      invitationId: 'inv-created-${_invitationByIdempotency.length + 1}',
      inviteeEmail: email,
      initialRoleId: roleId,
      initialRoleLabel: 'Nhân viên bán hàng',
      status: 'pending',
      expiresAt: now.add(const Duration(days: 7)),
      deliveryStatus: scenario == FakeIamScenario.inviteDeliveryFailed ? 'failed' : 'queued',
      deliveryCorrelationId: 'corr-$key',
      version: 1,
      createdAt: now,
      createdBy: 'lan-le',
      lastSentAt: now,
    );
    _invitationByIdempotency[key] = created;
    _invitationPayloadByKey[key] = payload;
    _invitations = [..._invitations, created];
    return created;
  }

  Future<TenantInvitationDetail> resendInvitation(ResendInvitationCommand command) async {
    commands.add(command);
    _throwInvitationScenarioErrors();

    final key = command.idempotencyKey.trim();
    final existing = _invitationByIdempotency[key];
    if (existing != null) return existing;

    final current = _pendingInvitation(command.invitationId, command.expectedVersion);
    final now = DateTime.utc(2026, 7, 30, 12);
    final resent = TenantInvitationDetail(
      invitationId: current.invitationId,
      inviteeEmail: current.inviteeEmail,
      initialRoleId: current.initialRoleId,
      initialRoleLabel: current.initialRoleLabel,
      status: 'pending',
      expiresAt: now.add(const Duration(days: 7)),
      deliveryStatus: scenario == FakeIamScenario.invitationResendDeliveryFailed
          ? 'failed'
          : 'queued',
      deliveryCorrelationId: 'corr-resend-$key',
      version: current.version + 1,
      createdAt: current.createdAt,
      createdBy: current.createdBy,
      lastSentAt: now,
    );
    return _replaceInvitation(key, resent);
  }

  Future<TenantInvitationDetail> revokeInvitation(RevokeInvitationCommand command) async {
    commands.add(command);
    _throwInvitationScenarioErrors();

    final key = command.idempotencyKey.trim();
    final existing = _invitationByIdempotency[key];
    if (existing != null) return existing;

    final current = _pendingInvitation(command.invitationId, command.expectedVersion);
    final revoked = TenantInvitationDetail(
      invitationId: current.invitationId,
      inviteeEmail: current.inviteeEmail,
      initialRoleId: current.initialRoleId,
      initialRoleLabel: current.initialRoleLabel,
      status: 'revoked',
      expiresAt: current.expiresAt,
      deliveryStatus: current.deliveryStatus,
      deliveryCorrelationId: current.deliveryCorrelationId,
      version: current.version + 1,
      createdAt: current.createdAt,
      createdBy: current.createdBy,
      lastSentAt: current.lastSentAt,
      revokedAt: DateTime.utc(2026, 7, 30, 12),
    );
    return _replaceInvitation(key, revoked);
  }

  void _throwInvitationScenarioErrors() {
    if (scenario == FakeIamScenario.invitationCrossTenantNotFound) {
      throw _blocked(IamBlockedCodes.resourceNotFound);
    }
    if (scenario == FakeIamScenario.invitationStateChanged) {
      throw _blocked(IamBlockedCodes.stateChanged);
    }
    if (scenario == FakeIamScenario.invitationTerminalReject) {
      throw _blocked(IamBlockedCodes.invitationAlreadyUsed);
    }
  }

  TenantInvitationDetail _pendingInvitation(String invitationId, int expectedVersion) {
    final current = _findInvitation(invitationId);
    if (current == null) throw _blocked(IamBlockedCodes.resourceNotFound);
    if (current.version != expectedVersion) throw _blocked(IamBlockedCodes.stateChanged);
    if (current.status != 'pending') throw _blocked(IamBlockedCodes.invitationAlreadyUsed);
    return current;
  }

  TenantInvitationDetail _replaceInvitation(String key, TenantInvitationDetail updated) {
    _invitationByIdempotency[key] = updated;
    _invitations = [
      for (final row in _invitations)
        if (row.invitationId == updated.invitationId) updated else row,
    ];
    return updated;
  }

  TenantInvitationDetail? _findInvitation(String invitationId) {
    for (final row in _invitations) {
      if (row.invitationId == invitationId) return row;
    }
    return null;
  }

  // ── Nhật ký tổ chức ──

  Future<TenantAuditLogPage> searchAudit(SearchTenantAuditLogsQuery query) async {
    queries.add(query);
    final scripted = onSearchAudit;
    if (scripted != null) return scripted(query);
    if (scenario == FakeIamScenario.tenantAuditForbidden) {
      throw _blocked(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.tenantAuditProviderError) {
      throw _blocked(IamBlockedCodes.systemError);
    }
    if (scenario == FakeIamScenario.tenantAuditEmpty ||
        scenario == FakeIamScenario.tenantAuditCrossTenant) {
      return const TenantAuditLogPage(items: [], totalCount: 0);
    }
    var items = _auditSummaries.toList();
    final eventCodes = query.eventCodes;
    if (eventCodes != null && eventCodes.isNotEmpty) {
      items = items.where((s) => eventCodes.contains(s.eventCode)).toList();
    }
    final result = query.result;
    if (result != null) {
      items = items.where((s) => s.result.code == result).toList();
    }
    final subjectType = query.subjectType;
    if (subjectType != null) {
      items = items.where((s) => s.subject.type == subjectType).toList();
    }
    final queryText = query.query;
    if (queryText != null && queryText.isNotEmpty) {
      final q = queryText.toLowerCase();
      items = items
          .where(
            (s) =>
                (s.actor.displayName?.toLowerCase().contains(q) ?? false) ||
                (s.subject.displayName?.toLowerCase().contains(q) ?? false) ||
                s.eventCode.toLowerCase().contains(q) ||
                s.auditLogId.toLowerCase().contains(q) ||
                s.trackingId.toLowerCase().contains(q) ||
                (s.actor.userId?.toLowerCase() == q) ||
                (s.subject.id?.toLowerCase() == q),
          )
          .toList();
    }
    // Phân trang theo cursor: trang đầu có cursor mờ, trang sau thì hết.
    final nextCursor = query.cursor == null && items.isNotEmpty ? 'opaque-next-cursor' : null;
    return TenantAuditLogPage(
      items: items,
      totalCount: items.length,
      nextCursor: nextCursor,
    );
  }

  Future<TenantAuditLogDetail> getAuditDetail(GetTenantAuditLogQuery query) async {
    queries.add(query);
    final scripted = onGetAuditDetail;
    if (scripted != null) return scripted(query);
    if (scenario == FakeIamScenario.tenantAuditForbidden) {
      throw _blocked(IamBlockedCodes.permissionDenied);
    }
    if (scenario == FakeIamScenario.tenantAuditProviderError) {
      throw _blocked(IamBlockedCodes.systemError);
    }
    final base = _auditDetail;
    if (scenario == FakeIamScenario.tenantAuditActorUnavailable) {
      return TenantAuditLogDetail(
        auditLogId: query.auditLogId,
        tenantId: query.tenantId,
        eventCode: base.eventCode,
        result: base.result,
        occurredAt: base.occurredAt,
        source: base.source,
        trackingId: base.trackingId,
        actorUnavailable: true,
        beforeRedacted: base.beforeRedacted,
        afterRedacted: base.afterRedacted,
        actor: const TenantAuditActor(
          userId: 'lan-le',
          displayName: null,
          actorType: 'user',
          roleCode: null,
          roleLabel: null,
          displayOrigin: TenantAuditDisplayOrigin.unavailable,
        ),
        subject: base.subject,
        beforeState: base.beforeState,
        afterState: base.afterState,
      );
    }
    if (scenario == FakeIamScenario.tenantAuditCrossTenant) {
      throw _blocked(IamBlockedCodes.resourceNotFound);
    }
    if (query.auditLogId == 'AUD-REDACTED') {
      return TenantAuditLogDetail(
        auditLogId: query.auditLogId,
        tenantId: query.tenantId,
        eventCode: base.eventCode,
        result: base.result,
        occurredAt: base.occurredAt,
        source: base.source,
        trackingId: base.trackingId,
        actorUnavailable: false,
        beforeRedacted: true,
        afterRedacted: true,
        actor: base.actor,
        subject: base.subject,
        beforeState: base.beforeState,
        afterState: base.afterState,
      );
    }
    if (query.auditLogId != base.auditLogId || query.tenantId != base.tenantId) {
      throw _blocked(IamBlockedCodes.resourceNotFound);
    }
    return base;
  }

  // ── Dữ liệu mẫu ──

  void _seed() {
    _memberships = [
      TenantMemberDetail(
        membershipId: 'mem-owner-1',
        tenantId: 'org-001',
        userId: 'lan-le',
        displayName: 'Lan Le',
        email: 'lan@gmail.com',
        role: 'owner',
        roleLabel: 'Chủ cửa hàng',
        isOwner: true,
        isSoleOwner: true,
        status: MembershipStatus.active,
        version: 1,
        joinedAt: DateTime(2026, 1, 1),
        lastActivityAt: DateTime(2026, 7, 14, 9, 18),
      ),
      TenantMemberDetail(
        membershipId: 'mem-staff-1',
        tenantId: 'org-001',
        userId: 'hoa-tran',
        displayName: 'Hoa Tran',
        email: 'hoa@example.com',
        role: 'staff',
        roleLabel: 'Nhân viên bán hàng',
        isOwner: false,
        isSoleOwner: false,
        status: MembershipStatus.active,
        version: 1,
        joinedAt: DateTime(2026, 2, 1),
        lastActivityAt: DateTime(2026, 7, 14, 9, 18),
      ),
      TenantMemberDetail(
        membershipId: 'mem-inactive-1',
        tenantId: 'org-001',
        userId: 'minh-nguyen',
        displayName: 'Minh Nguyen',
        email: 'minh@example.com',
        role: 'staff',
        roleLabel: 'Nhân viên bán hàng',
        isOwner: false,
        isSoleOwner: false,
        status: MembershipStatus.inactive,
        version: 2,
        joinedAt: DateTime(2026, 3, 1),
        lastActivityAt: DateTime(2026, 3, 15, 10),
        statusChangedAt: DateTime(2026, 3, 15),
      ),
      TenantMemberDetail(
        membershipId: 'mem-removed-1',
        tenantId: 'org-001',
        userId: 'old-user',
        displayName: 'Old User',
        email: 'old@example.com',
        role: 'staff',
        roleLabel: 'Nhân viên bán hàng',
        isOwner: false,
        isSoleOwner: false,
        status: MembershipStatus.removed,
        version: 3,
        joinedAt: DateTime(2026, 1, 10),
        statusChangedAt: DateTime(2026, 4),
        removedAt: DateTime(2026, 4),
      ),
    ];
    _memberSummaries = [
      TenantMember(
        membershipId: 'mem-owner-1',
        userId: 'lan-le',
        displayName: 'Lan Le',
        email: 'lan@gmail.com',
        roleId: 'role-owner',
        roleLabel: 'Chủ cửa hàng',
        isOwner: true,
        status: 'active',
        joinedAt: DateTime(2026, 1, 1),
        version: 1,
      ),
      TenantMember(
        membershipId: 'mem-staff-1',
        userId: 'hoa-tran',
        displayName: 'Hoa Tran',
        email: 'hoa@example.com',
        roleId: 'role-staff',
        roleLabel: 'Nhân viên bán hàng',
        isOwner: false,
        status: 'active',
        joinedAt: DateTime(2026, 2, 1),
        version: 1,
      ),
      TenantMember(
        membershipId: 'mem-inactive-1',
        userId: 'minh-nguyen',
        displayName: 'Minh Nguyen',
        email: 'minh@example.com',
        roleId: 'role-staff',
        roleLabel: 'Nhân viên bán hàng',
        isOwner: false,
        status: 'inactive',
        joinedAt: DateTime(2026, 3, 1),
        version: 2,
      ),
    ];
    _invitations = [
      TenantInvitationDetail(
        invitationId: 'inv-1',
        inviteeEmail: 'invitee@example.com',
        initialRoleId: 'role-staff',
        initialRoleLabel: 'Nhân viên bán hàng',
        status: 'pending',
        expiresAt: DateTime.utc(2026, 8, 5),
        deliveryStatus: 'sent',
        deliveryCorrelationId: 'corr-inv-1',
        version: 1,
        createdAt: DateTime.utc(2026, 7, 29),
        createdBy: 'lan-le',
        lastSentAt: DateTime.utc(2026, 7, 29),
      ),
      TenantInvitationDetail(
        invitationId: 'inv-expired',
        inviteeEmail: 'old@example.com',
        initialRoleId: 'role-staff',
        initialRoleLabel: 'Nhân viên bán hàng',
        status: 'expired',
        expiresAt: DateTime.utc(2026, 7),
        deliveryStatus: 'sent',
        deliveryCorrelationId: 'corr-inv-exp',
        version: 2,
        createdAt: DateTime.utc(2026, 6, 20),
        createdBy: 'lan-le',
        lastSentAt: DateTime.utc(2026, 6, 20),
      ),
    ];
    const actor = TenantAuditActor(
      userId: 'lan-le',
      displayName: 'Lê Thị Lan',
      actorType: 'user',
      roleCode: 'store_owner',
      roleLabel: 'Chủ sở hữu',
      displayOrigin: TenantAuditDisplayOrigin.snapshot,
    );
    const subject = TenantAuditSubject(
      type: 'tenant',
      id: 'org-001',
      displayName: 'Chi nhánh Quận 1',
      code: 'CN-Q1',
      secondaryLabel: null,
      displayOrigin: TenantAuditDisplayOrigin.snapshot,
    );
    _auditSummaries = [
      TenantAuditLogItem(
        auditLogId: 'AUD-T-001',
        eventCode: 'iam.tenant.profile.updated',
        result: TenantAuditLogResult.success,
        occurredAt: DateTime.utc(2026, 7, 13, 8),
        source: 'tenant-app',
        trackingId: 'TRK-001',
        actor: actor,
        subject: subject,
      ),
    ];
    _auditDetail = TenantAuditLogDetail(
      auditLogId: 'AUD-T-001',
      tenantId: 'org-001',
      eventCode: 'iam.tenant.profile.updated',
      result: TenantAuditLogResult.success,
      occurredAt: DateTime.utc(2026, 7, 13, 8),
      source: 'tenant-app',
      trackingId: 'TRK-001',
      actorUnavailable: false,
      beforeRedacted: false,
      afterRedacted: false,
      actor: actor,
      subject: subject,
      beforeState: const {'display_name': 'Old'},
      afterState: const {'display_name': 'New'},
    );
  }
}

// ─── Repository giả ───────────────────────────────────────────────────────

SupabaseRpc get _unusedRpc => SupabaseRpc(
  SupabaseClient(
    'http://127.0.0.1',
    'anon',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  ),
);

final class FakeMemberRepository extends MemberRepository {
  FakeMemberRepository(this.backend) : super(rpc: _unusedRpc, tenantId: () async => backend.tenantId);

  final FakeIamBackend backend;

  @override
  Future<CursorPage<TenantMember>> listMembers({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) {
    return backend.listMembers(
      ListTenantMembersQuery(
        tenantId: backend.tenantId,
        search: search,
        status: status,
        cursor: cursor,
        limit: limit,
      ),
    );
  }

  @override
  Future<TenantMemberDetail> getMember(String membershipId) {
    return backend.getMember(
      GetTenantMemberQuery(tenantId: backend.tenantId, membershipId: membershipId),
    );
  }

  @override
  Future<void> assignRole({required String userId, required String role}) {
    return backend.assignRole(
      AssignMemberRoleCommand(tenantId: backend.tenantId, userId: userId, role: role),
    );
  }

  @override
  Future<TenantMemberDetail> deactivate(String membershipId, {required int expectedVersion}) {
    return backend.deactivate(
      DeactivateMembershipCommand(
        tenantId: backend.tenantId,
        membershipId: membershipId,
        expectedVersion: expectedVersion,
      ),
    );
  }

  @override
  Future<TenantMemberDetail> reactivate(String membershipId, {required int expectedVersion}) {
    return backend.reactivate(
      ReactivateMembershipCommand(
        tenantId: backend.tenantId,
        membershipId: membershipId,
        expectedVersion: expectedVersion,
      ),
    );
  }

  @override
  Future<TenantMemberDetail> remove(String membershipId, {required int expectedVersion}) {
    return backend.remove(
      RemoveMembershipCommand(
        tenantId: backend.tenantId,
        membershipId: membershipId,
        expectedVersion: expectedVersion,
      ),
    );
  }
}

final class FakeInvitationRepository extends InvitationRepository {
  FakeInvitationRepository(this.backend)
    : super(rpc: _unusedRpc, tenantId: () async => backend.tenantId);

  final FakeIamBackend backend;

  @override
  Future<CursorPage<TenantInvitation>> listInvitations({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) {
    return backend.listInvitations(
      ListInvitationsQuery(
        tenantId: backend.tenantId,
        search: search,
        status: status,
        cursor: cursor,
        limit: limit,
      ),
    );
  }

  @override
  Future<TenantInvitationDetail> getInvitation(String invitationId) {
    return backend.getInvitation(
      GetInvitationQuery(tenantId: backend.tenantId, invitationId: invitationId),
    );
  }

  @override
  Future<TenantInvitationDetail> create({
    required String email,
    required String roleCode,
    required String idempotencyKey,
  }) {
    return backend.createInvitation(
      CreateInvitationCommand(
        tenantId: backend.tenantId,
        inviteeEmail: email,
        initialRoleId: roleCode,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<TenantInvitationDetail> resend(
    String invitationId, {
    required int expectedVersion,
    required String idempotencyKey,
  }) {
    return backend.resendInvitation(
      ResendInvitationCommand(
        tenantId: backend.tenantId,
        invitationId: invitationId,
        expectedVersion: expectedVersion,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<TenantInvitationDetail> revoke(
    String invitationId, {
    required int expectedVersion,
    required String reason,
    required String idempotencyKey,
  }) {
    return backend.revokeInvitation(
      RevokeInvitationCommand(
        tenantId: backend.tenantId,
        invitationId: invitationId,
        expectedVersion: expectedVersion,
        reason: reason,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  @override
  Future<List<AssignableInvitationRole>> listAssignableRoles() async {
    final rows = await backend.listAssignableRoles(
      ListAssignableInvitationRolesQuery(tenantId: backend.tenantId),
    );
    return rows
        .where((row) => row.roleId.isNotEmpty && row.label.isNotEmpty)
        .toList(growable: false);
  }
}

final class FakeAuditLogRepository extends AuditLogRepository {
  FakeAuditLogRepository(this.backend)
    : super(rpc: _unusedRpc, tenantId: () async => backend.tenantId);

  final FakeIamBackend backend;

  @override
  Future<TenantAuditLogPage> search({
    required DateTime from,
    required DateTime to,
    String? query,
    String? result,
    String? eventCategory,
    String? subjectType,
    List<String>? eventCodes,
    String? cursor,
    int limit = 20,
  }) {
    return backend.searchAudit(
      SearchTenantAuditLogsQuery(
        tenantId: backend.tenantId,
        fromUtc: from,
        toUtc: to,
        query: query,
        result: result,
        eventCategory: eventCategory,
        subjectType: subjectType,
        eventCodes: eventCodes,
        cursor: cursor,
        limit: limit,
      ),
    );
  }

  @override
  Future<TenantAuditLogDetail> getDetail(String auditLogId) {
    return backend.getAuditDetail(
      GetTenantAuditLogQuery(tenantId: backend.tenantId, auditLogId: auditLogId),
    );
  }
}
