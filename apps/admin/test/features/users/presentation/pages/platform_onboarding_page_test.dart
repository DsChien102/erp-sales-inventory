import 'package:admin/features/organizations/presentation/pages/platform_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';

/// wgt_e01_u03_fr01_01 — Onboarding wizard via IIamModule.
void main() {
  testWidgets('shows owner step and search results from FakeIamModule', (
    WidgetTester tester,
  ) async {
    final module = FakeIamModule(
      scenario: FakeIamScenario.onboardingExistingUserOk,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformOnboardingPage(iamModule: module),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khởi tạo tổ chức'), findsOneWidget);

    await tester.tap(find.byType(VSearchBar));
    await tester.pumpAndSettle();

    expect(find.text('Lê Thị Lan'), findsWidgets);
  });

  testWidgets('validation blocks next without owner selection', (
    WidgetTester tester,
  ) async {
    final module = FakeIamModule();

    await tester.pumpWidget(
      MaterialApp(
        home: PlatformOnboardingPage(iamModule: module),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    expect(find.textContaining('chủ sở hữu'), findsWidgets);
  });
}
