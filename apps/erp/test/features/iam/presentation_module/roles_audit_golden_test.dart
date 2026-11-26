// Golden 10-8i: Vai trò (ID-19) và Lịch sử quản trị (ID-20) ở 390 và 1280.
// Ảnh: docs/refactor/plans/P10/img/10-8i/flutter-<ca>-<rộng>.png
import 'dart:async';

import 'package:c45_design_system/design_system.dart';
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
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import '../../receivable/presentation/receivable_test_harness.dart';

/// Giờ chuẩn của ảnh: 23/11/2026 10:00 (VN).
final _now = DateTime.utc(2026, 11, 23, 3);

SupabaseRpc _unusedRpc() => SupabaseRpc(
  SupabaseClient(
    'http://127.0.0.1',
    'anon',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  ),
);

final _roles = const [
  AssignableInvitationRole(roleId: 'store_owner', label: 'Chủ cửa hàng'),
  AssignableInvitationRole(roleId: 'staff', label: 'Nhân viên bán hàng'),
  AssignableInvitationRole(roleId: 'accountant', label: 'Kế toán'),
  AssignableInvitationRole(roleId: 'warehouse', label: 'Thủ kho'),
];

final _members = [
  TenantMember(
    membershipId: 'm1',
    userId: 'u1',
    displayName: 'Nguyễn Thị Lan',
    email: 'lan@anphat.vn',
    roleId: 'store_owner',
    roleLabel: 'Chủ cửa hàng',
    isOwner: true,
    status: 'active',
    joinedAt: DateTime.utc(2026, 9, 2, 2),
    version: 1,
  ),
  TenantMember(
    membershipId: 'm2',
    userId: 'u2',
    displayName: 'Trần Văn Minh',
    email: 'minh@anphat.vn',
    roleId: 'staff',
    roleLabel: 'Nhân viên bán hàng',
    isOwner: false,
    status: 'active',
    joinedAt: DateTime.utc(2026, 10, 15, 2),
    version: 1,
  ),
  TenantMember(
    membershipId: 'm3',
    userId: 'u3',
    displayName: 'Lê Thu Hà',
    email: 'ha@anphat.vn',
    roleId: 'accountant',
    roleLabel: 'Kế toán',
    isOwner: false,
    status: 'inactive',
    joinedAt: DateTime.utc(2026, 10, 20, 2),
    version: 2,
  ),
];

final _auditItems = [
  TenantAuditLogSummaryDto(
    auditLogId: 'a1',
    eventCode: 'iam.membership.role_changed',
    eventCategory: TenantAuditEventCategory.role,
    result: TenantAuditLogResult.success,
    occurredAt: DateTime.utc(2026, 11, 22, 3, 21),
    source: 'tenant_app',
    trackingId: 'req_7f3a9c21e0b4d6a8b1e5f3c8d19f02',
    actor: const TenantAuditActorDto(
      displayName: 'Nguyễn Thị Lan',
      roleLabel: 'Chủ cửa hàng',
      displayOrigin: TenantAuditDisplayOrigin.snapshot,
    ),
    subject: const TenantAuditSubjectDto(
      type: 'membership',
      id: '5f1c2a9e00001111222233337b3d',
      displayName: 'Trần Văn Minh',
      displayOrigin: TenantAuditDisplayOrigin.snapshot,
    ),
  ),
  TenantAuditLogSummaryDto(
    auditLogId: 'a2',
    eventCode: IamAuditEvents.invitationCreated,
    eventCategory: TenantAuditEventCategory.invitation,
    result: TenantAuditLogResult.success,
    occurredAt: DateTime.utc(2026, 11, 21, 8, 2),
    source: 'tenant_app',
    trackingId: 'req_2',
    actor: const TenantAuditActorDto(
      displayName: 'Nguyễn Thị Lan',
      roleLabel: 'Chủ cửa hàng',
      displayOrigin: TenantAuditDisplayOrigin.snapshot,
    ),
    subject: const TenantAuditSubjectDto(
      type: 'invitation',
      displayName: 'tuan@anphat.vn',
      displayOrigin: TenantAuditDisplayOrigin.snapshot,
    ),
  ),
  TenantAuditLogSummaryDto(
    auditLogId: 'a3',
    eventCode: IamAuditEvents.membershipDeactivated,
    eventCategory: TenantAuditEventCategory.member,
    result: TenantAuditLogResult.success,
    occurredAt: DateTime.utc(2026, 11, 18, 2, 12),
    source: 'tenant_app',
    trackingId: 'req_3',
    actor: const TenantAuditActorDto(
      displayName: 'Nguyễn Thị Lan',
      roleLabel: 'Chủ cửa hàng',
      displayOrigin: TenantAuditDisplayOrigin.snapshot,
    ),
    subject: const TenantAuditSubjectDto(
      type: 'membership',
      displayName: 'Lê Thu Hà',
      displayOrigin: TenantAuditDisplayOrigin.current,
    ),
  ),
];

