import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/iam/data/invitation_repository.dart';
import 'package:erp/features/iam/data/models/tenant_invitation.dart';
import 'package:supabase/supabase.dart';
import '../../support/fake_iam_backend.dart';
import '../../support/iam_test_session.dart';
import 'package:erp/features/iam/presentation.dart';
import '../../support/iam_fixtures.dart';

final class _FakeRoles implements InvitationRoleOptionsSource {
  @override
  Future<List<InvitationRoleOption>> load(String tenantId) async {
    return const [
      InvitationRoleOption(roleId: 'role-staff', label: 'Nhân viên bán hàng'),
      InvitationRoleOption(roleId: 'role-accountant', label: 'Kế toán'),
      InvitationRoleOption(roleId: 'role-warehouse', label: 'Thủ kho'),
      InvitationRoleOption(roleId: 'role-owner', label: 'Chủ cửa hàng'),
    ];
  }
}

void main() {
  testWidgets('wgt_e03_u02_fr01_01: invite form loads roles and submits without FakeRolesData', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.inviteOk);
    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(module),
      roleOptionsSource: _FakeRoles(),
      keyFactory: FakeIdempotencyKeyFactory(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationInviteMemberPage(cubit: cubit),
      ),
    );
    await cubit.loadRoleOptions();
    await tester.pumpAndSettle();

    expect(find.text('Mời thành viên'), findsWidgets);
    expect(find.text('Nhân viên bán hàng'), findsWidgets);
    expect(find.text('FakeRolesData'), findsNothing);

    await tester.enterText(find.byType(TextField), 'staff@example.com');
    await tester.tap(find.text('Nhân viên bán hàng').first); // không còn chọn sẵn vai trò
    await tester.pump();
    await tester.tap(find.text('Gửi lời mời'));
    await tester.pumpAndSettle();

    expect(module.commandsOf<CreateInvitationCommand>(), hasLength(1));
    expect(
      module.commandsOf<CreateInvitationCommand>().single.initialRoleId,
      'role-staff',
    );
    expect(find.text('Đã gửi lời mời thành công.'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('empty email submits and shows inline validation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(FakeIamBackend(scenario: FakeIamScenario.inviteOk)),
      roleOptionsSource: _FakeRoles(),
      keyFactory: FakeIdempotencyKeyFactory(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationInviteMemberPage(cubit: cubit),
      ),
    );
    await cubit.loadRoleOptions();
    await tester.pumpAndSettle();

    final send = tester.widget<VButton>(
      find.widgetWithText(VButton, 'Gửi lời mời'),
    );
    expect(send.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(VButton, 'Gửi lời mời'));
    await tester.pump();
    expect(find.text('Vui lòng nhập email và chọn vai trò.'), findsNWidgets(2));

    await cubit.close();
  });

  testWidgets('invalid email shows inline error under email field without toast', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(FakeIamBackend(scenario: FakeIamScenario.inviteOk)),
      roleOptionsSource: _FakeRoles(),
      keyFactory: FakeIdempotencyKeyFactory(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationInviteMemberPage(cubit: cubit),
      ),
    );
    await cubit.loadRoleOptions();
    await tester.pumpAndSettle();

    // Verify helper text exists
    expect(
      find.textContaining('Người nhận phải đăng nhập đúng email.'),
      findsOneWidget,
    );

    // Enter invalid email 'abc'
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    await tester.tap(find.widgetWithText(VButton, 'Gửi lời mời'));
    await tester.pumpAndSettle();

    expect(find.text('Email không hợp lệ'), findsOneWidget);
    expect(find.byType(VToast), findsNothing);

    await cubit.close();
  });

  testWidgets('backend DUPLICATE_MEMBERSHIP shows inline error without toast', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(FakeIamBackend(
        scenario: FakeIamScenario.inviteDuplicateMembership,
      )),
      roleOptionsSource: _FakeRoles(),
      keyFactory: FakeIdempotencyKeyFactory(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationInviteMemberPage(cubit: cubit),
      ),
    );
    await cubit.loadRoleOptions();
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'existing@example.com');
    await tester.tap(find.text('Nhân viên bán hàng').first); // không còn chọn sẵn vai trò
    await tester.pump();
    await tester.tap(find.widgetWithText(VButton, 'Gửi lời mời'));
    await tester.pumpAndSettle();

    expect(find.text('Thành viên đã tồn tại trong tổ chức.'), findsOneWidget);
    expect(find.byType(VToast), findsNothing);

    await cubit.close();
  });

  testWidgets('success pushes detail then pops true', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.inviteOk);
    final invitationsRepo = FakeInvitationRepository(module);
    Object? poppedResult;

    final router = GoRouter(
      initialLocation: '/more/users',
      routes: [
        GoRoute(
          path: '/more/users',
          builder: (context, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  poppedResult = await context.push('/more/users/invite');
                },
                child: const Text('Mở mời'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/more/users/invite',
          builder: (_, _) => OrganizationInviteMemberPage(
            session: testSessionController(),
            invitations: invitationsRepo,
            roleOptionsSource: _FakeRoles(),
            keyFactory: FakeIdempotencyKeyFactory(),
          ),
        ),
        GoRoute(
          path: '/more/users/invitations/:id',
          builder: (_, state) => OrganizationInvitationDetailPage(
            invitationId: state.pathParameters['id']!,
            invitations: invitationsRepo,
            keyFactory: FakeIdempotencyKeyFactory(),
            clock: () => DateTime.utc(2026, 7, 31),
          ),
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

    await tester.tap(find.text('Mở mời'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'newstaff@example.com');
    await tester.tap(find.text('Nhân viên bán hàng').first); // không còn chọn sẵn vai trò
    await tester.pump();
    await tester.tap(find.text('Gửi lời mời'));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết lời mời'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.text('Mở mời'), findsOneWidget);
    expect(poppedResult, isTrue);
  });

  testWidgets('390: invite roles are four radio rows; 1280: two-column grid', (tester) async {
    for (final size in const [Size(390, 844), Size(1280, 800)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = OrganizationInviteMemberCubit(
        session: testSessionController(),
        invitations: FakeInvitationRepository(
          FakeIamBackend(scenario: FakeIamScenario.inviteOk),
        ),
        roleOptionsSource: _FakeRoles(),
        keyFactory: FakeIdempotencyKeyFactory(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationInviteMemberPage(
            key: ValueKey(size.width),
            cubit: cubit,
          ),
        ),
      );
      await cubit.loadRoleOptions();
      await tester.pumpAndSettle();

      expect(find.byType(RadioGroup<String>), findsOneWidget);
      expect(find.text('Nhân viên bán hàng'), findsOneWidget);
      expect(find.text('Kế toán'), findsOneWidget);
      expect(find.text('Thủ kho'), findsOneWidget);
      expect(find.text('Chủ cửa hàng'), findsOneWidget);
      expect(find.text('Bán hàng và chăm sóc khách hàng'), findsOneWidget);

      if (size.width >= 840) {
        final staffRect = tester.getRect(find.text('Nhân viên bán hàng'));
        final accountantRect = tester.getRect(find.text('Kế toán'));
        expect(staffRect.top, equals(accountantRect.top));
      } else {
        final staffRect = tester.getRect(find.text('Nhân viên bán hàng'));
        final accountantRect = tester.getRect(find.text('Kế toán'));
        expect(accountantRect.top, greaterThan(staffRect.top));
      }

      await cubit.close();
    }
  });

  testWidgets('submitting disables email and roles', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final gate = Completer<TenantInvitationDetail>();
    final repo = _SlowCreateInvitationRepository(gate);
    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: repo,
      roleOptionsSource: _FakeRoles(),
      keyFactory: FakeIdempotencyKeyFactory(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationInviteMemberPage(cubit: cubit),
      ),
    );
    await cubit.loadRoleOptions();
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'staff@example.com');
    await tester.tap(find.text('Nhân viên bán hàng').first); // không còn chọn sẵn vai trò
    await tester.pump();
    await tester.tap(find.widgetWithText(VButton, 'Gửi lời mời'));
    await tester.pump();

    expect(find.text('Đang gửi...'), findsOneWidget);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.enabled, isFalse);

    gate.complete(
      TenantInvitationDetail(
        invitationId: 'inv-new',
        inviteeEmail: 'staff@example.com',
        initialRoleId: 'role-staff',
        initialRoleLabel: 'Nhân viên bán hàng',
        status: 'pending',
        expiresAt: DateTime.utc(2026, 8, 7),
        deliveryStatus: 'sent',
        deliveryCorrelationId: 'corr-1',
        version: 1,
        createdAt: DateTime.utc(2026, 7, 31),
        createdBy: 'user-1',
      ),
    );
    await tester.pumpAndSettle();
    await cubit.close();
  });

  testWidgets('arrow keys move the role selection', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(
        FakeIamBackend(scenario: FakeIamScenario.inviteOk),
      ),
      roleOptionsSource: _FakeRoles(),
      keyFactory: FakeIdempotencyKeyFactory(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: OrganizationInviteMemberPage(cubit: cubit),
      ),
    );
    await cubit.loadRoleOptions();
    await tester.pumpAndSettle();

    final radioFocus = find.descendant(
      of: find.byType(Radio<String>).first,
      matching: find.byType(Focus),
    );
    tester.widget<Focus>(radioFocus.first).focusNode?.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(cubit.state.selectedRoleId, 'role-accountant');
    await cubit.close();
  });

  testWidgets('success returns to the invitations tab', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = FakeIamBackend(scenario: FakeIamScenario.inviteOk);
    final membersRepo = FakeMemberRepository(module);
    final invitationsRepo = FakeInvitationRepository(module);
    final usersCubit = OrganizationUsersCubit(
      members: membersRepo,
      invitations: invitationsRepo,
      searchDebounce: Duration.zero,
    );
    await usersCubit.loadInitial();

    final router = GoRouter(
      initialLocation: '/more/users',
      routes: [
        GoRoute(
          path: '/more/users',
          builder: (_, _) => OrganizationUsersPage(cubit: usersCubit),
          routes: [
            GoRoute(
              path: 'invite',
              builder: (_, _) => OrganizationInviteMemberPage(
                session: testSessionController(),
                invitations: invitationsRepo,
                roleOptionsSource: _FakeRoles(),
                keyFactory: FakeIdempotencyKeyFactory(),
              ),
            ),
            GoRoute(
              path: 'invitations/:id',
              builder: (_, state) => OrganizationInvitationDetailPage(
                invitationId: state.pathParameters['id']!,
                invitations: invitationsRepo,
                keyFactory: FakeIdempotencyKeyFactory(),
                clock: () => DateTime.utc(2026, 7, 31),
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

    await tester.tap(find.byKey(const Key('users_invite')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'newstaff@example.com');
    await tester.tap(find.text('Nhân viên bán hàng').first); // không còn chọn sẵn vai trò
    await tester.pump();
    await tester.tap(find.widgetWithText(VButton, 'Gửi lời mời'));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiết lời mời'), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    expect(usersCubit.state.activeTab, OrganizationUsersTab.invitations);
    await usersCubit.close();
  });

  testWidgets('320 at text scale 2.0 does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = OrganizationInviteMemberCubit(
      session: testSessionController(),
      invitations: FakeInvitationRepository(
        FakeIamBackend(scenario: FakeIamScenario.inviteOk),
      ),
      roleOptionsSource: _FakeRoles(),
      keyFactory: FakeIdempotencyKeyFactory(),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 844),
          textScaler: TextScaler.linear(2.0),
        ),
        child: MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationInviteMemberPage(cubit: cubit),
        ),
      ),
    );
    await cubit.loadRoleOptions();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await cubit.close();
  });
}

final class _SlowCreateInvitationRepository extends InvitationRepository {
  _SlowCreateInvitationRepository(this._gate)
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

  final Completer<TenantInvitationDetail> _gate;

  @override
  Future<TenantInvitationDetail> create({
    required String email,
    required String roleCode,
    required String idempotencyKey,
  }) {
    return _gate.future;
  }
}
