import 'package:erp/features/auth/presentation/pages/invitation_token_page.dart';
import 'package:erp/features/auth/presentation/widgets/invitation_token_entry_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';

Future<void> _enterInvitationCode(WidgetTester tester, String code) async {
  expect(find.byType(VVerificationCodeField), findsOneWidget);
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('invitation_token_input')),
      matching: find.byType(TextField),
    ).first,
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
    'wgt_e03_u03_fr01_01: existing account shows locked email and accept CTA',
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
      final submit = find.byKey(const Key('invitation_inspect_submit'));
      if (submit.evaluate().isNotEmpty) {
        final button = tester.widget<VButton>(submit);
        if (button.onPressed != null) {
          await tester.tap(submit);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byKey(const Key('invitation_locked_email')), findsOneWidget);
      expect(
        find.byKey(const Key('invitation_existing_password')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('invitation_accept_submit')), findsOneWidget);
      expect(find.text('invitee@example.com'), findsOneWidget);
      expect(find.text('K7P29XQM'), findsNothing);
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
      final submit = find.byKey(const Key('invitation_inspect_submit'));
      if (submit.evaluate().isNotEmpty) {
        final button = tester.widget<VButton>(submit);
        if (button.onPressed != null) {
          await tester.tap(submit);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byKey(const Key('invitation_register_given_name')), findsOneWidget);
      expect(find.byKey(const Key('invitation_register_family_name')), findsOneWidget);
      expect(find.byKey(const Key('invitation_register_phone')), findsOneWidget);
      expect(find.byKey(const Key('invitation_register_password')), findsOneWidget);
      expect(find.byKey(const Key('invitation_locked_email')), findsOneWidget);
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
        (w) =>
            w is RichText &&
            w.text.toPlainText().contains('Mã lời mời'),
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
    final cells = find.descendant(
      of: find.byKey(const Key('invitation_token_input')),
      matching: find.byType(TextField),
    );
    expect(cells, findsNWidgets(8));
    expect(tester.widget<TextField>(cells.at(0)).controller!.text, 'K');
    expect(tester.widget<TextField>(cells.at(7)).controller!.text, 'M');
  });
}
