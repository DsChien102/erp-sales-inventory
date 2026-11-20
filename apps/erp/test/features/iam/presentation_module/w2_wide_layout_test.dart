import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/core/router/app_router.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:erp/core/session/session_store.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/iam/data/member_repository.dart';
import 'package:erp/features/iam/data/invitation_repository.dart';
import 'package:erp/features/iam/data/audit_log_repository.dart';
import 'package:erp/features/iam/presentation/users/widgets/member_card.dart';

import '../support/fake_iam_backend.dart';
import '../../auth/support/scripted_auth.dart';

import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import '../../dashboard/presentation/fake_default_pair_repository.dart';

base class _CustomSessionStore extends SessionStore {
  _CustomSessionStore({
    this.grantedPermissions = const {
      IamPermissions.memberView,
      IamPermissions.tenantAuditView,
    },
    this.owner = false,
  });

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
      ..registerSingleton<DefaultPairRepository>(FakeDefaultPairRepository());
  });

  tearDown(() async {
    try {
      appRouter.go('/');
    } catch (_) {}
    await getIt.reset();
  });

  group('W-2 — Test bố cục rộng (Checklist 6.1)', () {
    testWidgets(
      '1. Users: 1280x800 hiện 2 cột, card isSelected: true, detail không có nút Quay lại',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
        final memberRepo = FakeMemberRepository(module);
        final invitationRepo = FakeInvitationRepository(module);
        final auditRepo = FakeAuditLogRepository(module);

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
        getIt.registerSingleton<AuditLogRepository>(auditRepo);

        await tester.pumpWidget(
          MaterialApp.router(
            theme: VTheme.lightTheme,
            routerConfig: appRouter,
          ),
        );

        // Đi thẳng tới chi tiết thành viên ở viewport rộng
        appRouter.go('/more/users/members/mem-owner-1');
        await tester.pumpAndSettle();

        // Cả 2 cột đều dựng
        expect(find.byType(OrganizationUsersBody), findsOneWidget);
        expect(find.byType(MemberDetailBody), findsOneWidget);

        // Card của thành viên đang chọn có isSelected: true
        final selectedCard = tester.widget<MemberCard>(
          find.widgetWithText(MemberCard, 'Lan Le'),
        );
        expect(selectedCard.isSelected, isTrue);

        // Detail không có nút Quay lại, cũng không có BackButton Material ngầm
        for (final matching in [find.byTooltip('Quay lại'), find.byType(BackButton)]) {
          expect(
            find.descendant(
              of: find.byType(OrganizationMemberDetailPage),
              matching: matching,
            ),
            findsNothing,
          );
        }
      },
    );

    testWidgets('2. Users: 390x844 hiện 1 cột chi tiết, có nút Quay lại', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
      final memberRepo = FakeMemberRepository(module);
      final invitationRepo = FakeInvitationRepository(module);
      final auditRepo = FakeAuditLogRepository(module);

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
      getIt.registerSingleton<AuditLogRepository>(auditRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      appRouter.go('/more/users/members/mem-owner-1');
      await tester.pumpAndSettle();

      // Chỉ dựng chi tiết, danh sách không dựng
      expect(find.byType(OrganizationUsersBody), findsNothing);
      expect(find.byType(MemberDetailBody), findsOneWidget);

      // Có nút Quay lại
      expect(find.byTooltip('Quay lại'), findsOneWidget);
    });

    testWidgets(
      '3. Roles: 1280x800 hiện 2 cột, detail không có nút Quay lại vs 390x844 có nút Quay lại',
      (tester) async {
        final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
        final memberRepo = FakeMemberRepository(module);
        final invitationRepo = FakeInvitationRepository(module);
        final auditRepo = FakeAuditLogRepository(module);

        final session = loginSession(
          store: _CustomSessionStore(owner: true),
        );
        session.applySignedInUser('user-1');

        getIt.registerSingleton<SessionController>(session);
        getIt.registerSingleton<MemberRepository>(memberRepo);
        getIt.registerSingleton<InvitationRepository>(invitationRepo);
        getIt.registerSingleton<AuditLogRepository>(auditRepo);

        // --- A. Bề rộng 1280x800 ---
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp.router(
            theme: VTheme.lightTheme,
            routerConfig: appRouter,
          ),
        );

        appRouter.go('/more/roles/warehouse');
        await tester.pumpAndSettle();

        expect(find.byType(OrganizationRolesPage), findsOneWidget);
        expect(find.byType(OrganizationRoleDetailPage), findsOneWidget);
        for (final matching in [find.byTooltip('Quay lại'), find.byType(BackButton)]) {
          expect(
            find.descendant(
              of: find.byType(OrganizationRoleDetailPage),
              matching: matching,
            ),
            findsNothing,
          );
        }

        // --- B. Bề rộng 390x844 ---
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();

        expect(find.byType(OrganizationRolesPage), findsNothing);
        expect(find.byType(OrganizationRoleDetailPage), findsOneWidget);
        expect(find.byTooltip('Quay lại'), findsOneWidget);

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets(
      '4. AuditLogs: 1280x800 hiện 2 cột, card isSelected: true, detail không nút Quay lại vs 390x844 có nút Quay lại',
      (tester) async {
        final module = FakeIamBackend(scenario: FakeIamScenario.tenantAuditSearchOk);
        final memberRepo = FakeMemberRepository(module);
        final invitationRepo = FakeInvitationRepository(module);
        final auditRepo = FakeAuditLogRepository(module);

        final session = loginSession(
          store: _CustomSessionStore(
            grantedPermissions: {IamPermissions.tenantAuditView},
            owner: true,
          ),
        );
        session.applySignedInUser('user-1');

        getIt.registerSingleton<SessionController>(session);
        getIt.registerSingleton<MemberRepository>(memberRepo);
        getIt.registerSingleton<InvitationRepository>(invitationRepo);
        getIt.registerSingleton<AuditLogRepository>(auditRepo);

        // --- A. Bề rộng 1280x800 ---
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp.router(
            theme: VTheme.lightTheme,
            routerConfig: appRouter,
          ),
        );

        appRouter.go('/more/audit-logs/AUD-T-001');
        await tester.pumpAndSettle();

        expect(find.byType(OrganizationAuditLogsPage), findsOneWidget);
        expect(find.byType(AuditLogDetailPage), findsOneWidget);

        final selectedItemCard = tester.widget<AuditLogItemCard>(
          find.byType(AuditLogItemCard).first,
        );
        expect(selectedItemCard.isSelected, isTrue);
        expect(
          find.descendant(
            of: find.byType(AuditLogDetailPage),
            matching: find.byTooltip('Quay lại'),
          ),
          findsNothing,
        );

        // --- B. Bề rộng 390x844 ---
        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpAndSettle();

        expect(find.byType(OrganizationAuditLogsPage), findsNothing);
        expect(find.byType(AuditLogDetailPage), findsOneWidget);
        expect(find.byTooltip('Quay lại'), findsOneWidget);

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets('5. 1280x800 khi chưa chọn dòng: hiện empty state hướng dẫn chọn', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
      final memberRepo = FakeMemberRepository(module);
      final invitationRepo = FakeInvitationRepository(module);
      final auditRepo = FakeAuditLogRepository(module);

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
      getIt.registerSingleton<MemberRepository>(memberRepo);
      getIt.registerSingleton<InvitationRepository>(invitationRepo);
      getIt.registerSingleton<AuditLogRepository>(auditRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      // 5.1 /more/users
      appRouter.go('/more/users');
      await tester.pumpAndSettle();
      expect(find.text('Chọn một thành viên hoặc lời mời để xem chi tiết.'), findsOneWidget);

      // 5.2 /more/roles
      appRouter.go('/more/roles');
      await tester.pumpAndSettle();
      expect(find.text('Chọn một vai trò để xem chi tiết.'), findsOneWidget);

      // 5.3 /more/audit-logs
      appRouter.go('/more/audit-logs');
      await tester.pumpAndSettle();
      expect(find.text('Chọn một mục lịch sử để xem chi tiết.'), findsOneWidget);
    });

    testWidgets(
      '6. 1280x800: chọn card trong list cập nhật URL qua context.go, không reload cả danh sách',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
        final memberRepo = FakeMemberRepository(module);
        final invitationRepo = FakeInvitationRepository(module);
        final auditRepo = FakeAuditLogRepository(module);

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
        getIt.registerSingleton<AuditLogRepository>(auditRepo);

        await tester.pumpWidget(
          MaterialApp.router(
            theme: VTheme.lightTheme,
            routerConfig: appRouter,
          ),
        );

        appRouter.go('/more/users');
        await tester.pumpAndSettle();

        final initialQueryCount = module.queriesOf<ListTenantMembersQuery>().length;
        expect(initialQueryCount, greaterThan(0));

        // Bấm vào card thành viên
        await tester.tap(find.text('Lan Le'));
        await tester.pumpAndSettle();

        // URL cập nhật sang chi tiết thành viên
        expect(
          appRouter.routerDelegate.currentConfiguration.uri.toString(),
          equals('/more/users/members/mem-owner-1'),
        );

        // Không gọi lại RPC lấy danh sách thành viên (giữ nguyên số query)
        expect(
          module.queriesOf<ListTenantMembersQuery>().length,
          equals(initialQueryCount),
        );
      },
    );

    testWidgets('7. 1280x800: thu hồi lời mời điều hướng về /more/users và kích hoạt reload', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
      final memberRepo = FakeMemberRepository(module);
      final invitationRepo = FakeInvitationRepository(module);
      final auditRepo = FakeAuditLogRepository(module);

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
      getIt.registerSingleton<AuditLogRepository>(auditRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      // Mở chi tiết lời mời ở 2 cột (trên tab Lời mời)
      appRouter.go('/more/users');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lời mời'));
      await tester.pumpAndSettle();

      appRouter.go('/more/users/invitations/inv-1');
      await tester.pumpAndSettle();

      expect(find.byType(OrganizationInvitationDetailPage), findsOneWidget);
      final initialInvitationQueries = module.queriesOf<ListInvitationsQuery>().length;

      // Thực hiện thu hồi lời mời
      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thu hồi lời mời'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.byType(VSheetDialog),
          matching: find.byType(TextField),
        ),
        'Không còn nhu cầu',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(VButton, 'Thu hồi lời mời'));
      await tester.pumpAndSettle();

      // Sau khi thu hồi, điều hướng về /more/users
      expect(
        appRouter.routerDelegate.currentConfiguration.uri.toString(),
        equals('/more/users'),
      );

      // Toast thành công hiển thị
      expect(find.text('Đã thu hồi lời mời.'), findsOneWidget);

      // Kích hoạt reload lời mời (số query tăng)
      expect(
        module.queriesOf<ListInvitationsQuery>().length,
        greaterThan(initialInvitationQueries),
      );
    });

    testWidgets('8. 1280x800: sheet bộ lọc render VSheetDialog với 1 tiêu đề duy nhất', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
      final memberRepo = FakeMemberRepository(module);
      final invitationRepo = FakeInvitationRepository(module);
      final auditRepo = FakeAuditLogRepository(module);

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
      getIt.registerSingleton<AuditLogRepository>(auditRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      appRouter.go('/more/users');
      await tester.pumpAndSettle();

      // Mở bộ lọc thành viên
      await tester.tap(find.byTooltip('Bộ lọc'));
      await tester.pumpAndSettle();

      // Hiển thị VSheetDialog thay vì ModalBottomSheet
      expect(find.byType(VSheetDialog), findsOneWidget);

      // Tiêu đề "Bộ lọc thành viên" chỉ xuất hiện đúng 1 lần duy nhất trong header
      expect(find.text('Bộ lọc thành viên'), findsOneWidget);

      // Bấm áp dụng để đóng dialog
      await tester.tap(find.text('Áp dụng'));
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsNothing);
    });

    testWidgets('9. 1280x800: sheet xác nhận tạm ngừng thành viên mở dạng VSheetDialog', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
      final memberRepo = FakeMemberRepository(module);
      final invitationRepo = FakeInvitationRepository(module);
      final auditRepo = FakeAuditLogRepository(module);

      final session = loginSession(
        store: _CustomSessionStore(
          grantedPermissions: {
            IamPermissions.memberView,
            IamPermissions.memberStatusUpdate,
          },
          owner: true,
        ),
      );
      session.applySignedInUser('user-1');

      getIt.registerSingleton<SessionController>(session);
      getIt.registerSingleton<MemberRepository>(memberRepo);
      getIt.registerSingleton<InvitationRepository>(invitationRepo);
      getIt.registerSingleton<AuditLogRepository>(auditRepo);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: VTheme.lightTheme,
          routerConfig: appRouter,
        ),
      );

      appRouter.go('/more/users/members/mem-staff-1');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạm ngừng thành viên'));
      await tester.pumpAndSettle();

      expect(find.byType(VSheetDialog), findsOneWidget);
      expect(find.text('Tạm ngừng thành viên?'), findsOneWidget);
    });

    testWidgets(
      '10. 1280x800: meetsGuideline tapTarget và labeledTapTarget cho màn Người dùng 2 cột',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final semanticsHandle = tester.ensureSemantics();

        final module = FakeIamBackend(scenario: FakeIamScenario.usersSearchOk);
        final memberRepo = FakeMemberRepository(module);
        final invitationRepo = FakeInvitationRepository(module);
        final auditRepo = FakeAuditLogRepository(module);

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
        getIt.registerSingleton<AuditLogRepository>(auditRepo);

        await tester.pumpWidget(
          MaterialApp.router(
            theme: VTheme.lightTheme,
            routerConfig: appRouter,
          ),
        );

        appRouter.go('/more/users/members/mem-owner-1');
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semanticsHandle.dispose();
      },
    );

    Future<FakeIamBackend> pumpApp(
      WidgetTester tester, {
      required Size size,
      Set<String> permissions = const {},
      bool owner = true,
      FakeIamScenario scenario = FakeIamScenario.usersSearchOk,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = FakeIamBackend(scenario: scenario);
      final session = loginSession(
        store: _CustomSessionStore(grantedPermissions: permissions, owner: owner),
      );
      session.applySignedInUser('user-1');

      getIt.registerSingleton<SessionController>(session);
      getIt.registerSingleton<MemberRepository>(FakeMemberRepository(module));
      getIt.registerSingleton<InvitationRepository>(FakeInvitationRepository(module));
      getIt.registerSingleton<AuditLogRepository>(FakeAuditLogRepository(module));

      await tester.pumpWidget(
        MaterialApp.router(theme: VTheme.lightTheme, routerConfig: appRouter),
      );
      return module;
    }

    String currentUri() => appRouter.routerDelegate.currentConfiguration.uri.toString();

    Future<void> openDeactivateDialog(WidgetTester tester) async {
      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạm ngừng thành viên'));
      await tester.pumpAndSettle();
      expect(find.byType(VSheetDialog), findsOneWidget);
    }

    testWidgets(
      '11. 1280x800: hộp thoại xác nhận chặn cả cửa sổ, Huỷ/Xác nhận đóng đúng hộp thoại',
      (tester) async {
        final module = await pumpApp(
          tester,
          size: const Size(1280, 800),
          permissions: {IamPermissions.memberView, IamPermissions.memberStatusUpdate},
        );

        appRouter.go('/more/users/members/mem-staff-1');
        await tester.pumpAndSettle();
        await openDeactivateDialog(tester);

        // Lớp chắn của hộp thoại phủ toàn cửa sổ (cả cột danh sách và thanh bên).
        expect(
          tester.getRect(find.byType(ModalBarrier).last),
          equals(const Rect.fromLTWH(0, 0, 1280, 800)),
        );

        // Bấm vào vùng cột danh sách khi hộp thoại mở: URL không đổi.
        await tester.tap(find.text('Lan Le'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(currentUri(), equals('/more/users/members/mem-staff-1'));
        expect(find.byType(OrganizationMemberDetailPage), findsOneWidget);

        // Huỷ: hộp thoại đóng, trang chi tiết còn.
        await openDeactivateDialog(tester);
        await tester.tap(
          find.descendant(of: find.byType(VSheetDialog), matching: find.text('Quay lại')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(VSheetDialog), findsNothing);
        expect(find.byType(OrganizationMemberDetailPage), findsOneWidget);
        expect(currentUri(), equals('/more/users/members/mem-staff-1'));

        // Xác nhận: đóng + toast + danh sách tải lại (refreshActiveTab).
        final before = module.queriesOf<ListTenantMembersQuery>().length;
        await openDeactivateDialog(tester);
        await tester.tap(
          find.descendant(of: find.byType(VSheetDialog), matching: find.text('Tạm ngừng')),
        );
        await tester.pumpAndSettle();
        expect(find.byType(VSheetDialog), findsNothing);
        expect(find.byType(OrganizationMemberDetailPage), findsOneWidget);
        expect(find.text('Đã tạm ngừng thành viên.'), findsOneWidget);
        expect(module.commandsOf<DeactivateMembershipCommand>(), isNotEmpty);
        expect(module.queriesOf<ListTenantMembersQuery>().length, greaterThan(before));
      },
    );

    testWidgets('12. Không có memberView: /more/users/members/x bị chặn, 0 RPC thành viên', (
      tester,
    ) async {
      final module = await pumpApp(
        tester,
        size: const Size(390, 844),
        owner: false,
      );

      appRouter.go('/more/users/members/x');
      await tester.pumpAndSettle();

      expect(find.text('Bạn không có quyền xem thành viên'), findsOneWidget);
      expect(module.queriesOf<ListTenantMembersQuery>(), isEmpty);
      expect(module.queriesOf<GetTenantMemberQuery>(), isEmpty);
    });

    testWidgets(
      '14. Hẹp: mở thẳng chi tiết -> Quay lại -> thấy trang danh sách (Người dùng, Vai trò, Lịch sử)',
      (tester) async {
        await pumpApp(
          tester,
          size: const Size(390, 844),
          permissions: {IamPermissions.memberView, IamPermissions.tenantAuditView},
          scenario: FakeIamScenario.tenantAuditSearchOk,
        );

        appRouter.go('/more/users/members/mem-owner-1');
        await tester.pumpAndSettle();
        expect(find.byType(OrganizationMemberDetailPage), findsOneWidget);
        await tester.tap(find.byTooltip('Quay lại'));
        await tester.pumpAndSettle();
        expect(find.byType(OrganizationMemberDetailPage), findsNothing);
        expect(find.byType(OrganizationUsersBody), findsOneWidget);

        appRouter.go('/more/roles/warehouse');
        await tester.pumpAndSettle();
        expect(find.byType(OrganizationRoleDetailPage), findsOneWidget);
        await tester.tap(find.byTooltip('Quay lại'));
        await tester.pumpAndSettle();
        expect(find.byType(OrganizationRoleDetailPage), findsNothing);
        expect(find.byType(OrganizationRolesPage), findsOneWidget);

        appRouter.go('/more/audit-logs/AUD-T-001');
        await tester.pumpAndSettle();
        expect(find.byType(AuditLogDetailPage), findsOneWidget);
        await tester.tap(find.byTooltip('Quay lại'));
        await tester.pumpAndSettle();
        expect(find.byType(AuditLogDetailPage), findsNothing);
        expect(find.byType(OrganizationAuditLogsPage), findsOneWidget);
      },
    );

    testWidgets(
      '15. Lịch sử: 1280x800 cột danh sách không có nút Quay lại; 390x844 từ /more có nút Quay lại',
      (tester) async {
        // --- A. Bề rộng 1280x800 ---
        await pumpApp(
          tester,
          size: const Size(1280, 800),
          permissions: {IamPermissions.tenantAuditView},
          scenario: FakeIamScenario.tenantAuditSearchOk,
        );

        appRouter.go('/more/audit-logs/AUD-T-001');
        await tester.pumpAndSettle();

        expect(find.byType(OrganizationAuditLogsPage), findsOneWidget);
        expect(find.byType(AuditLogDetailPage), findsOneWidget);

        // Trong cột danh sách, tooltip "Quay lại" = 0
        expect(
          find.descendant(
            of: find.byType(OrganizationAuditLogsPage),
            matching: find.byTooltip('Quay lại'),
          ),
          findsNothing,
        );

        // --- B. Bề rộng 390x844: mở /more rồi push sang /more/audit-logs ---
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        appRouter.go('/more');
        await tester.pumpAndSettle();

        appRouter.push('/more/audit-logs');
        await tester.pumpAndSettle();

        expect(find.byType(OrganizationAuditLogsPage), findsOneWidget);
        final backButton = find.descendant(
          of: find.byType(OrganizationAuditLogsPage),
          matching: find.byTooltip('Quay lại'),
        );
        expect(backButton, findsOneWidget);

        // Bấm Quay lại quay về /more
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        expect(find.byType(OrganizationAuditLogsPage), findsNothing);
        expect(currentUri(), equals('/more'));
      },
    );
  });
}