final _blockedItem = TenantAuditLogSummaryDto(
  auditLogId: 'a7',
  eventCode: IamAuditEvents.membershipRemoved,
  eventCategory: TenantAuditEventCategory.member,
  result: TenantAuditLogResult.blocked,
  occurredAt: DateTime.utc(2026, 11, 20, 1, 15),
  source: 'tenant_app',
  trackingId: 'req_7',
  actor: const TenantAuditActorDto(
    displayName: 'Nguyễn Thị Lan',
    roleLabel: 'Chủ cửa hàng',
    displayOrigin: TenantAuditDisplayOrigin.snapshot,
  ),
  subject: const TenantAuditSubjectDto(
    type: 'membership',
    displayName: 'Trần Văn Minh',
    displayOrigin: TenantAuditDisplayOrigin.snapshot,
  ),
);

final _detailA1 = TenantAuditLogDetailDto(
  auditLogId: 'a1',
  auditDisplayId: 'AUD-0001',
  tenantId: 'org-001',
  eventCode: 'iam.membership.role_changed',
  eventCategory: TenantAuditEventCategory.role,
  result: TenantAuditLogResult.success,
  occurredAt: DateTime.utc(2026, 11, 22, 3, 21),
  source: 'tenant_app',
  correlationId: 'req_7f3a9c21e0b4d6a8b1e5f3c8d19f02',
  trackingId: 'req_7f3a9c21e0b4d6a8b1e5f3c8d19f02',
  actorUnavailable: false,
  beforeRedacted: false,
  afterRedacted: false,
  actor: const TenantAuditActorDto(
    displayName: 'Nguyễn Thị Lan',
    roleLabel: 'Chủ cửa hàng',
    displayOrigin: TenantAuditDisplayOrigin.snapshot,
  ),
  subject: const TenantAuditSubjectDto(
    type: 'membership',
    id: '5f1c2a9e00001111222233337b3d',
    displayName: 'Trần Văn Minh',
    displayOrigin: TenantAuditDisplayOrigin.snapshot,
  ),
  beforeState: const {'role': 'warehouse'},
  afterState: const {'role': 'staff'},
);

final _detailA6 = TenantAuditLogDetailDto(
  auditLogId: 'a6',
  tenantId: 'org-001',
  eventCode: IamAuditEvents.invitationRevoked,
  eventCategory: TenantAuditEventCategory.invitation,
  result: TenantAuditLogResult.success,
  occurredAt: DateTime.utc(2026, 10, 12, 9, 47),
  source: 'tenant_app',
  correlationId: 'req_7f3a9c21e0b4d6a8b1e5f3c8d19f02',
  trackingId: 'req_7f3a9c21e0b4d6a8b1e5f3c8d19f02',
  actorUnavailable: true,
  beforeRedacted: false,
  afterRedacted: false,
  actor: const TenantAuditActorDto(
    displayOrigin: TenantAuditDisplayOrigin.unavailable,
  ),
  subject: const TenantAuditSubjectDto(
    type: 'invitation',
    displayName: 'vy.old@gmail.com',
    displayOrigin: TenantAuditDisplayOrigin.snapshot,
  ),
);

