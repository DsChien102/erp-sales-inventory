import 'package:erp/features/auth/presentation/pages/invitation_token_page.dart';
import 'package:erp/features/auth/presentation/widgets/invitation_token_entry_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';

void main() {
  testWidgets(
    'token stays out of route URI while typing opaque invitation token',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const rawToken = 'opaque-invite-token';
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

      await tester.enterText(
        find.byKey(const Key('invitation_token_input')),
        rawToken,
      );
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

      await tester.enterText(
        find.byKey(const Key('invitation_token_input')),
        'valid-token',
      );
      await tester.tap(find.byKey(const Key('invitation_inspect_submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('invitation_locked_email')), findsOneWidget);
      expect(
        find.byKey(const Key('invitation_existing_password')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('invitation_accept_submit')), findsOneWidget);
      expect(find.text('invitee@example.com'), findsOneWidget);
      expect(find.text('valid-token'), findsNothing);
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

      await tester.enterText(
        find.byKey(const Key('invitation_token_input')),
        'token-new',
      );
      await tester.tap(find.byKey(const Key('invitation_inspect_submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('invitation_register_given_name')), findsOneWidget);
      expect(find.byKey(const Key('invitation_register_family_name')), findsOneWidget);
      expect(find.byKey(const Key('invitation_register_phone')), findsOneWidget);
      expect(find.byKey(const Key('invitation_register_password')), findsOneWidget);
      expect(find.byKey(const Key('invitation_locked_email')), findsOneWidget);
    },
  );

  testWidgets('code field upcases input and shows the new hint', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: InvitationTokenEntryForm(isSubmitting: false, onInspect: (_) {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('VD: K7P29XQM'), findsOneWidget);
    expect(find.text('Mã không phân biệt chữ hoa và chữ thường.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('invitation_token_input')),
      'k7p2-9xqm',
    );
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'K7P2-9XQM',
    );
  });
}
