import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_state.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/audit_log_repository.dart';
import 'package:erp/features/iam/data/invitation_repository.dart';
import 'package:erp/features/iam/data/member_repository.dart';
import 'package:erp/features/iam/data/models/cursor_page.dart';
import 'package:erp/features/iam/data/models/tenant_audit_log.dart' as local;
import 'package:erp/features/iam/data/models/tenant_invitation.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import 'package:supabase/supabase.dart';
import 'package:vet45_iam_application/application.dart' as app;
import 'package:vet45_iam_infrastructure/infrastructure.dart';

import '../../../core/session/fake_session_repository.dart';

/// Bọc `IIamModule` (kịch bản fake còn lại) thành repository để test cubit
/// không dựng cubit bằng module. Hành vi kịch bản giữ nguyên.
SupabaseRpc get _unusedRpc => SupabaseRpc(
  SupabaseClient(
    'http://127.0.0.1',
    'anon',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  ),
);

SessionController testSessionController({
  String tenantId = 'org-001',
  String userId = 'u1',
  String role = 'staff',
  bool isOwner = false,
  List<String> permissions = const [],
  bool signedIn = true,
}) {
  final iam = IamSession();
  if (signedIn) {
    iam.apply(
      app.PrincipalAccessDto(
        userId: userId,
        tenantId: tenantId,
        role: role,
        isOwner: isOwner,
        permissions: permissions,
      ),
    );
  }
  return SessionController(
    repository: FakeSessionRepository(),
    iamSession: iam,
    initialState: SessionState(
      authStatus: signedIn ? AuthStatus.signedIn : AuthStatus.signedOut,
      userId: signedIn ? userId : null,
    ),
  );
}

final class IamModuleMemberRepository extends MemberRepository {
  IamModuleMemberRepository(this.module, {this.tenantId = 'org-001'})
    : super(rpc: _unusedRpc, tenantId: () async => tenantId);

  final app.IIamModule module;
  final String tenantId;

  @override
  Future<CursorPage<TenantMember>> listMembers({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    final page = await module.executeQueryAsync<app.CursorPageDto<app.TenantMemberDto>>(
      app.ListTenantMembersQuery(
        tenantId: tenantId,
        search: search,
        status: status,
        cursor: cursor,
        limit: limit,
      ),
    );
    return CursorPage(
      items: page.items.map(_member).toList(growable: false),
      nextCursor: page.nextCursor,
    );
  }

  @override
  Future<TenantMemberDetail> getMember(String membershipId) async {
    final detail = await module.executeQueryAsync<app.TenantMemberDetailDto>(
      app.GetTenantMemberQuery(tenantId: tenantId, membershipId: membershipId),
    );
    return _detail(detail);
  }

  @override
  Future<void> assignRole({required String userId, required String role}) {
    return module.executeCommandAsync<void>(
      app.AssignMemberRoleCommand(tenantId: tenantId, userId: userId, role: role),
    );
  }

  @override
  Future<TenantMemberDetail> deactivate(String membershipId, {required int expectedVersion}) async {
    final detail = await module.executeCommandAsync<app.TenantMemberDetailDto>(
      app.DeactivateMembershipCommand(
        tenantId: tenantId,
        membershipId: membershipId,
        expectedVersion: expectedVersion,
      ),
    );
    return _detail(detail);
  }

  @override
  Future<TenantMemberDetail> reactivate(String membershipId, {required int expectedVersion}) async {
    final detail = await module.executeCommandAsync<app.TenantMemberDetailDto>(
      app.ReactivateMembershipCommand(
        tenantId: tenantId,
        membershipId: membershipId,
        expectedVersion: expectedVersion,
      ),
    );
    return _detail(detail);
  }

  @override
  Future<TenantMemberDetail> remove(String membershipId, {required int expectedVersion}) async {
    final detail = await module.executeCommandAsync<app.TenantMemberDetailDto>(
      app.RemoveMembershipCommand(
        tenantId: tenantId,
        membershipId: membershipId,
        expectedVersion: expectedVersion,
      ),
    );
    return _detail(detail);
  }

  static TenantMember _member(app.TenantMemberDto dto) {
    return TenantMember(
      membershipId: dto.membershipId,
      userId: dto.userId,
      displayName: dto.displayName,
      email: dto.email,
      roleId: dto.roleId,
      roleLabel: dto.roleLabel,
      isOwner: dto.isOwner,
      status: dto.status,
      joinedAt: dto.joinedAt,
      version: dto.version,
    );
  }

  static TenantMemberDetail _detail(app.TenantMemberDetailDto dto) {
    return TenantMemberDetail(
      membershipId: dto.membershipId,
      tenantId: dto.tenantId,
      userId: dto.userId,
      displayName: dto.displayName,
      email: dto.email,
      role: dto.role,
      roleLabel: dto.roleLabel,
      isOwner: dto.isOwner,
      isSoleOwner: dto.isSoleOwner,
      status: dto.status,
      version: dto.version,
      joinedAt: dto.joinedAt,
      lastActivityAt: dto.lastActivityAt,
      statusChangedAt: dto.statusChangedAt,
      removedAt: dto.removedAt,
    );
  }
}

final class IamModuleInvitationRepository extends InvitationRepository {
  IamModuleInvitationRepository(this.module, {this.tenantId = 'org-001'})
    : super(rpc: _unusedRpc, tenantId: () async => tenantId);

