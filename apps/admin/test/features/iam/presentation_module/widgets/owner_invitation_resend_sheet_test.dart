import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:admin/features/iam/presentation/organizations/widgets/owner_invitation_resend_sheet.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required String initialEmail,
    required Future<bool> Function(String email) onSubmit,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OwnerInvitationResendSheet(
            initialEmail: initialEmail,
            onSubmit: onSubmit,
          ),
        ),
      ),
    );
  }

  testWidgets('prefill email and copy, Hủy closes without submit', (tester) async {
    var submitted = false;
    await pumpSheet(
      tester,
      initialEmail: 'owner@example.com',
      onSubmit: (email) async {
        submitted = true;
        return true;
      },
    );

    expect(find.text('Gửi lại email thiết lập?'), findsOneWidget);
    expect(find.text('owner@example.com'), findsOneWidget);
    expect(find.widgetWithText(VButton, 'Gửi'), findsOneWidget);

    await tester.tap(find.widgetWithText(VButton, 'Hủy'));
    await tester.pumpAndSettle();

    expect(submitted, isFalse);
    expect(find.byType(OwnerInvitationResendSheet), findsNothing);
  });

  testWidgets('invalid email disables Gửi', (tester) async {
    await pumpSheet(
      tester,
      initialEmail: 'owner@example.com',
      onSubmit: (_) async => true,
    );

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.pump();

    final sendButton = tester.widget<VButton>(find.widgetWithText(VButton, 'Gửi'));
    expect(sendButton.onPressed, isNull);
  });

  testWidgets('submit same email returns canonical lowercase', (tester) async {
    String? received;
    await pumpSheet(
      tester,
      initialEmail: 'Owner@Example.com',
      onSubmit: (email) async {
        received = email;
        return true;
      },
    );

    await tester.tap(find.widgetWithText(VButton, 'Gửi'));
    await tester.pumpAndSettle();

    expect(received, 'owner@example.com');
    expect(find.byType(OwnerInvitationResendSheet), findsNothing);
  });

  testWidgets('submit changed email and keep sheet open on failure', (tester) async {
    String? received;
    await pumpSheet(
      tester,
      initialEmail: 'owner@example.com',
      onSubmit: (email) async {
        received = email;
        return false;
      },
    );

    await tester.enterText(find.byType(TextField), 'new@example.com');
    await tester.pump();
    await tester.tap(find.widgetWithText(VButton, 'Gửi'));
    await tester.pumpAndSettle();

    expect(received, 'new@example.com');
    expect(find.byType(OwnerInvitationResendSheet), findsOneWidget);
    expect(find.text('new@example.com'), findsOneWidget);
  });
}
