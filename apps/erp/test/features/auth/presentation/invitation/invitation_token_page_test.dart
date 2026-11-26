import 'dart:async';

import 'package:erp/core/widgets/flow/flow_layout.dart';
import 'package:erp/features/auth/data/models/invitation_token_inspection.dart';
import 'package:erp/features/auth/logic/invitation_acceptance_state.dart';
import 'package:erp/features/auth/presentation/pages/invitation_token_page.dart';
import 'package:erp/features/auth/presentation/widgets/invitation_confirm_bottom_sheet.dart';
import 'package:erp/features/auth/presentation/widgets/invitation_outcome_view.dart';
import 'package:erp/features/auth/presentation/widgets/invitation_registration_form.dart';
import 'package:erp/features/auth/presentation/widgets/invitation_token_entry_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:erp/core/errors/app_exception.dart';
import '../../../iam/support/fake_iam_backend.dart';
import '../../../iam/support/iam_fixtures.dart';

import '../../support/scripted_auth.dart';
import '../../support/scripted_invitations.dart';

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
      final harness = InvitationPageHarness(
        scenario: FakeIamScenario.inspectExistingAccount,
      );
      final router = GoRouter(
        initialLocation: '/invitation',
        routes: <RouteBase>[
          GoRoute(
            path: '/invitation',
            builder: (_, _) => harness.page,
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
          home: InvitationPageHarness(
            scenario: FakeIamScenario.inspectExistingAccount,
          ).page,
        ),
      );
      await tester.pumpAndSettle();

      await _enterInvitationCode(tester, 'K7P29XQM');
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận lời mời tham gia tổ chức?'), findsOneWidget);
      expect(find.text('Mã lời mời hợp lệ.'), findsOneWidget);
      expect(find.text('Mậu Hiên'), findsOneWidget);
      expect(find.text('Nhân viên bán hàng'), findsOneWidget);
      expect(find.text('invitee@example.com'), findsOneWidget);
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

  testWidgets('expired invitation shows inline error and can be retried', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: InvitationPageHarness(scenario: FakeIamScenario.acceptExpired).page,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('invitation_token_submit')), findsOneWidget);
    await _enterInvitationCode(tester, 'TOKENEXP');
    await tester.pumpAndSettle();

    expect(find.textContaining('Mã lời mời đã hết hạn'), findsOneWidget);
    expect(find.byType(VToast), findsNothing);
    expect(find.byKey(const Key('invitation_token_submit')), findsOneWidget);
  });

  testWidgets('closing confirmation sheet leaves the continue action available', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: InvitationPageHarness(
          scenario: FakeIamScenario.inspectExistingAccount,
        ).page,
      ),
    );
    await tester.pumpAndSettle();

    await _enterInvitationCode(tester, 'K7P29XQM');
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận lời mời tham gia tổ chức?'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận lời mời tham gia tổ chức?'), findsNothing);

    await tester.tap(find.byKey(const Key('invitation_token_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận lời mời tham gia tổ chức?'), findsOneWidget);
  });

  testWidgets(
    'existing account confirm sheet accept executes accept and navigates to login with prefilledEmail',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final harness = InvitationPageHarness(
        scenario: FakeIamScenario.inspectExistingAccount,
      );
      Object? receivedExtra;
      final router = GoRouter(
        initialLocation: '/invitation',
        routes: <RouteBase>[
          GoRoute(
            path: '/invitation',
            builder: (_, _) => harness.page,
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
      expect(harness.invitations.accepts, hasLength(1));
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

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationPageHarness(
            scenario: FakeIamScenario.inspectExistingAccount,
            acceptError: const AppException(IamBlockedCodes.idempotencyConflict),
          ).page,
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
          home: InvitationPageHarness(
            scenario: FakeIamScenario.inspectNewAccount,
          ).page,
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
      // Mã lời mời đã chứng minh chủ email: không có bước nhập mã xác minh 6 số.
      expect(find.byType(VVerificationCodeField), findsNothing);
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
            inspection: InvitationTokenInspection(
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
        find.descendant(
          of: find.byKey(const Key('invitation_locked_email')),
          matching: find.text('dosychien9@gmail.com'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('invitation_locked_email')),
          matching: find.byType(TextField),
        ),
        findsNothing,
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
            builder: (_, _) => InvitationPageHarness(
              scenario: FakeIamScenario.registerAndAcceptOk,
            ).page,
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

  testWidgets('back is disabled while inspecting', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final completer = Completer<InvitationTokenInspection>();
    final invitations = _HangingInspectInvitations(completer);
    final router = GoRouter(
      initialLocation: '/invitation',
      routes: <RouteBase>[
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('LOGIN_PAGE')),
        ),
        GoRoute(
          path: '/invitation',
          builder: (_, _) => InvitationTokenPage(
            invitations: invitations,
            auth: ScriptedAuthRepository(),
            session: loginSession(email: 'invitee@example.com'),
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

    await _enterInvitationCode(tester, 'K7P29XQM');
    await tester.pump();

    await tester.tap(find.byTooltip('Quay lại'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('LOGIN_PAGE'), findsNothing);

    completer.complete(
      InvitationTokenInspection(
        tenantId: 'org-001',
        tenantName: 'Mậu Hiên',
        inviteeEmail: 'invitee@example.com',
        initialRoleId: 'role-staff',
        initialRoleLabel: 'Nhân viên bán hàng',
        expiresAt: DateTime.utc(2026, 8, 5),
        accountExists: true,
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('typing clears the server error', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: InvitationPageHarness(scenario: FakeIamScenario.acceptExpired).page,
      ),
    );
    await tester.pumpAndSettle();

    await _enterInvitationCode(tester, 'TOKENEXP');
    await tester.pumpAndSettle();
    expect(find.textContaining('Mã lời mời đã hết hạn'), findsOneWidget);

    await _enterInvitationCode(tester, 'TOKENEX');
    await tester.pump();
    expect(find.textContaining('Mã lời mời đã hết hạn'), findsNothing);
  });

  testWidgets('decline shows outcome', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: InvitationPageHarness(
          scenario: FakeIamScenario.inspectExistingAccount,
        ).page,
      ),
    );
    await tester.pumpAndSettle();

    await _enterInvitationCode(tester, 'K7P29XQM');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('invitation_confirm_sheet_decline')));
    await tester.pumpAndSettle();

    expect(find.text('Đã từ chối lời mời'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Nhập mã khác'), findsOneWidget);
  });

  testWidgets('passwords are cleared after a failed submit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: InvitationPageHarness(
          scenario: FakeIamScenario.registerAndAcceptOk,
          registerError: const AppException(AppErrorCode.unknown),
        ).page,
      ),
    );
    await tester.pumpAndSettle();

    await _enterInvitationCode(tester, 'TOKENNEW');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('invitation_confirm_sheet_accept')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('invitation_register_family_name')),
      'Nguyễn',
    );
    await tester.enterText(
      find.byKey(const Key('invitation_register_given_name')),
      'An',
    );
    await tester.enterText(
      find.byKey(const Key('invitation_register_phone')),
      '0912345678',
    );
    await tester.enterText(
      find.byKey(const Key('invitation_register_password')),
      'Password123@',
    );
    await tester.enterText(
      find.byKey(const Key('invitation_register_confirm_password')),
      'Password123@',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.tap(find.byKey(const Key('invitation_accept_submit')));
    await tester.pumpAndSettle();

    String fieldText(Key key) => tester
        .widget<TextField>(
          find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
        )
        .controller!
        .text;

    expect(fieldText(const Key('invitation_register_password')), isEmpty);
    expect(fieldText(const Key('invitation_register_confirm_password')), isEmpty);
    expect(fieldText(const Key('invitation_register_family_name')), 'Nguyễn');
    expect(fieldText(const Key('invitation_register_given_name')), 'An');
    expect(fieldText(const Key('invitation_register_phone')), '0912345678');
  });

  testWidgets('back returns to token entry', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: InvitationPageHarness(
          scenario: FakeIamScenario.inspectNewAccount,
        ).page,
      ),
    );
    await tester.pumpAndSettle();

    await _enterInvitationCode(tester, 'TOKENNEW');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('invitation_confirm_sheet_accept')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('invitation_register_given_name')), findsOneWidget);

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();

    expect(find.text('Nhập mã lời mời'), findsOneWidget);
  });

  testWidgets('enter other token returns to entry', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: InvitationPageHarness(
          scenario: FakeIamScenario.inspectExistingAccount,
        ).page,
      ),
    );
    await tester.pumpAndSettle();

    await _enterInvitationCode(tester, 'K7P29XQM');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('invitation_confirm_sheet_decline')));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(VButton, 'Nhập mã khác'));
    await tester.pumpAndSettle();

    expect(find.text('Nhập mã lời mời'), findsOneWidget);
  });

  group('10-8f Task 2 entry', () {
    testWidgets('390: split 4 + 4 cells, continue right under the hint', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationTokenEntryForm(
            isSubmitting: false,
            onInspect: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byKey(const Key('v-code-cell-0'))).height, 52);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.bottomNavigationBar, isNull);
    });

    testWidgets('1280: card 488 wide, 8 cells fill 446, continue inside the card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationTokenEntryForm(
            isSubmitting: false,
            onInspect: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(FlowCard)).width, 488);
      final left = tester.getTopLeft(find.byKey(const Key('v-code-cell-0'))).dx;
      final right = tester.getTopRight(find.byKey(const Key('v-code-cell-7'))).dx;
      expect(right - left, closeTo(448, 0.5));
      expect(
        find.descendant(
          of: find.byType(FlowCard),
          matching: find.byKey(const Key('invitation_token_submit')),
        ),
        findsOneWidget,
      );
    });

    testWidgets('resizing 900 → 700 keeps 5 typed characters and does not submit', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var inspected = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationTokenEntryForm(
            isSubmitting: false,
            onInspect: (_) => inspected = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _enterInvitationCode(tester, 'K7P29');
      tester.view.physicalSize = const Size(700, 800);
      await tester.pump();

      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('invitation_token_input')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        'K7P29',
      );
      expect(inspected, isFalse);
    });

    testWidgets('320 at text scale 2.0 does not overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2.0),
            ),
            child: child!,
          ),
          home: InvitationTokenEntryForm(
            isSubmitting: false,
            onInspect: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('10-8f Task 3 register', () {
    InvitationTokenInspection sampleInspection({
      String tenantName = 'Mậu Hiên',
      String email = 'invitee@example.com',
    }) {
      return InvitationTokenInspection(
        tenantId: 'org-001',
        tenantName: tenantName,
        inviteeEmail: email,
        initialRoleId: 'role-staff',
        initialRoleLabel: 'Nhân viên bán hàng',
        expiresAt: DateTime.utc(2026, 8, 5),
        accountExists: false,
      );
    }

    testWidgets('390: locked email is a read-only row', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationRegistrationForm(
            inspection: sampleInspection(email: 'lan@anphat.vn'),
            isSubmitting: false,
            onRegister: ({
              required givenName,
              required familyName,
              phone,
              required password,
            }) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final row = find.byKey(const Key('invitation_locked_email'));
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.text('lan@anphat.vn')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.byType(TextField)),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('Email, lan@anphat.vn, không sửa được'),
        findsOneWidget,
      );
    });

    testWidgets('1280: locked email is a disabled field', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationRegistrationForm(
            inspection: sampleInspection(email: 'dosychien9@gmail.com'),
            isSubmitting: false,
            onRegister: ({
              required givenName,
              required familyName,
              phone,
              required password,
            }) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('invitation_locked_email')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, 'dosychien9@gmail.com');
      expect(field.enabled, isFalse);
    });

    testWidgets('390: names share a row 3 : 2, submit right under the form', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationRegistrationForm(
            inspection: sampleInspection(),
            isSubmitting: false,
            onRegister: ({
              required givenName,
              required familyName,
              phone,
              required password,
            }) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final familyRect = tester.getRect(
        find.byKey(const Key('invitation_register_family_name')),
      );
      final givenRect = tester.getRect(
        find.byKey(const Key('invitation_register_given_name')),
      );
      expect(familyRect.top, closeTo(givenRect.top, 2));
      expect(familyRect.width / givenRect.width, closeTo(1.5, 0.1));
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar,
        isNull,
      );
    });

    testWidgets('390: keyboard open, submit can be scrolled into view', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 327);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationRegistrationForm(
            inspection: sampleInspection(),
            isSubmitting: false,
            onRegister: ({
              required givenName,
              required familyName,
              phone,
              required password,
            }) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final submit = find.byKey(const Key('invitation_accept_submit'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      expect(submit.hitTestable(), findsOneWidget);
    });

    testWidgets('1280: banner then card 488, bottom bar content 488', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationRegistrationForm(
            inspection: sampleInspection(),
            isSubmitting: false,
            onRegister: ({
              required givenName,
              required familyName,
              phone,
              required password,
            }) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bannerY = tester.getTopLeft(find.byType(VBanner)).dy;
      final cardY = tester.getTopLeft(find.byType(FlowCard)).dy;
      expect(bannerY, lessThan(cardY));
      expect(tester.getSize(find.byType(FlowCard)).width, 488);
      expect(
        tester
            .getSize(find.byKey(const Key('invitation_accept_submit')))
            .width,
        488,
      );
    });

    testWidgets('resizing keeps every typed value', (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationRegistrationForm(
            inspection: sampleInspection(),
            isSubmitting: false,
            onRegister: ({
              required givenName,
              required familyName,
              phone,
              required password,
            }) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('invitation_register_family_name')),
        'Nguyễn',
      );
      await tester.enterText(
        find.byKey(const Key('invitation_register_given_name')),
        'Bình',
      );
      await tester.enterText(
        find.byKey(const Key('invitation_register_phone')),
        '0912345678',
      );
      await tester.enterText(
        find.byKey(const Key('invitation_register_password')),
        'Abc@12345',
      );
      await tester.enterText(
        find.byKey(const Key('invitation_register_confirm_password')),
        'Abc@12345',
      );

      tester.view.physicalSize = const Size(700, 800);
      await tester.pump();

      String textOf(Key key) => tester
          .widget<TextField>(
            find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
          )
          .controller!
          .text;

      expect(textOf(const Key('invitation_register_family_name')), 'Nguyễn');
      expect(textOf(const Key('invitation_register_given_name')), 'Bình');
      expect(textOf(const Key('invitation_register_phone')), '0912345678');
      expect(textOf(const Key('invitation_register_password')), 'Abc@12345');
      expect(
        textOf(const Key('invitation_register_confirm_password')),
        'Abc@12345',
      );
    });

    testWidgets(
      '320 at text scale 2.0, 80-char tenant and 60-char email do not overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final longTenant = 'Cửa hàng ' * 9;
        final longEmail = '${'a' * 48}@example.com';
        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2.0),
              ),
              child: child!,
            ),
            home: InvitationRegistrationForm(
              inspection: sampleInspection(
                tenantName: longTenant,
                email: longEmail,
              ),
              isSubmitting: false,
              onRegister: ({
                required givenName,
                required familyName,
                phone,
                required password,
              }) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });

  group('10-8f Task 4 confirm & outcome', () {
    InvitationTokenInspection sampleConfirmInspection() {
      return InvitationTokenInspection(
        tenantId: 'org-001',
        tenantName: 'Mậu Hiên',
        inviteeEmail: 'invitee@example.com',
        initialRoleId: 'role-staff',
        initialRoleLabel: 'Nhân viên bán hàng',
        expiresAt: DateTime.utc(2026, 8, 5),
        accountExists: true,
      );
    }

    testWidgets('390: confirm sheet shows a filled box with three rows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showInvitationConfirmBottomSheet(
                  context: context,
                  inspection: sampleConfirmInspection(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final bgColor =
          tester.element(find.text('Xác nhận lời mời tham gia tổ chức?')).vColors.background;
      final boxFinder = find.ancestor(
        of: find.text('Mậu Hiên'),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color == bgColor,
        ),
      );
      expect(boxFinder, findsOneWidget);
      final valueWidget = tester.widget<Text>(find.text('Mậu Hiên'));
      expect(valueWidget.textAlign, TextAlign.right);
    });

    testWidgets('1280: confirm dialog keeps the 72-wide labels', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showInvitationConfirmBottomSheet(
                  context: context,
                  inspection: sampleConfirmInspection(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final labelBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.text('Tổ chức'),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(labelBox.width, 72);
    });

    testWidgets(
      '390: declined uses the neutral icon, blocked the warning icon, action at the bottom',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: InvitationOutcomeView(
              step: InvitationAcceptanceStep.declined,
              onEnterOtherToken: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FlowIcon), findsOneWidget);
        expect(
          tester.widget<VIcon>(find.byType(VIcon)).icon,
          VIcons.close,
        );
        expect(
          tester.getTopLeft(find.widgetWithText(VButton, 'Nhập mã khác')).dy,
          greaterThan(700),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: VTheme.lightTheme,
            home: InvitationOutcomeView(
              step: InvitationAcceptanceStep.blocked,
              onEnterOtherToken: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.widget<VIcon>(find.byType(VIcon)).icon,
          VIcons.warning,
        );
      },
    );

    testWidgets('1280: outcome is top aligned within 480', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: InvitationOutcomeView(
            step: InvitationAcceptanceStep.declined,
            onEnterOtherToken: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('Đã từ chối lời mời')).dy, lessThan(100));
      expect(
        tester.getSize(find.widgetWithText(VButton, 'Nhập mã khác')).width,
        lessThanOrEqualTo(480),
      );
    });

    testWidgets('320 at text scale 2.0: confirm sheet scrolls to decline', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2.0),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showInvitationConfirmBottomSheet(
                  context: context,
                  inspection: sampleConfirmInspection(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final decline = find.byKey(const Key('invitation_confirm_sheet_decline'));
      await tester.ensureVisible(decline);
      await tester.pumpAndSettle();
      expect(decline.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _HangingInspectInvitations extends ScriptedInvitations {
  _HangingInspectInvitations(this.completer)
    : super(scenario: FakeIamScenario.inspectExistingAccount);

  final Completer<InvitationTokenInspection> completer;

  @override
  Future<InvitationTokenInspection> inspect(String token) => completer.future;
}
