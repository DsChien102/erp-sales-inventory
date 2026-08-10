import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:vet45_iam_presentation/presentation.dart';
import 'package:vet45_iam_presentation/testing.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  testWidgets('wgt_e02_u03_fr01_01: legal form does not use endsWith 999 simulation', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final module = RecordingIamModule(
      FakeIamModule(scenario: FakeIamScenario.tenantProfileOk),
    );
    final cubit = OrganizationProfileCubit(
      iamModule: module,
      executionContext: FakeExecutionContext(tenantId: 'org-001'),
    );
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: OrganizationLegalProfileFormPage(cubit: cubit),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chỉnh hồ sơ pháp lý'), findsOneWidget);
    expect(find.text('Lưu hồ sơ'), findsOneWidget);

    // Tax code ending with 999 must not auto-open mock duplicate sheet.
    final taxFields = find.byType(TextField);
    expect(taxFields, findsWidgets);
    await tester.enterText(taxFields.at(1), '0123456999');
    await tester.tap(find.widgetWithText(VButton, 'Lưu hồ sơ'));
    await tester.pumpAndSettle();

    expect(find.text('Mã số thuế đã được ghi nhận'), findsNothing);
    expect(module.commandsOf<UpsertLegalProfileCommand>(), hasLength(1));
    await cubit.close();
  });
}
