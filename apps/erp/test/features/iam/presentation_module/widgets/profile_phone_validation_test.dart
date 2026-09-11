import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/testing.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:erp/features/iam/testing.dart';
import 'package:vet45_shared_testing/shared_testing.dart';

void main() {
  for (final kind in ['sample', 'live', 'organization']) {
    testWidgets('$kind phone validates only on save', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final org = kind == 'organization';
      final module = RecordingIamModule(FakeIamModule(scenario: org ? FakeIamScenario.tenantProfileUpdateOk : FakeIamScenario.myAccountOk));
      Widget page;
      if (org) {
        final cubit = OrganizationProfileCubit(iamModule: module, executionContext: FakeExecutionContext(tenantId: 'org-001'));
        addTearDown(cubit.close);
        await cubit.load();
        page = OrganizationEditProfilePage(cubit: cubit);
      } else {
        page = kind == 'live' ? EditMyAccountPage(iamModule: module) : const EditMyAccountPage(data: MyAccountUiModel.sample);
      }
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pumpAndSettle();
      final phone = find.byType(TextField).at(org ? 1 : 2);
      await tester.enterText(phone, '12345678');
      await tester.pump();
      expect(find.text(VPhoneValidator.defaultInvalidMessage), findsNothing);
      await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
      await tester.pumpAndSettle();
      expect(find.text(VPhoneValidator.defaultInvalidMessage), findsOneWidget);
      expect(module.commandsOf<UpdateMyIdentityProfileCommand>(), isEmpty);
      expect(module.commandsOf<UpdateTenantProfileCommand>(), isEmpty);
      await tester.enterText(phone, '012 345 6789');
      await tester.pump();
      expect(find.text(VPhoneValidator.defaultInvalidMessage), findsNothing);
      await tester.enterText(phone, '+84123456789');
      expect(tester.widget<TextField>(phone).controller!.text, '012 345 6789');
      await tester.enterText(phone, '');
      await tester.pump();
      await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
      await tester.pumpAndSettle();
      if (org) {
        expect(find.text(VPhoneValidator.defaultRequiredMessage), findsOneWidget);
        await tester.enterText(phone, '012 345 6789');
        await tester.pump();
        expect(find.text(VPhoneValidator.defaultRequiredMessage), findsNothing);
        await tester.tap(find.widgetWithText(VButton, 'Lưu thay đổi'));
        await tester.pumpAndSettle();
        expect(module.commandsOf<UpdateTenantProfileCommand>().single.contactPhone, '012 345 6789');
      } else if (kind == 'live') {
        expect(module.commandsOf<UpdateMyIdentityProfileCommand>().single.phoneNumber, isNull);
      }
    });
  }
}
