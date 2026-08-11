import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_presentation/src/organization_profile/data/vn_administrative_units_loader.dart';
import 'package:vet45_iam_presentation/src/widgets/platform_onboarding_step_organization.dart';

void main() {
  const units = <VnAdministrativeUnit>[
    VnAdministrativeUnit(
      code: '01',
      fullName: 'Thành phố Hà Nội',
      wards: [
        VnWard(
          code: '00004',
          fullName: 'Phường Ba Đình',
          provinceCode: '01',
        ),
      ],
    ),
    VnAdministrativeUnit(
      code: '75',
      fullName: 'Tỉnh Đồng Nai',
      wards: [
        VnWard(
          code: '26074',
          fullName: 'Phường Trấn Biên',
          provinceCode: '75',
        ),
      ],
    ),
  ];

  Widget buildTestableWidget({
    String? selectedProvince = 'Thành phố Hà Nội',
    String? selectedWard = 'Phường Trấn Biên',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: PlatformOnboardingStepOrganization(
            orgNameController: TextEditingController(),
            orgDisplayNameController: TextEditingController(),
            orgLegalNameController: TextEditingController(),
            orgTaxCodeController: TextEditingController(),
            orgPhoneController: TextEditingController(),
            orgEmailController: TextEditingController(),
            orgAddressController: TextEditingController(),
            selectedProvince: selectedProvince,
            selectedWard: selectedWard,
            administrativeUnitsFuture: Future.value(units),
            onProvinceChanged: (_) {},
            onWardChanged: (_) {},
            onOrgNameChanged: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('does not display a ward outside the selected province', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    expect(find.text('Thành phố Hà Nội'), findsOneWidget);
    expect(find.text('Phường Trấn Biên'), findsNothing);
    expect(find.text('Chọn xã / phường'), findsOneWidget);
  });
}
