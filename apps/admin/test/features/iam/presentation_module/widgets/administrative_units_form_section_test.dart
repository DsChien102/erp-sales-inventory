import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/iam/presentation/organization_profile/data/vn_administrative_units_loader.dart';
import 'package:admin/features/iam/presentation/organization_profile/widgets/administrative_units_form_section.dart';
import 'package:admin/features/iam/presentation/organization_profile/widgets/vn_administrative_unit_picker_sheet.dart';

void main() {
  const units = <VnAdministrativeUnit>[
    VnAdministrativeUnit(
      code: '01',
      fullName: 'Thành phố Hà Nội',
      wards: [
        VnWard(code: '00004', fullName: 'Phường Ba Đình', provinceCode: '01'),
        VnWard(code: '00010', fullName: 'Xã Hát Môn', provinceCode: '01'),
      ],
    ),
  ];

  Widget buildSection({
    String? provinceCode,
    String? communeCode,
    ValueChanged<String?>? onProvinceChanged,
    ValueChanged<String?>? onCommuneChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AdministrativeUnitsFormSection(
              unitsFuture: Future.value(units),
              selectedProvinceCode: provinceCode,
              selectedCommuneCode: communeCode,
              onProvinceChanged: onProvinceChanged ?? (_) {},
              onCommuneChanged: onCommuneChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders empty state correctly when unselected', (tester) async {
    await tester.pumpWidget(buildSection());
    await tester.pumpAndSettle();

    expect(find.text('Tỉnh / thành phố'), findsOneWidget);
    expect(find.text('Chọn tỉnh / thành phố'), findsOneWidget);
    expect(find.text('Xã / phường'), findsOneWidget);
    expect(find.text('Chọn tỉnh / thành phố trước'), findsOneWidget);
  });

  testWidgets('renders selected province and ward', (tester) async {
    await tester.pumpWidget(buildSection(
      provinceCode: '01',
      communeCode: '00010',
    ));
    await tester.pumpAndSettle();

    expect(find.text('Thành phố Hà Nội'), findsOneWidget);
    expect(find.text('Xã Hát Môn'), findsOneWidget);
    expect(find.byKey(const Key('field_select_province_clear')), findsOneWidget);
    expect(find.byKey(const Key('field_select_ward_clear')), findsOneWidget);
  });

  testWidgets('clearing province resets both province and commune', (tester) async {
    String? clearedProvince;
    String? clearedCommune;

    await tester.pumpWidget(buildSection(
      provinceCode: '01',
      communeCode: '00010',
      onProvinceChanged: (v) => clearedProvince = v,
      onCommuneChanged: (v) => clearedCommune = v,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('field_select_province_clear')));
    await tester.pumpAndSettle();

    expect(clearedProvince, isNull);
    expect(clearedCommune, isNull);
  });

  testWidgets('clearing ward resets only commune', (tester) async {
    String? clearedCommune = 'not_called';

    await tester.pumpWidget(buildSection(
      provinceCode: '01',
      communeCode: '00010',
      onCommuneChanged: (v) => clearedCommune = v,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('field_select_ward_clear')));
    await tester.pumpAndSettle();

    expect(clearedCommune, isNull);
  });

  testWidgets('tapping province field opens picker bottom sheet', (tester) async {
    await tester.pumpWidget(buildSection());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('field_select_province')));
    await tester.pumpAndSettle();

    expect(find.byType(VnAdministrativeUnitPickerSheet), findsOneWidget);
    expect(find.text('Khu vực hành chính'), findsOneWidget);
  });
}
