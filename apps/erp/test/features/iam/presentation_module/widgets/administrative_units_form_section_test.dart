import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/iam/presentation/organization_profile/data/vn_administrative_units_loader.dart';
import 'package:erp/features/iam/presentation/organization_profile/widgets/administrative_units_form_section.dart';
import 'package:erp/features/iam/presentation/organization_profile/widgets/vn_administrative_unit_picker_sheet.dart';

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

  testWidgets('horizontal puts both fields on one row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: AdministrativeUnitsFormSection(
              unitsFuture: Future.value(units),
              direction: Axis.horizontal,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final provinceRect = tester.getRect(
      find.byKey(const Key('field_select_province')),
    );
    final wardRect = tester.getRect(
      find.byKey(const Key('field_select_ward')),
    );
    expect(provinceRect.top, wardRect.top);
    expect(wardRect.left - provinceRect.right, 20);
  });

  testWidgets('inputBorder uses borderInput only when enabled and valid', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: AdministrativeUnitsFormSection(
            unitsFuture: Future.value(units),
            inputBorder: true,
            provinceError: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final lightColors = VTheme.lightTheme.extension<VColorScheme>()!;
    final provinceBox = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('field_select_province')),
            matching: find.byType(Container),
          ),
        )
        .first;
    final dec = provinceBox.decoration! as BoxDecoration;
    expect(dec.border!.top.color, lightColors.borderInput);

    // Disabled ward does not use borderInput.
    final wardBox = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('field_select_ward')),
            matching: find.byType(Container),
          ),
        )
        .first;
    final wardDec = wardBox.decoration! as BoxDecoration;
    expect(wardDec.border!.top.color, isNot(lightColors.borderInput));

    // Invalid province uses danger, not borderInput.
    await tester.pumpWidget(
      MaterialApp(
        theme: VTheme.lightTheme,
        home: Scaffold(
          body: AdministrativeUnitsFormSection(
            unitsFuture: Future.value(units),
            inputBorder: true,
            provinceError: 'Lỗi tỉnh',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final invalidBox = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('field_select_province')),
            matching: find.byType(Container),
          ),
        )
        .first;
    final invalidDec = invalidBox.decoration! as BoxDecoration;
    expect(invalidDec.border!.top.color, lightColors.danger);
  });
}
