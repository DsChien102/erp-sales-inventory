import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/invitation_repository.dart';
import 'package:erp/features/iam/data/member_repository.dart';
import 'package:erp/features/iam/data/models/cursor_page.dart';
import 'package:erp/features/iam/data/models/tenant_invitation.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:supabase/supabase.dart';
import '../../support/iam_fixtures.dart';

void main() {
  testWidgets('OrganizationRoleDetailPage renders role summary and permission groups (TA-D-02)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sampleRole = FakeRolesData.sampleRoles[1]; // Nhân viên bán hàng

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationRoleDetailPage(role: sampleRole),
      ),
    );
    await tester.pumpAndSettle();

    // Summary Card
    expect(find.text('Chi tiết vai trò'), findsOneWidget);
    expect(find.text('Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Bán hàng và chăm sóc khách hàng'), findsOneWidget);
    expect(find.text('Vai trò hệ thống · Chỉ đọc'), findsOneWidget);
    expect(find.textContaining('quyền'), findsNothing);
    expect(find.text('Chưa có thành viên đang giữ vai trò này.'), findsOneWidget);
  });

  testWidgets('deep link loads the role', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationRoleDetailPage(
          code: 'staff',
          invitations: _FakeInvitations(),
          members: _FakeMembers(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết vai trò'), findsOneWidget);
    expect(find.text('Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Bình'), findsOneWidget);
  });

  testWidgets('unknown code shows Không tìm thấy vai trò', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationRoleDetailPage(
          code: 'unknown-code',
          invitations: _FakeInvitations(),
          members: _FakeMembers(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy vai trò'), findsOneWidget);
  });

  testWidgets('detail load error can be retried', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final invitations = _FailOnceInvitations();
    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationRoleDetailPage(
          code: 'staff',
          invitations: invitations,
          members: _FakeMembers(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không thể tải danh sách vai trò'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Bình'), findsOneWidget);
  });
}

SupabaseRpc get _rpc => SupabaseRpc(
  SupabaseClient(
    'http://127.0.0.1',
    'anon',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  ),
);

final class _FakeInvitations extends InvitationRepository {
  _FakeInvitations() : super(rpc: _rpc, tenantId: () async => 'org-001');

  @override
  Future<List<AssignableInvitationRole>> listAssignableRoles() async => const [
    AssignableInvitationRole(roleId: 'role-owner', label: 'Chủ cửa hàng'),
    AssignableInvitationRole(roleId: 'role-staff', label: 'Nhân viên bán hàng'),
  ];
}

final class _FailOnceInvitations extends InvitationRepository {
  _FailOnceInvitations() : super(rpc: _rpc, tenantId: () async => 'org-001');
  var _calls = 0;

  @override
  Future<List<AssignableInvitationRole>> listAssignableRoles() async {
    _calls += 1;
    if (_calls == 1) throw StateError('down');
    return const [
      AssignableInvitationRole(roleId: 'role-owner', label: 'Chủ cửa hàng'),
      AssignableInvitationRole(roleId: 'role-staff', label: 'Nhân viên bán hàng'),
    ];
  }
}

final class _FakeMembers extends MemberRepository {
  _FakeMembers() : super(rpc: _rpc, tenantId: () async => 'org-001');

  @override
  Future<CursorPage<TenantMember>> listMembers({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    return CursorPage(
      items: [
        TenantMember(
          membershipId: 'm2',
          userId: 'u2',
          displayName: 'Bình',
          email: 'binh@example.com',
          roleId: 'role-staff',
          roleLabel: 'Nhân viên bán hàng',
          isOwner: false,
          status: 'active',
          joinedAt: DateTime.utc(2026, 1, 1),
          version: 1,
        ),
      ],
    );
  }
}
