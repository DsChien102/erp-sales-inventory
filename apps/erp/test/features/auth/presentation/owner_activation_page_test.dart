import 'package:erp/features/auth/data/owner_activation_client.dart';
import 'package:erp/features/auth/presentation/bloc/owner_activation_cubit.dart';
import 'package:erp/features/auth/presentation/pages/owner_activation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

final class _RecordingClient implements OwnerActivationClient {
  String? inspectedCode;
  String? activatedCode;

  @override
  Future<OwnerActivationInspection> inspect(String code) async {
    inspectedCode = code;
    return const OwnerActivationInspection(
      valid: true,
      email: 'owner@example.com',
      givenName: 'An',
      familyName: 'Nguyen',
    );
  }

  @override
  Future<void> activate({
    required String code,
    required String email,
    required String password,
    required bool accountExists,
    String? givenName,
    String? familyName,
    String? phone,
    required String idempotencyKey,
  }) async {
    activatedCode = code;
  }
}

void main() {
  testWidgets(
    'OwnerActivationPage uses alphanumeric VVerificationCodeField length 8',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final client = _RecordingClient();
      final router = GoRouter(
        initialLocation: '/owner-activation',
        routes: [
          GoRoute(
            path: '/owner-activation',
            builder: (_, _) => OwnerActivationPage(
              cubit: OwnerActivationCubit(
                client: client,
                idempotencyKey: 'test-key',
              ),
            ),
          ),
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
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

      expect(find.byType(VVerificationCodeField), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('Mã kích hoạt'),
        ),
        findsOneWidget,
      );

      final submit = find.widgetWithText(VButton, 'Kích hoạt tài khoản');
      expect(tester.widget<VButton>(submit).onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, 'abcd2345');
      await tester.pump();
      expect(tester.widget<VButton>(submit).onPressed, isNull);

      await tester.enterText(
        find.descendant(
          of: find.byType(VPasswordField),
          matching: find.byType(TextField),
        ),
        'Password123!',
      );
      await tester.pump();

      expect(tester.widget<VButton>(submit).onPressed, isNotNull);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(client.inspectedCode, 'ABCD2345');
      expect(client.activatedCode, 'ABCD2345');
      expect(find.text('home'), findsOneWidget);
    },
  );
}
