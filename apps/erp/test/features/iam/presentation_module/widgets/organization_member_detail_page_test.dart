import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/member_repository.dart';
import 'package:erp/features/iam/data/models/tenant_member.dart';
import 'package:supabase/supabase.dart';
import '../../support/fake_iam_backend.dart';
import 'package:erp/features/iam/presentation.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    required FakeIamScenario scenario,
    String membershipId = 'mem-staff-1',
    OrganizationMemberDetailCubit? cubit,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationMemberDetailPage(
          membershipId: membershipId,
          members: FakeMemberRepository(FakeIamBackend(scenario: scenario)),
          cubit: cubit,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('wgt_e03_u05_fr01_01: loads member by id and shows lifecycle actions including role change',
      (tester) async {
    await pumpPage(
      tester,
      scenario: FakeIamScenario.memberDeactivateOk,
    );

    expect(find.text('Chi tiết thành viên'), findsOneWidget);
    expect(find.text('Hoa Tran'), findsWidgets);
    expect(find.text('Thao tác'), findsOneWidget);

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    expect(find.text('Thao tác thành viên'), findsOneWidget);
    expect(find.text('Thay đổi vai trò'), findsOneWidget);
    expect(find.text('Tạm ngừng thành viên'), findsOneWidget);
    expect(find.text('Loại khỏi tổ chức'), findsOneWidget);
  });

  testWidgets('tapping Thay đổi vai trò opens select role page', (tester) async {
    await pumpPage(
      tester,
      scenario: FakeIamScenario.memberDeactivateOk,
    );

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thay đổi vai trò'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn vai trò mới'), findsOneWidget);
  });

  testWidgets('removed member is read-only without action buttons', (tester) async {
    await pumpPage(
      tester,
      scenario: FakeIamScenario.memberDetailOk,
      membershipId: 'mem-removed-1',
    );

    expect(find.text('Đã loại'), findsOneWidget);
    expect(find.text('Thao tác'), findsNothing);
    expect(find.text('Tạm ngừng thành viên'), findsNothing);
    expect(find.text('Kích hoạt lại'), findsNothing);
    expect(find.text('Loại khỏi tổ chức'), findsNothing);
  });

  testWidgets('wgt_e03_u06_fr01_01: sole owner has no destructive CTAs', (tester) async {
    await pumpPage(
      tester,
      scenario: FakeIamScenario.memberDetailOk,
      membershipId: 'mem-owner-1',
    );

    expect(find.text('Thao tác'), findsNothing);
  });

  testWidgets('deactivate confirmation mutates to inactive', (tester) async {
    final module = FakeIamBackend(scenario: FakeIamScenario.memberDeactivateOk);
    final cubit = OrganizationMemberDetailCubit(
      membershipId: 'mem-staff-1',
      members: FakeMemberRepository(module),
    );
    await cubit.load();

    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationMemberDetailPage(
          membershipId: 'mem-staff-1',
          cubit: cubit,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạm ngừng thành viên'));
    await tester.pumpAndSettle();
    expect(find.text('Tạm ngừng thành viên?'), findsOneWidget);

    await tester.tap(find.widgetWithText(VButton, 'Tạm ngừng'));
    await tester.pumpAndSettle();

    expect(module.commandsOf<DeactivateMembershipCommand>(), hasLength(1));
    expect(cubit.state.member?.status, MembershipStatus.inactive);
    expect(find.text('Quyền truy cập đã tạm ngừng'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('Xác nhận thay đổi changes the role, closes both, shows one toast', (tester) async {
    final module = FakeIamBackend(scenario: FakeIamScenario.memberDeactivateOk);
    final cubit = OrganizationMemberDetailCubit(
      membershipId: 'mem-staff-1',
      members: FakeMemberRepository(module),
    );
    await cubit.load();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationMemberDetailPage(
          membershipId: 'mem-staff-1',
          cubit: cubit,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thay đổi vai trò'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn vai trò mới'), findsOneWidget);

    await tester.tap(find.text('Kế toán'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
    await tester.pumpAndSettle();

    expect(find.text('Xác nhận thay đổi'), findsOneWidget);
    await tester.tap(find.widgetWithText(VButton, 'Xác nhận thay đổi'));
    await tester.pumpAndSettle();

    expect(module.commandsOf<AssignMemberRoleCommand>(), hasLength(1));
    expect(module.commandsOf<AssignMemberRoleCommand>().first.role, 'accountant');
    expect(find.text('Chi tiết thành viên'), findsOneWidget);
    expect(find.text('Đã thay đổi vai trò thành công.'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('a failed change keeps the sheet open and shows the toast', (tester) async {
    final module = FakeIamBackend(scenario: FakeIamScenario.memberDetailOk);
    final cubit = OrganizationMemberDetailCubit(
      membershipId: 'mem-staff-1',
      members: _AssignRoleBlockedRepository(module),
    );
    await cubit.load();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationMemberDetailPage(
          membershipId: 'mem-staff-1',
          cubit: cubit,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thao tác'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thay đổi vai trò'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kế toán'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Tiếp tục'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(VButton, 'Xác nhận thay đổi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(VToast), findsOneWidget);

    // Chờ hết hiệu ứng: sheet và trang chọn vai trò vẫn còn.
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận thay đổi'), findsOneWidget);
    expect(find.text('Chọn vai trò'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('1280: suspended sole owner only shows Kích hoạt lại', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationMemberDetailPage(
          membershipId: 'mem-owner-1',
          members: _SuspendedSoleOwnerRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(VButton, 'Kích hoạt lại'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Thay đổi vai trò'), findsNothing);
    expect(find.widgetWithText(VButton, 'Loại khỏi tổ chức'), findsNothing);
  });

  testWidgets('accessibility guidelines: tap target size and labeled tap target', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpPage(
      tester,
      scenario: FakeIamScenario.memberDeactivateOk,
    );

    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });

  testWidgets('1280: member actions follow status and sole owner', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Active member: 3 buttons, no Thao tác
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationMemberDetailPage(
          membershipId: 'mem-staff-1',
          members: FakeMemberRepository(
            FakeIamBackend(scenario: FakeIamScenario.memberDeactivateOk),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Thao tác'), findsNothing);
    expect(find.widgetWithText(VButton, 'Thay đổi vai trò'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Tạm ngừng thành viên'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Loại khỏi tổ chức'), findsOneWidget);

    // Suspended member: Kích hoạt lại
    final suspendedModule = FakeIamBackend(scenario: FakeIamScenario.memberDeactivateOk);
    final suspendedRepo = FakeMemberRepository(suspendedModule);
    await suspendedRepo.deactivate('mem-staff-1', expectedVersion: 1);
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationMemberDetailPage(
          key: const ValueKey('suspended'),
          membershipId: 'mem-staff-1',
          members: suspendedRepo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(VButton, 'Kích hoạt lại'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Tạm ngừng thành viên'), findsNothing);

    // Sole owner: no action buttons
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationMemberDetailPage(
          membershipId: 'mem-owner-1',
          members: FakeMemberRepository(
            FakeIamBackend(scenario: FakeIamScenario.memberDetailOk),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(VButton, 'Thay đổi vai trò'), findsNothing);
    expect(find.widgetWithText(VButton, 'Loại khỏi tổ chức'), findsNothing);

    // Removed member: no action buttons
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationMemberDetailPage(
          membershipId: 'mem-removed-1',
          members: FakeMemberRepository(
            FakeIamBackend(scenario: FakeIamScenario.memberDetailOk),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(VButton, 'Thay đổi vai trò'), findsNothing);
    expect(find.widgetWithText(VButton, 'Loại khỏi tổ chức'), findsNothing);
  });

  testWidgets('1280: running action spins and disables the others', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.memberDeactivateOk);
    final gate = Completer<TenantMemberDetail>();
    final repo = _SlowDeactivateMemberRepository(module, gate);
    final cubit = OrganizationMemberDetailCubit(
      membershipId: 'mem-staff-1',
      members: repo,
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationMemberDetailPage(
          membershipId: 'mem-staff-1',
          cubit: cubit,
        ),
      ),
    );
    await tester.pumpAndSettle();

    unawaited(cubit.deactivate());
    await tester.pump();
    await tester.pump();

    final changeRoleBtn = tester.widget<VButton>(
      find.widgetWithText(VButton, 'Thay đổi vai trò'),
    );
    final deactivateBtn = tester.widget<VButton>(
      find.widgetWithText(VButton, 'Tạm ngừng thành viên'),
    );
    expect(changeRoleBtn.onPressed, isNull);
    expect(deactivateBtn.isLoading, isTrue);

    gate.complete(await module.getMember(const GetTenantMemberQuery(
      tenantId: 'org-001',
      membershipId: 'mem-staff-1',
    )));
    await tester.pumpAndSettle();
    await cubit.close();
  });

  testWidgets('390 and 1280: ownership row, no Chỉ đọc', (tester) async {
    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationMemberDetailPage(
            membershipId: 'mem-staff-1',
            members: FakeMemberRepository(
              FakeIamBackend(scenario: FakeIamScenario.memberDetailOk),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quyền sở hữu'), findsOneWidget);
      expect(find.text('Thành viên'), findsOneWidget);
      expect(find.text('Chỉ đọc'), findsNothing);
    }
  });

  testWidgets('detail always has back; deep link back goes to the list', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
    final membersRepo = FakeMemberRepository(module);
    final invitationsRepo = FakeInvitationRepository(module);

    final router = GoRouter(
      initialLocation: '/more/users/members/mem-staff-1',
      routes: [
        GoRoute(
          path: '/more/users',
          builder: (_, _) => OrganizationUsersPage(
            members: membersRepo,
            invitations: invitationsRepo,
          ),
          routes: [
            GoRoute(
              path: 'members/:id',
              builder: (_, state) => OrganizationMemberDetailPage(
                membershipId: state.pathParameters['id']!,
                members: membersRepo,
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: VTheme.lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Quay lại'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.text('Người dùng'), findsOneWidget);
  });

  testWidgets('resizing 1280 → 700 in detail then back works', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
    final membersRepo = FakeMemberRepository(module);
    final invitationsRepo = FakeInvitationRepository(module);

    final router = GoRouter(
      initialLocation: '/more/users/members/mem-staff-1',
      routes: [
        GoRoute(
          path: '/more/users',
          builder: (_, _) => OrganizationUsersPage(
            members: membersRepo,
            invitations: invitationsRepo,
          ),
          routes: [
            GoRoute(
              path: 'members/:id',
              builder: (_, state) => OrganizationMemberDetailPage(
                membershipId: state.pathParameters['id']!,
                members: membersRepo,
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: VTheme.lightTheme,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(700, 800);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.text('Người dùng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 at text scale 2.0 does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 844),
          textScaler: TextScaler.linear(2.0),
        ),
        child: MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationMemberDetailPage(
            membershipId: 'mem-staff-1',
            members: FakeMemberRepository(
              FakeIamBackend(scenario: FakeIamScenario.memberDetailOk),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

final class _SlowDeactivateMemberRepository extends MemberRepository {
  _SlowDeactivateMemberRepository(FakeIamBackend backend, this._gate)
    : _delegate = FakeMemberRepository(backend),
      super(
        rpc: SupabaseRpc(
          SupabaseClient(
            'http://127.0.0.1',
            'anon',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        ),
        tenantId: () async => 'org-001',
      );

  final FakeMemberRepository _delegate;
  final Completer<TenantMemberDetail> _gate;

  @override
  Future<TenantMemberDetail> getMember(String membershipId) =>
      _delegate.getMember(membershipId);

  @override
  Future<TenantMemberDetail> deactivate(
    String membershipId, {
    required int expectedVersion,
  }) {
    return _gate.future;
  }
}

/// Chủ duy nhất đang tạm ngừng: chỉ được kích hoạt lại.
final class _SuspendedSoleOwnerRepository extends MemberRepository {
  _SuspendedSoleOwnerRepository()
    : super(
        rpc: SupabaseRpc(
          SupabaseClient(
            'http://127.0.0.1',
            'anon',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        ),
        tenantId: () async => 'org-001',
      );

  @override
  Future<TenantMemberDetail> getMember(String membershipId) async {
    return TenantMemberDetail(
      membershipId: membershipId,
      tenantId: 'org-001',
      userId: 'lan-le',
      displayName: 'Lan Le',
      email: 'lan@gmail.com',
      role: 'owner',
      roleLabel: 'Chủ cửa hàng',
      isOwner: true,
      isSoleOwner: true,
      status: MembershipStatus.inactive,
      version: 2,
      joinedAt: DateTime(2026, 1, 1),
      statusChangedAt: DateTime(2026, 7, 1),
    );
  }
}

/// Gán vai trò bị chặn (LAST_OWNER_PROTECTED); đọc chi tiết như thường.
final class _AssignRoleBlockedRepository extends MemberRepository {
  _AssignRoleBlockedRepository(FakeIamBackend backend)
    : _delegate = FakeMemberRepository(backend),
      super(
        rpc: SupabaseRpc(
          SupabaseClient(
            'http://127.0.0.1',
            'anon',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        ),
        tenantId: () async => 'org-001',
      );

  final FakeMemberRepository _delegate;

  @override
  Future<TenantMemberDetail> getMember(String membershipId) =>
      _delegate.getMember(membershipId);

  @override
  Future<void> assignRole({required String userId, required String role}) async {
    throw const AppException(IamBlockedCodes.lastOwnerProtected);
  }
}