  final app.IIamModule module;
  final String tenantId;

  @override
  Future<CursorPage<TenantInvitation>> listInvitations({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    final page = await module.executeQueryAsync<app.CursorPageDto<app.InvitationSummaryDto>>(
      app.ListInvitationsQuery(
        tenantId: tenantId,
        search: search,
        status: status,
        cursor: cursor,
        limit: limit,
      ),
    );
    return CursorPage(
      items: page.items.map(_summary).toList(growable: false),
      nextCursor: page.nextCursor,
    );
  }

  @override
  Future<TenantInvitationDetail> getInvitation(String invitationId) async {
    final detail = await module.executeQueryAsync<app.InvitationDetailDto>(
      app.GetInvitationQuery(tenantId: tenantId, invitationId: invitationId),
    );
    return _detail(detail);
  }

  @override
  Future<TenantInvitationDetail> create({
    required String email,
    required String roleCode,
    required String idempotencyKey,
  }) async {
    final detail = await module.executeCommandAsync<app.InvitationDetailDto>(
      app.CreateInvitationCommand(
        tenantId: tenantId,
        inviteeEmail: email,
        initialRoleId: roleCode,
        idempotencyKey: idempotencyKey,
      ),
    );
    return _detail(detail);
  }

  @override
  Future<TenantInvitationDetail> resend(
    String invitationId, {
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    final detail = await module.executeCommandAsync<app.InvitationDetailDto>(
      app.ResendInvitationCommand(
        tenantId: tenantId,
        invitationId: invitationId,
        expectedVersion: expectedVersion,
        idempotencyKey: idempotencyKey,
      ),
    );
    return _detail(detail);
  }

  @override
  Future<TenantInvitationDetail> revoke(
    String invitationId, {
    required int expectedVersion,
    required String reason,
    required String idempotencyKey,
  }) async {
    final detail = await module.executeCommandAsync<app.InvitationDetailDto>(
      app.RevokeInvitationCommand(
        tenantId: tenantId,
        invitationId: invitationId,
        expectedVersion: expectedVersion,
        reason: reason,
        idempotencyKey: idempotencyKey,
      ),
    );
    return _detail(detail);
  }

  @override
  Future<List<AssignableInvitationRole>> listAssignableRoles() async {
    final rows = await module.executeQueryAsync<List<app.AssignableRoleOptionDto>>(
      app.ListAssignableInvitationRolesQuery(tenantId: tenantId),
    );
    return rows
        .map((row) => AssignableInvitationRole(roleId: row.roleId, label: row.label))
        .where((row) => row.roleId.isNotEmpty && row.label.isNotEmpty)
        .toList(growable: false);
  }

  static TenantInvitation _summary(app.InvitationSummaryDto dto) {
    return TenantInvitation(
      invitationId: dto.invitationId,
      inviteeEmail: dto.inviteeEmail,
      initialRoleId: dto.initialRoleId,
      initialRoleLabel: dto.initialRoleLabel,
      status: dto.status,
      expiresAt: dto.expiresAt,
      deliveryStatus: dto.deliveryStatus,
      deliveryCorrelationId: dto.deliveryCorrelationId,
      version: dto.version,
    );
  }

  static TenantInvitationDetail _detail(app.InvitationDetailDto dto) {
    return TenantInvitationDetail(
      invitationId: dto.invitationId,
      inviteeEmail: dto.inviteeEmail,
      initialRoleId: dto.initialRoleId,
      initialRoleLabel: dto.initialRoleLabel,
      status: dto.status,
      expiresAt: dto.expiresAt,
      deliveryStatus: dto.deliveryStatus,
      deliveryCorrelationId: dto.deliveryCorrelationId,
      version: dto.version,
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      lastSentAt: dto.lastSentAt,
      revokedAt: dto.revokedAt,
      declinedAt: dto.declinedAt,
    );
  }
}

final class IamModuleAuditLogRepository extends AuditLogRepository {
  IamModuleAuditLogRepository(this.module, {this.tenantId = 'org-001'})
    : super(rpc: _unusedRpc, tenantId: () async => tenantId);

  final app.IIamModule module;
  final String tenantId;

  @override
  Future<local.TenantAuditLogPage> search({
    required DateTime from,
    required DateTime to,
    String? query,
    String? result,
    String? eventCategory,
    String? subjectType,
    List<String>? eventCodes,
    String? cursor,
    int limit = 20,
  }) async {
    final page = await module.executeQueryAsync<app.TenantAuditLogSearchPageDto>(
      app.SearchTenantAuditLogsQuery(
        tenantId: tenantId,
        fromUtc: from,
        toUtc: to,
        query: query,
        result: result,
        eventCategory: _category(eventCategory),
        subjectType: subjectType,
        eventCodes: eventCodes,
        cursor: cursor,
        limit: limit,
      ),
    );
    return local.TenantAuditLogPage(
      items: page.items.map(_item).toList(growable: false),
      totalCount: page.totalCount,
      nextCursor: page.nextCursor,
    );
  }

  @override
  Future<local.TenantAuditLogDetail> getDetail(String auditLogId) async {
    final detail = await module.executeQueryAsync<app.TenantAuditLogDetailDto>(
      app.GetTenantAuditLogQuery(tenantId: tenantId, auditLogId: auditLogId),
    );
    return _detail(detail);
  }

  static app.TenantAuditEventCategory? _category(String? code) {
    if (code == null) return null;
    for (final category in app.TenantAuditEventCategory.values) {
      if (category.code == code) return category;
    }
    return null;
  }

  static local.TenantAuditEventCategory? _localCategory(app.TenantAuditEventCategory? category) {
    return local.TenantAuditEventCategory.fromCode(category?.code);
  }

  static local.TenantAuditLogResult _result(app.TenantAuditLogResult result) {
    return local.TenantAuditLogResultCodes.fromCode(result.code) ?? local.TenantAuditLogResult.success;
  }

  static local.TenantAuditDisplayOrigin? _origin(app.TenantAuditDisplayOrigin? origin) {
    return local.TenantAuditDisplayOrigin.fromCode(origin?.code);
  }

  static local.TenantAuditActor _actor(app.TenantAuditActorDto dto) {
    return local.TenantAuditActor(
      userId: dto.userId,
      displayName: dto.displayName,
      actorType: dto.actorType,
      roleCode: dto.roleCode,
      roleLabel: dto.roleLabel,
      displayOrigin: _origin(dto.displayOrigin),
    );
  }

  static local.TenantAuditSubject _subject(app.TenantAuditSubjectDto dto) {
    return local.TenantAuditSubject(
      type: dto.type,
      id: dto.id,
      displayName: dto.displayName,
      code: dto.code,
      secondaryLabel: dto.secondaryLabel,
      displayOrigin: _origin(dto.displayOrigin),
    );
  }

  static local.TenantAuditLogItem _item(app.TenantAuditLogSummaryDto dto) {
    return local.TenantAuditLogItem(
      auditLogId: dto.auditLogId,
      eventCode: dto.eventCode,
      eventCategory: _localCategory(dto.eventCategory),
      result: _result(dto.result),
      occurredAt: dto.occurredAt,
      source: dto.source,
      trackingId: dto.trackingId,
      actor: _actor(dto.actor),
      subject: _subject(dto.subject),
    );
  }

  static local.TenantAuditLogDetail _detail(app.TenantAuditLogDetailDto dto) {
    return local.TenantAuditLogDetail(
      auditLogId: dto.auditLogId,
      auditDisplayId: dto.auditDisplayId,
      tenantId: dto.tenantId,
      activityCode: dto.activityCode,
      eventCode: dto.eventCode,
      eventCategory: _localCategory(dto.eventCategory),
      titleSnapshot: dto.titleSnapshot,
      result: _result(dto.result),
      occurredAt: dto.occurredAt,
      source: dto.source,
      correlationId: dto.correlationId,
      trackingId: dto.trackingId,
      actorUnavailable: dto.actorUnavailable,
      beforeRedacted: dto.beforeRedacted,
      afterRedacted: dto.afterRedacted,
      actor: _actor(dto.actor),
      subject: _subject(dto.subject),
      beforeState: dto.beforeState,
      afterState: dto.afterState,
    );
  }
}

SessionController sessionFromDto(app.SessionDto dto) {
  return testSessionController(
    signedIn: dto.isAuthenticated,
    userId: (dto.userId == null || dto.userId!.isEmpty) ? 'u1' : dto.userId!,
    tenantId: dto.tenantId ?? '',
    role: (dto.role == null || dto.role!.isEmpty) ? 'staff' : dto.role!,
    isOwner: dto.isOwner,
    permissions: dto.permissions,
  );
}

