import 'package:admin/features/organizations/presentation/pages/platform_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';

void main() {
  testWidgets('owner and organization phones validate on next and again on submit', (tester) async {
    await tester.pumpWidget(MaterialApp(home: PlatformOnboardingPage(
      iamModule: FakeIamModule(scenario: FakeIamScenario.onboardingNewUserOk),
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo mới'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Nguyen');
    await tester.enterText(find.byType(TextField).at(1), 'An');
    await tester.enterText(find.byType(TextField).at(2), 'new@example.com');
    final ownerPhone = tester.widget<TextField>(find.byType(TextField).at(3)).controller!;
    ownerPhone.text = '12345678';
    await tester.pump();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('Tên tổ chức'), findsNothing);
    expect(find.text(VPhoneValidator.defaultInvalidMessage), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(3), '090 123 4567');
    await tester.pump();
    expect(find.text(VPhoneValidator.defaultInvalidMessage), findsNothing);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Phong kham');
    final orgPhone = tester.widget<TextField>(find.byType(TextField).at(1)).controller!;
    orgPhone.text = '\t0901234567';
    await tester.pump();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text(VPhoneValidator.defaultInvalidMessage), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), '');
    await tester.pump();
    expect(find.text(VPhoneValidator.defaultInvalidMessage), findsNothing);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    // Controllers may change after next; the final callback must revalidate.
    ownerPhone.text = '123456789012';
    await tester.tap(find.widgetWithText(VButton, 'Khởi tạo tổ chức'));
    await tester.pumpAndSettle();
    expect(find.text(VPhoneValidator.defaultInvalidMessage), findsOneWidget);
    expect(find.text('Nhập họ và tên đệm'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(3), '');
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    orgPhone.text = '123456789012';
    await tester.tap(find.widgetWithText(VButton, 'Khởi tạo tổ chức'));
    await tester.pumpAndSettle();
    expect(find.text(VPhoneValidator.defaultInvalidMessage), findsOneWidget);
    expect(find.text('Tên tổ chức'), findsOneWidget);
  });
}
