import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:admin/features/iam/presentation/organization_profile/data/vn_administrative_units_loader.dart';
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
    VnAdministrativeUnit(
      code: '79',
      fullName: 'Thành phố Hồ Chí Minh',
      wards: [
        VnWard(code: '26734', fullName: 'Phường Bến Nghé', provinceCode: '79'),
      ],
    ),
    VnAdministrativeUnit(
      code: '48',
      fullName: 'Thành phố Đà Nẵng',
      wards: [
        VnWard(code: '20194', fullName: 'Phường Hải Châu', provinceCode: '48'),
      ],
    ),
  ];

  Widget buildTestApp({
    String? initialProvinceCode,
    String? initialCommuneCode,
    int initialTab = 0,
    void Function(VnAdministrativeUnitSelection? result)? onResult,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await showVnAdministrativeUnitPickerSheet(
                  context: context,
                  units: units,
                  initialProvinceCode: initialProvinceCode,
                  initialCommuneCode: initialCommuneCode,
                  initialTab: initialTab,
                );
                onResult?.call(result);
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders picker sheet with search and tabs', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Khu vực hành chính'), findsOneWidget);
    expect(find.byKey(const Key('input_unit_search')), findsOneWidget);
    expect(find.byKey(const Key('tab_picker_step_0')), findsOneWidget);
    expect(find.byKey(const Key('tab_picker_step_1')), findsOneWidget);
    expect(find.text('Thành phố Hà Nội'), findsOneWidget);
    expect(find.text('Thành phố Hồ Chí Minh'), findsOneWidget);
    expect(find.text('Thành phố Đà Nẵng'), findsOneWidget);
  });

  testWidgets('filters provinces using unaccented Vietnamese search', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input_unit_search')), 'ha noi');
    await tester.pumpAndSettle();

    expect(find.text('Thành phố Hà Nội'), findsOneWidget);
    expect(find.text('Thành phố Hồ Chí Minh'), findsNothing);
    expect(find.text('Thành phố Đà Nẵng'), findsNothing);
  });

  testWidgets('selecting province automatically switches to ward tab', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('item_province_01')));
    await tester.pumpAndSettle();

    // Ward list of Ha Noi should appear
    expect(find.byKey(const Key('list_wards')), findsOneWidget);
    expect(find.text('Phường Ba Đình'), findsOneWidget);
    expect(find.text('Xã Hát Môn'), findsOneWidget);
  });

  testWidgets('filters wards using unaccented search', (tester) async {
    await tester.pumpWidget(buildTestApp(
      initialProvinceCode: '01',
      initialTab: 1,
    ));
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('input_unit_search')), 'hat mon');
    await tester.pumpAndSettle();

    expect(find.text('Xã Hát Môn'), findsOneWidget);
    expect(find.text('Phường Ba Đình'), findsNothing);
  });

  testWidgets('selecting a ward returns selection and closes sheet', (tester) async {
    VnAdministrativeUnitSelection? selectedResult;

    await tester.pumpWidget(buildTestApp(
      onResult: (res) => selectedResult = res,
    ));
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Select Province
    await tester.tap(find.byKey(const Key('item_province_01')));
    await tester.pumpAndSettle();

    // Select Ward
    await tester.tap(find.byKey(const Key('item_ward_00010')));
    await tester.pumpAndSettle();

    expect(selectedResult, isNotNull);
    expect(selectedResult!.province.code, '01');
    expect(selectedResult!.province.fullName, 'Thành phố Hà Nội');
    expect(selectedResult!.ward?.code, '00010');
    expect(selectedResult!.ward?.fullName, 'Xã Hát Môn');
  });

  testWidgets('can switch back to province tab by tapping step 0', (tester) async {
    await tester.pumpWidget(buildTestApp(
      initialProvinceCode: '01',
      initialTab: 1,
    ));
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('list_wards')), findsOneWidget);

    // Tap Tab 0 to switch back
    await tester.tap(find.byKey(const Key('tab_picker_step_0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('list_provinces')), findsOneWidget);
  });

  testWidgets('does not overflow when software keyboard is open with 291px viewInsets', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 291);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Focus search input
    await tester.tap(find.byKey(const Key('input_unit_search')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('input_unit_search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
