import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/core/router/app_router.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/iam/data/member_repository.dart';
import 'package:erp/features/iam/data/invitation_repository.dart';
import 'package:erp/features/iam/data/audit_log_repository.dart';
import 'package:erp/features/auth/data/models/invitation_token_inspection.dart';
import 'package:erp/features/auth/presentation/pages/login_page.dart';
import 'package:erp/features/auth/presentation/pages/signup_page.dart';
import 'package:erp/features/auth/presentation/pages/verify_email_page.dart';
import 'package:erp/features/auth/presentation/pages/no_organization_page.dart';
import 'package:erp/features/auth/presentation/widgets/invitation_token_entry_form.dart';
import 'package:erp/features/auth/presentation/widgets/invitation_registration_form.dart';

import '../support/fake_iam_backend.dart';
import '../../auth/support/scripted_auth.dart';

import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';
import '../../dashboard/presentation/fake_default_pair_repository.dart';

base class _CustomSessionStore extends SessionStore {
  _CustomSessionStore({this.grantedPermissions = const {}, this.owner = false});
  final Set<String> grantedPermissions;
  final bool owner;

  @override
  bool hasPermission(String code) => grantedPermissions.contains(code);

  @override
  bool get isOwner => owner;

  @override
  String? get tenantId => 'tenant-test';
}

