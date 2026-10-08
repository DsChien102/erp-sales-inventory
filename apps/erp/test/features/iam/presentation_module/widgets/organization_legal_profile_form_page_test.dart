import 'package:erp/features/iam/logic/organization_profile_cubit.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/scripted_iam_repositories.dart';

void main() {
  testWidgets('wgt_e02_u03_fr01_01: legal form does not use endsWith 999 simulation', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = ScriptedOrganizationRepository();
    final cubit = OrganizationProfileCubit(organizationRepository: repository);
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
    expect(repository.upserts, hasLength(1));
    await cubit.close();
  });
}
