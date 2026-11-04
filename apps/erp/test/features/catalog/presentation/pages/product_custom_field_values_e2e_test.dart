import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../catalog_e2e_harness.dart';

Finder _customFieldInput(String label) {
  return find.byWidgetPredicate((widget) => widget is VTextField && widget.label == label);
}

Future<void> _enterCustomFieldText(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = _customFieldInput(label);
  await tester.ensureVisible(field);
  await tester.enterText(
    find.descendant(of: field, matching: find.byType(TextField)),
    value,
  );
  await tester.pump();
}

Future<void> _openAmoxicillinFromDiscovery(WidgetTester tester) async {
  await tester.pumpWidget(buildCatalogDiscoveryRouter());
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Amoxicillin 500mg'));
  await tester.pumpAndSettle();
}

Future<void> _saveCustomFieldGroup(WidgetTester tester) async {
  await tester.tap(find.text('Lưu thay đổi'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('e2e_e03_u02_fr01_01: PCC shows custom field group cards', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.e2eCfValuesOk);

    await _openAmoxicillinFromDiscovery(tester);

    expect(find.byKey(const Key('wgt_e01_u02_fr01_01')), findsOneWidget);
    expect(find.text('Thông tin thuốc'), findsOneWidget);
    expect(find.text('Quy cách & bảo quản'), findsOneWidget);
    expect(find.textContaining('0/2 trường đã điền'), findsOneWidget);
    expect(find.textContaining('0/1 trường đã điền'), findsOneWidget);
  });

  testWidgets('e2e_e03_u02_fr02_01: save text custom field value and refresh PCC', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.e2eCfValuesSaveOk);

    await _openAmoxicillinFromDiscovery(tester);
    await tapEditCustomFieldGroup(tester, 'Thông tin thuốc');

    await _enterCustomFieldText(tester, 'Thành phần', 'Vitamin A, D, E');
    await _saveCustomFieldGroup(tester);

    expect(find.text('Thông tin thuốc'), findsOneWidget);
    expect(find.textContaining('1/3 trường đã điền'), findsOneWidget);
  });

  testWidgets('e2e_e03_u02_fr02_02: invalid number value shows field-level error', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.e2eCfValuesSaveOk);

    await _openAmoxicillinFromDiscovery(tester);
    await tapEditCustomFieldGroup(tester, 'Thông tin thuốc');

    await _enterCustomFieldText(tester, 'Thời gian ngưng sử dụng', '.');
    await _saveCustomFieldGroup(tester);

    expect(find.text('Thời gian ngưng sử dụng không đúng kiểu dữ liệu.'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsOneWidget);
  });

  testWidgets('e2e_e03_u02_fr03_01: optional field saves while required sibling empty', (
    tester,
  ) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.e2eCfValuesRequired);

    await _openAmoxicillinFromDiscovery(tester);
    await tapEditCustomFieldGroup(tester, 'Thông tin thuốc');

    await _enterCustomFieldText(tester, 'Chỉ định', 'Kháng sinh');
    await _saveCustomFieldGroup(tester);

    expect(find.text('Thông tin thuốc'), findsOneWidget);
    expect(find.textContaining('1/2 trường đã điền'), findsOneWidget);
    expect(find.text('Trường này là bắt buộc'), findsNothing);
    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
  });

  testWidgets('e2e_e03_u02_fr03_02: filling required custom field clears readiness blocker', (
    tester,
  ) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.e2eCfValuesRequired);

    await _openAmoxicillinFromDiscovery(tester);

    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
    expect(find.textContaining('Cần bổ sung'), findsOneWidget);

    await tapEditCustomFieldGroup(tester, 'Thông tin thuốc');
    await _enterCustomFieldText(tester, 'Thành phần', 'Vitamin A, D, E');
    await _saveCustomFieldGroup(tester);

    expect(find.text('Sẵn sàng bán'), findsOneWidget);
    expect(find.textContaining('1/2 trường đã điền'), findsOneWidget);
  });
}
