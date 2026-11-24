import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/invitation_repository.dart';
import 'package:erp/features/iam/data/member_repository.dart';
import 'package:erp/features/iam/data/models/cursor_page.dart';
import 'package:erp/features/iam/data/models/tenant_invitation.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

void main() {
  testWidgets('OrganizationRolesPage renders system roles without permission counts', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = await _loadedCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(home: OrganizationRolesPage(cubit: cubit)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vai trò'), findsOneWidget);
    expect(find.text('4 vai trò hệ thống'), findsOneWidget);
    expect(find.text('Vai trò hệ thống'), findsOneWidget);
    expect(
      find.text('Vai trò vận hành không thay đổi tư cách Chủ sở hữu.'),
      findsOneWidget,
    );
    expect(find.text('Chủ cửa hàng'), findsOneWidget);
    expect(find.textContaining('quyền'), findsNothing);
    expect(find.text('Đang dùng'), findsOneWidget);
    expect(find.text('Nhân viên bán hàng'), findsOneWidget);
    expect(find.text('Bán hàng và chăm sóc khách hàng'), findsOneWidget);
    expect(find.text('Kế toán'), findsOneWidget);
    expect(find.text('Thủ kho'), findsOneWidget);
    expect(find.text('Nhập xuất, tồn kho và kiểm kê'), findsOneWidget);
  });

  testWidgets('OrganizationRolesPage opens the role detail', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = await _loadedCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(home: OrganizationRolesPage(cubit: cubit)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nhân viên bán hàng'));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết vai trò'), findsOneWidget);
    expect(find.text('Bán hàng và chăm sóc khách hàng'), findsWidgets);
    expect(find.text('Chưa có thành viên đang giữ vai trò này.'), findsOneWidget);
    expect(find.textContaining('quyền'), findsNothing);
  });

  testWidgets('OrganizationRolesPage retries after a load failure', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final invitations = _ScriptedInvitations(failFirst: true);
    final cubit = RolesCubit(
      invitations: invitations,
      members: _ScriptedMembers(const []),
    );
    addTearDown(cubit.close);
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(home: OrganizationRolesPage(cubit: cubit)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tải được'), findsOneWidget);
    expect(find.text('Không thể tải danh sách vai trò'), findsOneWidget);
    expect(
      find.text(
        'Dịch vụ phân quyền đang tạm thời không khả dụng. Vui lòng thử lại sau.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('4 vai trò hệ thống'), findsOneWidget);
  });

  testWidgets('accessibility guidelines: tap target size and labeled tap target', (
    WidgetTester tester,
  ) async {
    final handle = tester.ensureSemantics();

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = await _loadedCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(home: OrganizationRolesPage(cubit: cubit)),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });
}


Future<RolesCubit> _loadedCubit() async {
  final cubit = RolesCubit(
    invitations: _ScriptedInvitations(),
    members: _ScriptedMembers([
      CursorPage(
        items: [
          TenantMember(
            membershipId: 'm1',
            userId: 'u1',
            displayName: 'An',
            email: 'an@example.com',
            roleId: 'role-owner',
            roleLabel: 'Chủ cửa hàng',
            isOwner: true,
            status: 'active',
            joinedAt: DateTime.utc(2026, 1, 1),
            version: 1,
          ),
        ],
      ),
    ]),
  );
  await cubit.load();
  return cubit;
}

const _roles = [
  AssignableInvitationRole(roleId: 'role-owner', label: 'Chủ cửa hàng'),
  AssignableInvitationRole(roleId: 'role-staff', label: 'Nhân viên bán hàng'),
  AssignableInvitationRole(roleId: 'role-accountant', label: 'Kế toán'),
  AssignableInvitationRole(roleId: 'role-warehouse', label: 'Thủ kho'),
];

SupabaseRpc get _rpc => SupabaseRpc(
  SupabaseClient(
    'http://127.0.0.1',
    'anon',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  ),
);

final class _ScriptedInvitations extends InvitationRepository {
  _ScriptedInvitations({this.failFirst = false})
    : super(rpc: _rpc, tenantId: () async => 'org-001');

  final bool failFirst;
  var _calls = 0;

  @override
  Future<List<AssignableInvitationRole>> listAssignableRoles() async {
    _calls += 1;
    if (failFirst && _calls == 1) throw StateError('down');
    return _roles;
  }
}

final class _ScriptedMembers extends MemberRepository {
  _ScriptedMembers(this.pages) : super(rpc: _rpc, tenantId: () async => 'org-001');

  final List<CursorPage<TenantMember>> pages;

  @override
  Future<CursorPage<TenantMember>> listMembers({
    String? search,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    return pages.isEmpty ? const CursorPage(items: []) : pages.first;
  }
}