final class _GoldenInvitations extends InvitationRepository {
  _GoldenInvitations({this.fail = false, this.pending})
    : super(rpc: _unusedRpc(), tenantId: () async => 'org-001');

  final bool fail;
  final Completer<void>? pending;

  @override
  Future<List<AssignableInvitationRole>> listAssignableRoles() async {
    if (pending != null) await pending!.future;
    if (fail) throw StateError('down');
    return _roles;
  }
}

final class _GoldenMembers extends MemberRepository {
  _GoldenMembers() : super(rpc: _unusedRpc(), tenantId: () async => 'org-001');

  @override
  Future<CursorPage<TenantMember>> listMembers({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async => CursorPage(items: _members);
}

final class _GoldenAudit extends AuditLogRepository {
  _GoldenAudit({
    this.pending,
    this.forbidden = false,
    this.empty = false,
    this.blocked = false,
    this.notFound = false,
    this.actorUnavailable = false,
  }) : super(rpc: _unusedRpc(), tenantId: () async => 'org-001');

  final Completer<void>? pending;
  final bool forbidden;
  final bool empty;
  final bool blocked;
  final bool notFound;
  final bool actorUnavailable;

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
  }) async {
    if (pending != null) await pending!.future;
    if (forbidden) {
      throw const AppException(IamBlockedCodes.permissionDenied);
    }
    if (empty) {
      return const TenantAuditLogPage(items: [], totalCount: 0);
    }
    final items = blocked ? [_blockedItem, ..._auditItems] : _auditItems;
    return TenantAuditLogPage(
      items: items,
      totalCount: 24,
      nextCursor: 'next-1',
    );
  }

  @override
  Future<TenantAuditLogDetailDto> getDetail(String auditLogId) async {
    if (notFound) {
      throw const AppException(IamBlockedCodes.resourceNotFound);
    }
    return actorUnavailable ? _detailA6 : _detailA1;
  }
}

Future<void> _capture(
  WidgetTester tester, {
  required int width,
  required String name,
  required Widget page,
  Future<void> Function()? act,
  bool settle = true,
}) async {
  final phone = width < 840;
  final size = Size(width.toDouble(), phone ? 844 : 800);
  final view = tester.view;
  view.physicalSize = size;
  view.devicePixelRatio = 1.0;
  if (phone) {
    view.padding = const FakeViewPadding(top: 30, bottom: 34);
    view.viewPadding = const FakeViewPadding(top: 30, bottom: 34);
  }
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);

  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VTheme.lightTheme,
      builder: (context, child) => RepaintBoundary(key: key, child: child),
      home: page,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }
  if (act != null) {
    await act();
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  await expectLater(
    find.byKey(key),
    matchesGoldenFile(
      '${repoRoot()}/docs/refactor/plans/P10/img/10-8i/flutter-$name-$width.png',
    ),
  );
}

