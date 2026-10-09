import 'package:erp/features/auth/data/models/invitation_token_inspection.dart';
import 'package:erp/features/auth/presentation/widgets/invitation_registration_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  for (final invalid in ['12345678', '123456789012', '\t0901234567', '+84901234567']) {
    testWidgets('registration rejects raw phone $invalid until corrected', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final submitted = <String?>[];
      await tester.pumpWidget(MaterialApp(theme: VTheme.lightTheme, home: InvitationRegistrationForm(
        inspection: InvitationTokenInspection(
          tenantId: 'org', tenantName: 'Clinic', inviteeEmail: 'a@example.com',
          initialRoleId: 'owner', initialRoleLabel: 'Owner', expiresAt: DateTime.utc(2026),
          accountExists: false, givenName: 'An', familyName: 'Nguyen', phone: invalid,
        ),
        isSubmitting: false,
        onRegister: ({required givenName, required familyName, phone, required password}) async { submitted.add(phone); },
      )));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('invitation_register_password')), 'Password123@');
      await tester.enterText(find.byKey(const Key('invitation_register_confirm_password')), 'Password123@');
      expect(find.text(VPhoneValidator.defaultInvalidMessage), findsNothing);
      await tester.tap(find.byKey(const Key('invitation_accept_submit')));
      await tester.pumpAndSettle();
      expect(submitted, isEmpty);
      expect(find.text(VPhoneValidator.defaultInvalidMessage), findsOneWidget);
      await tester.enterText(find.byKey(const Key('invitation_register_phone')), ' 090 123 4567 ');
      await tester.pump();
      expect(find.text(VPhoneValidator.defaultInvalidMessage), findsNothing);
      await tester.tap(find.byKey(const Key('invitation_accept_submit')));
      await tester.pumpAndSettle();
      expect(submitted, ['090 123 4567']);
    });
  }
}
