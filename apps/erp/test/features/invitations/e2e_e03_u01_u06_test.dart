import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../iam/support/iam_module_repositories.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/iam/testing.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

import '../auth/support/scripted_invitations.dart';

/// e2e_e03_u01..u06 — members/invitations vertical (S6–S10) + S8 token paths.
void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> enterInvitationCode(WidgetTester tester, String code) async {
    expect(find.byType(VVerificationCodeField), findsOneWidget);
    await tester.enterText(
      find
          .descendant(
            of: find.byKey(const Key('invitation_token_input')),
            matching: find.byType(TextField),
          )
          .first,
      code,
    );
    await tester.pump();
  }

  Future<void> submitInvitationCode(WidgetTester tester, String code) async {
    await enterInvitationCode(tester, code);
  }

  void register(IIamModule module) {
    getIt
      ..registerSingleton<IExecutionContext>(
        FakeExecutionContext(tenantId: 'org-001'),
      )
      ..registerSingleton<IIamModule>(module);
  }

  testWidgets(
    'e2e_e03_u01_fr01_01: list members then invitations via IIamModule',
    (tester) async {
      await phone(tester);
      final module = FakeIamModule(scenario: FakeIamScenario.membersSearchOk);
      register(module);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationUsersPage(
            members: IamModuleMemberRepository(module),
            invitations: IamModuleInvitationRepository(module),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lan Le'), findsOneWidget);
      expect(find.text('Hoa Tran'), findsOneWidget);

      await tester.tap(find.text('Lời mời'));
      await tester.pumpAndSettle();
      expect(find.text('invitee@example.com'), findsOneWidget);
    },
  );

  testWidgets(
    'e2e_e03_u02_fr01_01: invite member loads roles and submits CreateInvitation',
    (tester) async {
      await phone(tester);
      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.inviteOk),
      );
      register(module);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationInviteMemberPage(
            session: testSessionController(),
            invitations: IamModuleInvitationRepository(module),
            keyFactory: FakeIdempotencyKeyFactory(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nhân viên bán hàng'), findsWidgets);
      await tester.enterText(find.byType(TextField), 'new.staff@example.com');
      await tester.pump();
      await tester.tap(find.text('Gửi lời mời'));
      await tester.pumpAndSettle();

      expect(module.commandsOf<CreateInvitationCommand>(), hasLength(1));
    },
  );

  testWidgets(
    'e2e_e03_u03_fr01_01: opaque token → existing account accept',
    (tester) async {
      await phone(tester);
      final module = FakeIamModule(
        scenario: FakeIamScenario.acceptExistingAccountOk,
      );
      register(module);
      final router = GoRouter(
        initialLocation: '/invitation',
        routes: <RouteBase>[
          GoRoute(
            path: '/invitation',
            builder: (_, _) => InvitationPageHarness(
              scenario: FakeIamScenario.acceptExistingAccountOk,
            ).page,
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('Login')),
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

      await submitInvitationCode(tester, 'K7P29XQM');
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận lời mời tham gia tổ chức?'), findsOneWidget);
      expect(
        find.byKey(const Key('invitation_confirm_sheet_accept')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('invitation_confirm_sheet_accept')));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.toString(), '/login');
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Đã tham gia tổ chức'), findsNothing);
      expect(find.text('K7P29XQM'), findsNothing);
    },
  );

  testWidgets(
    'e2e_e03_u03_fr01_02: opaque token → new account registration fields',
    (tester) async {
      await phone(tester);
      final module = FakeIamModule(scenario: FakeIamScenario.registerAndAcceptOk);
      register(module);
      final router = GoRouter(
        initialLocation: '/invitation',
        routes: <RouteBase>[
          GoRoute(
            path: '/invitation',
            builder: (_, _) => InvitationPageHarness(
              scenario: FakeIamScenario.registerAndAcceptOk,
            ).page,
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('Login')),
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

      await submitInvitationCode(tester, 'OPAQUENE');
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận lời mời tham gia tổ chức?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('invitation_confirm_sheet_accept')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('invitation_register_given_name')), findsOneWidget);
      expect(find.byKey(const Key('invitation_register_password')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('invitation_register_given_name')),
        'An',
      );
      await tester.enterText(
        find.byKey(const Key('invitation_register_family_name')),
        'Nguyen',
      );
      await tester.enterText(
        find.byKey(const Key('invitation_register_password')),
        'password1!',
      );
      await tester.enterText(
        find.byKey(const Key('invitation_register_confirm_password')),
        'password1!',
      );
      await tester.tap(find.byKey(const Key('invitation_accept_submit')));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.toString(), '/login');
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Đã tham gia tổ chức'), findsNothing);
    },
  );

  testWidgets(
    'e2e_e03_u03_fr01_03: invalid code stays on entry with a toast, no outcome page',
    (tester) async {
      await phone(tester);
      final module = FakeIamModule(
        scenario: FakeIamScenario.inspectInvalidNoLeak,
      );
      register(module);

      const raw = 'LEAKYSEC';
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationPageHarness(
            scenario: FakeIamScenario.inspectInvalidNoLeak,
          ).page,
        ),
      );
      await tester.pumpAndSettle();

      await submitInvitationCode(tester, raw);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Stays on the entry screen (input still present); never routes to the
      // blocked outcome page for an invalid code.
      expect(find.byKey(const Key('invitation_token_input')), findsOneWidget);
      expect(find.text('Không thể tiếp tục'), findsNothing);
      expect(find.text('Đã tham gia tổ chức'), findsNothing);
      // Generic, code-specific toast copy — never the raw token.
      expect(
        find.textContaining('Mã kích hoạt không hợp lệ'),
        findsOneWidget,
      );

      // Let the snackbar auto-dismiss timer fire so no timer stays pending.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'e2e_e03_u04_fr01_01: invitation detail → resend then revoke',
    (tester) async {
      await phone(tester);
      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.invitationResendOk),
      );
      register(module);

      final router = GoRouter(
        initialLocation: '/more/users/invitations/inv-1',
        routes: [
          GoRoute(
            path: '/more/users/invitations/:invitationId',
            builder: (context, state) => OrganizationInvitationDetailPage(
              invitationId: state.pathParameters['invitationId']!,
            invitations: IamModuleInvitationRepository(module),
              keyFactory: FakeIdempotencyKeyFactory(),
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

      expect(find.text('invitee@example.com'), findsOneWidget);

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi lại lời mời'));
      await tester.pumpAndSettle();
      expect(module.commandsOf<ResendInvitationCommand>(), hasLength(1));

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Thu hồi lời mời'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Không còn nhu cầu');
      await tester.tap(find.widgetWithText(VButton, 'Thu hồi lời mời'));
      await tester.pumpAndSettle();

      expect(module.commandsOf<RevokeInvitationCommand>(), hasLength(1));
    },
  );

  testWidgets(
    'e2e_e03_u05_fr01_01: member detail deactivate lifecycle',
    (tester) async {
      await phone(tester);
      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.memberDeactivateOk),
      );
      register(module);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationMemberDetailPage(
            membershipId: 'mem-staff-1',
            members: IamModuleMemberRepository(module),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thao tác'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạm ngừng thành viên'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(VButton, 'Tạm ngừng'));
      await tester.pumpAndSettle();

      expect(module.commandsOf<DeactivateMembershipCommand>(), hasLength(1));
    },
  );

  testWidgets(
    'e2e_e03_u05_fr01_02: last owner protected blocks destructive action',
    (tester) async {
      await phone(tester);
      final module = FakeIamModule(
        scenario: FakeIamScenario.memberLastOwnerProtected,
      );
      register(module);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationMemberDetailPage(
            membershipId: 'mem-owner-1',
            members: IamModuleMemberRepository(module),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sole owner UI hides destructive CTAs; still proves page wired to module.
      expect(find.text('Thao tác'), findsNothing);
    },
  );

  testWidgets(
    'e2e_e03_u01_fr01_02: permission denied on members list',
    (tester) async {
      await phone(tester);
      final module = FakeIamModule(
        scenario: FakeIamScenario.memberInvitationForbidden,
      );
      register(module);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: OrganizationUsersPage(
            members: IamModuleMemberRepository(module),
            invitations: IamModuleInvitationRepository(module),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lan Le'), findsNothing);
    },
  );
}
