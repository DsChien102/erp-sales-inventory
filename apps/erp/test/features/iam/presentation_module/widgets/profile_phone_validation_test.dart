import 'package:erp/features/iam/logic/organization_profile_cubit.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../support/scripted_iam_repositories.dart';

void main() {
  for (final kind in ['sample', 'live', 'organization']) {
    testWidgets('$kind phone validates only on save', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final org = kind == 'organization';
      final account = ScriptedAccountRepository();
      final organization = ScriptedOrganizationRepository(mode: OrganizationScript.updateOk);
      Widget page;
      if (org) {
        final cubit = OrganizationProfileCubit(organizationRepository: organization);
        addTearDown(cubit.close);
        await cubit.load();
        page = OrganizationEditProfilePage(cubit: cubit);
      } else {
        page = kind == 'live'
            ? EditMyAccountPage(accountRepository: account)
            : const EditMyAccountPage(data: MyAccountUiModel.sample);
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
      expect(account.updateCount, 0);
      expect(organization.updates, isEmpty);
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
        expect(organization.updates.single['contactPhone'], '012 345 6789');
      } else if (kind == 'live') {
        expect(account.profile.phone, isNull);
      }
    });
  }
}