void main() {
  setUp(() async {
    await getIt.reset();
    getIt
      ..registerSingleton<IExecutionContext>(FakeExecutionContext(tenantId: 'tenant-test'))
      ..registerSingleton<DefaultPairRepository>(FakeDefaultPairRepository());
  });

  tearDown(() async {
    try {
      appRouter.go('/');
    } catch (_) {}
    await getIt.reset();
  });

  group('W-2 Bước 0 — Test giữ hành vi (H1–H13)', () {
    testWidgets('H1: Thiếu quyền memberView -> không tạo cubit, không gọi RPC member', (tester) async {
      final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
      final memberRepo = FakeMemberRepository(module);
      final invitationRepo = FakeInvitationRepository(module);
      final session = loginSession(
        store: _CustomSessionStore(grantedPermissions: {}, owner: false),
      );
      session.applySignedInUser('user-1');

      getIt.registerSingleton<SessionController>(session);
      getIt.registerSingleton<MemberRepository>(memberRepo);
      getIt.registerSingleton<InvitationRepository>(invitationRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      appRouter.go('/more/users');
      await tester.pumpAndSettle();

      expect(find.text('Bạn không có quyền xem thành viên'), findsOneWidget);
      expect(module.queriesOf<ListTenantMembersQuery>(), isEmpty);
    });

    testWidgets('H1: Không phải Owner -> không gọi RPC roles', (tester) async {
      final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
      final memberRepo = FakeMemberRepository(module);
      final invitationRepo = FakeInvitationRepository(module);
      final session = loginSession(
        store: _CustomSessionStore(grantedPermissions: {}, owner: false),
      );
      session.applySignedInUser('user-1');

      getIt.registerSingleton<SessionController>(session);
      getIt.registerSingleton<MemberRepository>(memberRepo);
      getIt.registerSingleton<InvitationRepository>(invitationRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      appRouter.go('/more/roles');
      await tester.pumpAndSettle();

      expect(find.text('Bạn không có quyền xem vai trò'), findsOneWidget);
      expect(module.queriesOf<ListTenantMembersQuery>(), isEmpty);
    });

    testWidgets('H1: Thiếu quyền tenantAuditView -> không gọi RPC audit logs', (tester) async {
      final module = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);
      final auditRepo = FakeAuditLogRepository(module);
      final session = loginSession(
        store: _CustomSessionStore(grantedPermissions: {}, owner: false),
      );
      session.applySignedInUser('user-1');

      getIt.registerSingleton<SessionController>(session);
      getIt.registerSingleton<MemberRepository>(FakeMemberRepository(module));
      getIt.registerSingleton<InvitationRepository>(FakeInvitationRepository(module));
      getIt.registerSingleton<AuditLogRepository>(auditRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      appRouter.go('/more/audit-logs');
      await tester.pumpAndSettle();

      expect(find.text('Bạn không có quyền xem lịch sử quản trị'), findsOneWidget);
      expect(module.queriesOf<SearchTenantAuditLogsQuery>(), isEmpty);
    });

    testWidgets('H2: Mở danh sách Người dùng -> gọi repo đúng 1 lần', (tester) async {
      final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
      final memberRepo = FakeMemberRepository(module);
      final invitationRepo = FakeInvitationRepository(module);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: OrganizationUsersPage(
              members: memberRepo,
              invitations: invitationRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(module.queriesOf<ListTenantMembersQuery>().length, equals(1));
    });

    testWidgets('H3: canInvite false không hiện nút Mời thành viên', (tester) async {
      final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
      final cubit = OrganizationUsersCubit(
        members: FakeMemberRepository(module),
        invitations: FakeInvitationRepository(module),
        searchDebounce: Duration.zero,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: OrganizationUsersPage(
              cubit: cubit,
              canInvite: false,
            ),
          ),
        ),
      );
      await cubit.loadInitial();
      await tester.pumpAndSettle();

      expect(find.text('Mời thành viên'), findsNothing);
      await cubit.close();
    });

    testWidgets('H4: Mời xong trả true -> danh sách lời mời tải lại', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
      final memberRepo = FakeMemberRepository(module);
      final invitationRepo = FakeInvitationRepository(module);
      final session = loginSession(
        store: _CustomSessionStore(
          grantedPermissions: {
            IamPermissions.memberView,
            IamPermissions.memberInvite,
          },
          owner: true,
        ),
      );
      session.applySignedInUser('user-1');

      getIt.registerSingleton<SessionController>(session);
      getIt.registerSingleton<MemberRepository>(memberRepo);
      getIt.registerSingleton<InvitationRepository>(invitationRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      appRouter.go('/more/users');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lời mời'));
      await tester.pumpAndSettle();

      final initialInvitationsQueries = module.queriesOf<ListInvitationsQuery>().length;

      await tester.tap(find.byTooltip('Mời thành viên'));
      await tester.pumpAndSettle();

      expect(find.text('Mời thành viên'), findsWidgets);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
      navigator.pop(true);
      await tester.pumpAndSettle();

      expect(module.queriesOf<ListInvitationsQuery>().length, greaterThan(initialInvitationsQueries));
    });

    testWidgets('H5: Mở thành viên rồi quay lại -> loadMembers gọi lại', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.membersSearchOk);
      final memberRepo = FakeMemberRepository(module);
      final invitationRepo = FakeInvitationRepository(module);
      final session = loginSession(
        store: _CustomSessionStore(
          grantedPermissions: {IamPermissions.memberView},
          owner: true,
        ),
      );
      session.applySignedInUser('user-1');

      getIt.registerSingleton<SessionController>(session);
      getIt.registerSingleton<MemberRepository>(memberRepo);
      getIt.registerSingleton<InvitationRepository>(invitationRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      appRouter.go('/more/users');
      await tester.pumpAndSettle();

      final initialCount = module.queriesOf<ListTenantMembersQuery>().length;

      await tester.tap(find.text('Lan Le'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết thành viên'), findsOneWidget);

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(module.queriesOf<ListTenantMembersQuery>().length, greaterThan(initialCount));
    });

    testWidgets('H6: Thu hồi lời mời -> toast đúng chuỗi và tải lại lời mời', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.invitationsSearchOk);
      final memberRepo = FakeMemberRepository(module);
      final invitationRepo = FakeInvitationRepository(module);
      final session = loginSession(
        store: _CustomSessionStore(
          grantedPermissions: {
            IamPermissions.memberView,
            IamPermissions.memberInvite,
          },
          owner: true,
        ),
      );
      session.applySignedInUser('user-1');

      getIt.registerSingleton<SessionController>(session);
      getIt.registerSingleton<MemberRepository>(memberRepo);
      getIt.registerSingleton<InvitationRepository>(invitationRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      appRouter.go('/more/users');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lời mời'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('invitee@example.com'));
      await tester.pumpAndSettle();

      expect(find.text('Chi tiết lời mời'), findsOneWidget);

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thu hồi lời mời'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'Lý do thu hồi test');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Thu hồi lời mời'));
      await tester.pumpAndSettle();

      expect(find.text('Đã thu hồi lời mời.'), findsOneWidget);
      expect(module.commandsOf<RevokeInvitationCommand>(), isNotEmpty);
    });

    testWidgets('H7: Mở vai trò từ extra không gọi repo thêm; mở theo code thì gọi repo', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
      final memberRepo = FakeMemberRepository(module);
      final invitationRepo = FakeInvitationRepository(module);
      final session = loginSession(
        store: _CustomSessionStore(owner: true),
      );
      session.applySignedInUser('user-1');

      getIt.registerSingleton<SessionController>(session);
      getIt.registerSingleton<MemberRepository>(memberRepo);
      getIt.registerSingleton<InvitationRepository>(invitationRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      const role = RoleUiModel(
        id: 'store_owner',
        title: 'Chủ cửa hàng',
        description: 'Toàn quyền',
      );
      appRouter.go('/more/roles/store_owner', extra: role);
      await tester.pumpAndSettle();

      expect(find.text('Chủ cửa hàng'), findsWidgets);
      final initialQueryCount = module.queriesOf<ListTenantMembersQuery>().length;

      appRouter.go('/more/roles/warehouse');
      await tester.pumpAndSettle();

      expect(find.text('Thủ kho'), findsWidgets);
      expect(module.queriesOf<ListTenantMembersQuery>().length, greaterThanOrEqualTo(initialQueryCount));
    });

    testWidgets('H8: Mở lịch sử và quay lại -> danh sách giữ bộ lọc', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);
      final auditRepo = FakeAuditLogRepository(module);
      final session = loginSession(
        store: _CustomSessionStore(
          grantedPermissions: {IamPermissions.tenantAuditView},
          owner: true,
        ),
      );
      session.applySignedInUser('user-1');

      getIt.registerSingleton<SessionController>(session);
      getIt.registerSingleton<MemberRepository>(FakeMemberRepository(module));
      getIt.registerSingleton<InvitationRepository>(FakeInvitationRepository(module));
      getIt.registerSingleton<AuditLogRepository>(auditRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      appRouter.go('/more/audit-logs');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Bộ lọc'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thành công'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hoạt động quản trị'));
      await tester.pumpAndSettle();
      expect(find.text('Chi tiết hoạt động'), findsOneWidget);

      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();

      expect(find.text('Lịch sử quản trị'), findsOneWidget);
    });

    test('H9: Đổi tab Thành viên <-> Lời mời giữ bộ lọc từng tab', () async {
      final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
      final cubit = OrganizationUsersCubit(
        members: FakeMemberRepository(module),
        invitations: FakeInvitationRepository(module),
        searchDebounce: Duration.zero,
      );

      await cubit.setMemberFilter('Tạm ngừng');
      expect(cubit.state.memberFilter, equals('Tạm ngừng'));

      cubit.selectTab(OrganizationUsersTab.invitations);
      expect(cubit.state.activeTab, equals(OrganizationUsersTab.invitations));

      cubit.selectTab(OrganizationUsersTab.members);
      expect(cubit.state.memberFilter, equals('Tạm ngừng'));
      await cubit.close();
    });

    testWidgets('H10: 7 đường dẫn cũ redirect đúng đích', (tester) async {
      final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
      getIt.registerSingleton<MemberRepository>(FakeMemberRepository(module));
      getIt.registerSingleton<InvitationRepository>(FakeInvitationRepository(module));
      getIt.registerSingleton<AuditLogRepository>(FakeAuditLogRepository(module));

      final session = loginSession(
        store: _CustomSessionStore(
          grantedPermissions: {
            IamPermissions.memberView,
            IamPermissions.tenantAuditView,
          },
          owner: true,
        ),
      );
      session.applySignedInUser('user-1');
      getIt.registerSingleton<SessionController>(session);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      for (final target in [
        ('/more/users/invitation-detail', '/more/users'),
        ('/more/users/member-detail', '/more/users'),
        ('/more/users/select-role', '/more/users-and-roles'),
        ('/more/users/preview-role-change', '/more/users-and-roles'),
        ('/more/roles/detail', '/more/roles'),
        ('/more/audit-logs/detail', '/more/audit-logs'),
        ('/more/users/invite', '/more/users/invite'),
      ]) {
        appRouter.go(target.$1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(appRouter.routerDelegate.currentConfiguration.uri.toString(), target.$2);
      }
    });

    testWidgets('H11: 3 Sheet bộ lọc mở qua showVAdaptiveSheet -> Áp dụng -> nhận đúng tiêu chí', (tester) async {
      MemberFilterCriteria? memberApplied;
      InvitationFilterCriteria? invitationApplied;
      AuditLogFilterCriteria? auditApplied;

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => showVAdaptiveSheet<void>(
                      context: context,
                      title: 'Bộ lọc thành viên',
                      child: MemberFilterBottomSheet(
                        initialCriteria: const MemberFilterCriteria(),
                        onApply: (criteria) => memberApplied = criteria,
                      ),
                    ),
                    child: const Text('Open Member Filter'),
                  ),
                  ElevatedButton(
                    onPressed: () => showVAdaptiveSheet<void>(
                      context: context,
                      title: 'Bộ lọc lời mời',
                      child: InvitationFilterBottomSheet(
                        initialCriteria: const InvitationFilterCriteria(),
                        onApply: (criteria) => invitationApplied = criteria,
                      ),
                    ),
                    child: const Text('Open Invitation Filter'),
                  ),
                  ElevatedButton(
                    onPressed: () => showVAdaptiveSheet<void>(
                      context: context,
                      title: 'Bộ lọc nhật ký nền tảng',
                      child: AuditLogFilterBottomSheet(
                        initialCriteria: const AuditLogFilterCriteria(),
                        onApply: (criteria) => auditApplied = criteria,
                      ),
                    ),
                    child: const Text('Open Audit Filter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 1. Member filter
      await tester.tap(find.text('Open Member Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạm ngừng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();
      expect(memberApplied?.status, equals('Tạm ngừng'));

      // 2. Invitation filter
      await tester.tap(find.text('Open Invitation Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Đang chờ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();
      expect(invitationApplied?.status, equals('Đang chờ'));

      // 3. Audit log filter
      await tester.tap(find.text('Open Audit Filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thành công'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();
      expect(auditApplied?.status, equals(AuditLogStatus.success));
    });

    testWidgets('H12: Tab gốc không có Quay lại, màn con có Quay lại', (tester) async {
      final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
      getIt.registerSingleton<MemberRepository>(FakeMemberRepository(module));
      getIt.registerSingleton<InvitationRepository>(FakeInvitationRepository(module));
      getIt.registerSingleton<AuditLogRepository>(FakeAuditLogRepository(module));

      final session = loginSession(
        store: _CustomSessionStore(
          grantedPermissions: {
            IamPermissions.memberView,
            IamPermissions.tenantAuditView,
          },
          owner: true,
        ),
      );
      session.applySignedInUser('user-1');
      getIt.registerSingleton<SessionController>(session);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      // 1. Tab gốc không có nút Quay lại
      appRouter.go('/');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Quay lại'), findsNothing);

      // 2. Màn con (màn chi tiết đẩy) có nút Quay lại
      appRouter.push('/more/users/invite');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Quay lại'), findsOneWidget);
    });

    testWidgets('H13: 7 màn công khai ở bề rộng 390 chiếm đúng 390 và bottomBar < 120', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = loginSession();
      final authScreens = <Widget>[
        LoginPage(auth: ScriptedAuthRepository(), session: session),
        SignupPage(auth: ScriptedAuthRepository(), session: session),
        VerifyEmailPage(
          email: 'user@example.com',
          auth: ScriptedAuthRepository(),
          session: session,
        ),
        NoOrganizationPage(session: session),
        InvitationTokenEntryForm(onInspect: (_) {}, isSubmitting: false),
        InvitationRegistrationForm(
          inspection: InvitationTokenInspection(
            tenantId: 'tenant-1',
            tenantName: 'Tổ chức thử nghiệm',
            inviteeEmail: 'invitee@example.com',
            initialRoleId: 'staff',
            initialRoleLabel: 'Nhân viên bán hàng',
            expiresAt: DateTime.utc(2026, 12, 31),
            accountExists: false,
          ),
          isSubmitting: false,
          onRegister: ({
            required familyName,
            required givenName,
            required password,
            phone,
          }) async {},
        ),
        ResetPasswordPage(
          emailMasked: 'u***@example.com',
        ),
      ];

      for (final screen in authScreens) {
        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: screen,
          ),
        );
        await tester.pump();
        final scrollable = find.byType(Scrollable);
        expect(scrollable, findsWidgets, reason: '${screen.runtimeType}');
        expect(
          tester.getSize(scrollable.first).width,
          equals(390),
          reason: '${screen.runtimeType}',
        );
      }

      // Kiểm riêng bottomBar của InvitationTokenEntryForm và InvitationRegistrationForm < 120px
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationTokenEntryForm(
            onInspect: (_) {},
            isSubmitting: false,
          ),
        ),
      );
      await tester.pump();
      final submitButton = find.byKey(const Key('invitation_token_submit'));
      expect(submitButton, findsOneWidget);
      expect(tester.getSize(submitButton).height, lessThan(120));

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationRegistrationForm(
            inspection: InvitationTokenInspection(
              tenantId: 'tenant-1',
              tenantName: 'Tổ chức thử nghiệm',
              inviteeEmail: 'invitee@example.com',
              initialRoleId: 'staff',
              initialRoleLabel: 'Nhân viên bán hàng',
              expiresAt: DateTime.utc(2026, 12, 31),
              accountExists: false,
            ),
            isSubmitting: false,
            onRegister: ({
              required familyName,
              required givenName,
              required password,
              phone,
            }) async {},
          ),
        ),
      );
      await tester.pump();
      final acceptButton = find.byKey(const Key('invitation_accept_submit'));
      expect(acceptButton, findsOneWidget);
      expect(tester.getSize(acceptButton).height, lessThan(120));
    });

    testWidgets('7 màn công khai ở bề rộng 1280 co lại tối đa 480', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final session = loginSession();
      final authScreens = <Widget>[
        LoginPage(auth: ScriptedAuthRepository(), session: session),
        SignupPage(auth: ScriptedAuthRepository(), session: session),
        VerifyEmailPage(
          email: 'user@example.com',
          auth: ScriptedAuthRepository(),
          session: session,
        ),
        NoOrganizationPage(session: session),
        InvitationTokenEntryForm(onInspect: (_) {}, isSubmitting: false),
        InvitationRegistrationForm(
          inspection: InvitationTokenInspection(
            tenantId: 'tenant-1',
            tenantName: 'Tổ chức thử nghiệm',
            inviteeEmail: 'invitee@example.com',
            initialRoleId: 'staff',
            initialRoleLabel: 'Nhân viên bán hàng',
            expiresAt: DateTime.utc(2026, 12, 31),
            accountExists: false,
          ),
          isSubmitting: false,
          onRegister: ({
            required familyName,
            required givenName,
            required password,
            phone,
          }) async {},
        ),
        const ResetPasswordPage(
          emailMasked: 'u***@example.com',
        ),
      ];

      for (final screen in authScreens) {
        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: screen,
          ),
        );
        await tester.pump();
        final scrollable = find.byType(Scrollable);
        expect(scrollable, findsWidgets, reason: '${screen.runtimeType}');
        expect(
          tester.getSize(scrollable.first).width,
          lessThanOrEqualTo(480),
          reason: '${screen.runtimeType}',
        );
      }
    });
  });
}
