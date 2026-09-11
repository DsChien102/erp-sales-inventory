import 'package:erp/features/auth/presentation/pages/invitation_token_page.dart';
import 'package:erp/features/auth/presentation/widgets/invitation_registration_form.dart';
import 'package:erp/features/auth/presentation/widgets/invitation_token_entry_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_application/application.dart';

Future<void> _enterInvitationCode(WidgetTester tester, String code) async {
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

void main() {
  testWidgets(
    'token stays out of route URI while typing opaque invitation token',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const rawToken = 'K7P29XQM';
      final module = FakeIamModule(
        scenario: FakeIamScenario.inspectExistingAccount,
      );
      final router = GoRouter(
        initialLocation: '/invitation',
        routes: <RouteBase>[
          GoRoute(
            path: '/invitation',
            builder: (_, _) => InvitationTokenPage(iamModule: module),
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

      await _enterInvitationCode(tester, rawToken);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/invitation',
      );
      expect(
        router.routeInformationProvider.value.uri.toString(),
        isNot(contains(rawToken)),
      );
    },
  );

  testWidgets(
    'wgt_e03_u03_fr01_01: existing account shows confirmation bottom sheet',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationTokenPage(
            iamModule: FakeIamModule(
              scenario: FakeIamScenario.inspectExistingAccount,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _enterInvitationCode(tester, 'K7P29XQM');
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận lời mời tham gia tổ chức?'), findsOneWidget);
      expect(find.text('Mã kích hoạt đã hợp lệ.'), findsOneWidget);
      expect(
        find.byKey(const Key('invitation_confirm_sheet_accept')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('invitation_confirm_sheet_decline')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'existing account confirm sheet accept executes accept and navigates to login with prefilledEmail',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = RecordingIamModule(
        FakeIamModule(scenario: FakeIamScenario.inspectExistingAccount),
      );
      Object? receivedExtra;
      final router = GoRouter(
        initialLocation: '/invitation',
        routes: <RouteBase>[
          GoRoute(
            path: '/invitation',
            builder: (_, _) => InvitationTokenPage(iamModule: module),
          ),
          GoRoute(
            path: '/login',
            builder: (_, state) {
              receivedExtra = state.extra;
              return const Scaffold(body: Text('LOGIN_PAGE'));
            },
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

      await _enterInvitationCode(tester, 'K7P29XQM');
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận lời mời tham gia tổ chức?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('invitation_confirm_sheet_accept')));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN_PAGE'), findsOneWidget);
      expect(module.commandsOf<AcceptInvitationCommand>(), hasLength(1));
      expect(receivedExtra, isA<Map<String, dynamic>>());
      final map = receivedExtra as Map<String, dynamic>;
      expect(map['prefilledEmail'], 'invitee@example.com');
      expect(map['showSuccessBanner'], true);
      expect(map['organizationName'], 'Mậu Hiên');
    },
  );

  testWidgets(
    'existing account confirm sheet accept failure shows danger toast and does not reopen bottom sheet',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final module = _FailAcceptModule();
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationTokenPage(iamModule: module),
        ),
      );
      await tester.pumpAndSettle();

      await _enterInvitationCode(tester, 'K7P29XQM');
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận lời mời tham gia tổ chức?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('invitation_confirm_sheet_accept')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(VToast), findsOneWidget);
      expect(tester.widget<VToast>(find.byType(VToast)).type, VToastType.danger);
      expect(tester.widget<VToast>(find.byType(VToast)).title, 'Không hoàn tất');
      expect(find.text('Xác nhận lời mời tham gia tổ chức?'), findsNothing);
      expect(find.byKey(const Key('invitation_confirm_sheet_accept')), findsNothing);
    },
  );

  testWidgets(
    'new account path shows registration fields without editable email',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationTokenPage(
            iamModule: FakeIamModule(
              scenario: FakeIamScenario.inspectNewAccount,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _enterInvitationCode(tester, 'TOKENNEW');
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận lời mời tham gia tổ chức?'), findsOneWidget);
      expect(
        find.byKey(const Key('invitation_confirm_sheet_accept')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('invitation_confirm_sheet_accept')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('invitation_register_given_name')), findsOneWidget);
      expect(find.byKey(const Key('invitation_register_family_name')), findsOneWidget);
      expect(find.byKey(const Key('invitation_register_phone')), findsOneWidget);
      expect(find.byKey(const Key('invitation_register_password')), findsOneWidget);
      expect(find.byKey(const Key('invitation_locked_email')), findsOneWidget);
    },
  );

  testWidgets(
    'new account registration pre-fills invitation profile but keeps name fields editable',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationRegistrationForm(
            inspection: InvitationTokenInspectionDto(
              tenantId: 'org-001',
              tenantName: 'Dschien',
              inviteeEmail: 'dosychien9@gmail.com',
              initialRoleId: 'store_owner',
              initialRoleLabel: 'Chủ sở hữu',
              expiresAt: DateTime.utc(2026, 8, 18),
              accountExists: false,
              givenName: 'Chiến',
              familyName: 'Đỗ Sỹ',
              phone: '0901234567',
            ),
            isSubmitting: false,
            onRegister:
                ({
                  required givenName,
                  required familyName,
                  phone,
                  required password,
                }) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(
                  const Key('invitation_register_family_name'),
                ),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        'Đỗ Sỹ',
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(
                  const Key('invitation_register_given_name'),
                ),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        'Chiến',
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('invitation_register_phone')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        '0901234567',
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('invitation_locked_email')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        'dosychien9@gmail.com',
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('invitation_locked_email')),
                matching: find.byType(TextField),
              ),
            )
            .enabled,
        isFalse,
      );
    },
  );

  testWidgets('code field uses alphanumeric verification cells and uppercases', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? inspected;
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: InvitationTokenEntryForm(
          isSubmitting: false,
          onInspect: (token) => inspected = token,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VVerificationCodeField), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Mã lời mời'),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Mã không phân biệt chữ hoa và chữ thường.'),
      findsOneWidget,
    );

    await _enterInvitationCode(tester, 'k7p29xqm');
    await tester.pumpAndSettle();

    expect(inspected, 'K7P29XQM');
    final textField = find.descendant(
      of: find.byKey(const Key('invitation_token_input')),
      matching: find.byType(TextField),
    );
    expect(textField, findsOneWidget);
    expect(tester.widget<TextField>(textField).controller!.text, 'K7P29XQM');
  });

  testWidgets(
    'new account registration success shows success toast and navigates',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Object? receivedExtra;
      final router = GoRouter(
        initialLocation: '/invitation',
        routes: <RouteBase>[
          GoRoute(
            path: '/invitation',
            builder: (_, _) => InvitationTokenPage(
              iamModule: FakeIamModule(
                scenario: FakeIamScenario.registerAndAcceptOk,
              ),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (_, state) {
              receivedExtra = state.extra;
              return const Scaffold(body: Text('LOGIN_PAGE'));
            },
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

      await _enterInvitationCode(tester, 'TOKENNEW');
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận lời mời tham gia tổ chức?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('invitation_confirm_sheet_accept')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('invitation_register_family_name')),
        'Đỗ Sỹ',
      );
      await tester.enterText(
        find.byKey(const Key('invitation_register_given_name')),
        'Chiến',
      );
      await tester.enterText(
        find.byKey(const Key('invitation_register_password')),
        'Password123@',
      );
      await tester.enterText(
        find.byKey(const Key('invitation_register_confirm_password')),
        'Password123@',
      );

      await tester.tap(find.byKey(const Key('invitation_accept_submit')));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN_PAGE'), findsOneWidget);
      expect(receivedExtra, isA<Map<String, dynamic>>());
      final map = receivedExtra as Map<String, dynamic>;
      expect(map['organizationName'], 'Mậu Hiên');
      expect(map['showSuccessBanner'], true);
    },
  );
}

final class _FailAcceptModule implements IIamModule {
  @override
  Future<TResult> executeCommandAsync<TResult>(ICommand<TResult> command) {
    if (command is AcceptInvitationCommand) {
      throw const IamBlockedException(IamBlockedCodes.idempotencyConflict);
    }
    throw UnsupportedError(command.runtimeType.toString());
  }

  @override
  Future<TResult> executeQueryAsync<TResult>(IQuery<TResult> query) {
    if (query is InspectInvitationTokenQuery) {
      return Future.value(
        InvitationTokenInspectionDto(
          tenantId: 'org-001',
          tenantName: 'Org',
          inviteeEmail: 'invitee@example.com',
          initialRoleId: 'role-staff',
          initialRoleLabel: 'Staff',
          expiresAt: DateTime.utc(2026, 8, 5),
          accountExists: true,
        ) as TResult,
      );
    }
    throw UnsupportedError(query.runtimeType.toString());
  }
}