void main() {
  setUpAll(() async {
    await loadInterFont();
  });

  for (final width in [390, 1280]) {
    // ── ID-19: Vai trò ──
    testWidgets('roles__list $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'roles__list',
        page: OrganizationRolesPage(
          invitations: _GoldenInvitations(),
          members: _GoldenMembers(),
        ),
      );
    });

    testWidgets('roles__loading $width', (tester) async {
      final pending = Completer<void>();
      await _capture(
        tester,
        width: width,
        name: 'roles__loading',
        settle: false,
        page: OrganizationRolesPage(
          invitations: _GoldenInvitations(pending: pending),
          members: _GoldenMembers(),
        ),
      );
    });

    testWidgets('roles__failed $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'roles__failed',
        page: OrganizationRolesPage(
          invitations: _GoldenInvitations(fail: true),
          members: _GoldenMembers(),
        ),
      );
    });

    testWidgets('roles__detail $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'roles__detail',
        page: OrganizationRoleDetailPage(
          code: 'staff',
          invitations: _GoldenInvitations(),
          members: _GoldenMembers(),
        ),
      );
    });

    testWidgets('roles__detail-empty $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'roles__detail-empty',
        page: OrganizationRoleDetailPage(
          code: 'warehouse',
          invitations: _GoldenInvitations(),
          members: _GoldenMembers(),
        ),
      );
    });

    // ── ID-20: Lịch sử quản trị ──
    testWidgets('audit__list $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'audit__list',
        page: OrganizationAuditLogsPage(
          auditLogs: _GoldenAudit(),
          clockLocal: () => _now,
        ),
      );
    });

    testWidgets('audit__loading $width', (tester) async {
      final pending = Completer<void>();
      await _capture(
        tester,
        width: width,
        name: 'audit__loading',
        settle: false,
        page: OrganizationAuditLogsPage(
          auditLogs: _GoldenAudit(pending: pending),
          clockLocal: () => _now,
        ),
      );
    });

    testWidgets('audit__no-results $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'audit__no-results',
        page: OrganizationAuditLogsPage(
          auditLogs: _GoldenAudit(empty: true),
          clockLocal: () => _now,
        ),
        act: () async {
          await tester.enterText(find.byType(VSearchBar), 'xoá dữ liệu');
          await tester.pump(const Duration(milliseconds: 400));
        },
      );
    });

    testWidgets('audit__forbidden $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'audit__forbidden',
        page: OrganizationAuditLogsPage(
          auditLogs: _GoldenAudit(forbidden: true),
          clockLocal: () => _now,
        ),
      );
    });

    testWidgets('audit__filter $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'audit__filter',
        page: OrganizationAuditLogsPage(
          auditLogs: _GoldenAudit(),
          clockLocal: () => _now,
        ),
        act: () => tester.tap(find.byTooltip('Bộ lọc')),
      );
    });

    testWidgets('audit__filter-applied $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'audit__filter-applied',
        page: OrganizationAuditLogsPage(
          auditLogs: _GoldenAudit(),
          clockLocal: () => _now,
        ),
        act: () async {
          await tester.tap(find.byTooltip('Bộ lọc'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('7 ngày'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(VButton, 'Áp dụng'));
        },
      );
    });

    testWidgets('audit__blocked $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'audit__blocked',
        page: OrganizationAuditLogsPage(
          auditLogs: _GoldenAudit(blocked: true),
          clockLocal: () => _now,
        ),
      );
    });

    // ── ID-20: Chi tiết hoạt động ──
    testWidgets('audit-detail__detail $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'audit-detail__detail',
        page: AuditLogDetailPage(
          auditLogId: 'a1',
          auditLogs: _GoldenAudit(),
        ),
      );
    });

    testWidgets('audit-detail__actor-unavailable $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'audit-detail__actor-unavailable',
        page: AuditLogDetailPage(
          auditLogId: 'a6',
          auditLogs: _GoldenAudit(actorUnavailable: true),
        ),
      );
    });

    testWidgets('audit-detail__not-found $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'audit-detail__not-found',
        page: AuditLogDetailPage(
          auditLogId: 'missing',
          auditLogs: _GoldenAudit(notFound: true),
        ),
      );
    });

    testWidgets('audit-detail__toast-copied $width', (tester) async {
      await _capture(
        tester,
        width: width,
        name: 'audit-detail__toast-copied',
        settle: false,
        page: AuditLogDetailPage(
          auditLogId: 'a1',
          auditLogs: _GoldenAudit(),
        ),
        act: () async {
          await tester.pumpAndSettle();
          final copyBtn = find.byTooltip('Sao chép mã theo dõi');
          await tester.ensureVisible(copyBtn);
          await tester.pumpAndSettle();
          await tester.tap(copyBtn);
        },
      );
    });
  }
}
