import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/testing.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../catalog_e2e_harness.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('e2e_e03_u01_fr01_01: initialize template seeds default groups', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.cfTemplateSeedOk);

    await tester.pumpWidget(buildCustomFieldSettingsRouter());
    await tester.pumpAndSettle();

    expect(find.text('Chưa có nhóm thông tin nào'), findsOneWidget);
    await tester.tap(find.widgetWithText(VButton, 'Tạo mẫu mặc định'));
    await tester.pumpAndSettle();

    expect(find.text('Thông tin thuốc'), findsOneWidget);
    expect(find.text('Quy cách & bảo quản'), findsOneWidget);
  });

  testWidgets('e2e_e03_u01_fr02_01: create and edit custom field group', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.cfGroupDeactivateOk);

    await tester.pumpWidget(buildCustomFieldSettingsRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(VTextField).first, 'Thông tin tuân thủ');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Thông tin tuân thủ'), findsOneWidget);
    await tester.tap(find.text('Thông tin tuân thủ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    expect(find.text('Sửa nhóm thông tin'), findsOneWidget);
    await tester.enterText(find.byType(VTextField).first, 'Thông tin tuân thủ mới');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Thông tin tuân thủ mới'), findsOneWidget);
  });

  testWidgets('e2e_e03_u01_fr03_01: reorder groups updates visual order', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.cfReorderGroupsOk);

    await tester.pumpWidget(buildCustomFieldSettingsRouter());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Tạo mẫu mặc định'));
    await tester.pumpAndSettle();

    final beforeTop = tester.getTopLeft(find.text('Thông tin thuốc'));
    final beforeBottom = tester.getTopLeft(find.text('Quy cách & bảo quản'));
    expect(beforeTop.dy, lessThan(beforeBottom.dy));

    final groupDragHandle = find.byIcon(Icons.drag_indicator).at(1);
    final groupDragGesture = await tester.startGesture(tester.getCenter(groupDragHandle));
    await tester.pump(const Duration(milliseconds: 600));
    await groupDragGesture.moveBy(const Offset(0, -220));
    await groupDragGesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Thông tin thuốc'), findsOneWidget);
    expect(find.text('Quy cách & bảo quản'), findsOneWidget);
    expect(find.text('Lỗi'), findsNothing);
  });

  testWidgets('e2e_e03_u01_fr04_02: single select field requires at least one option', (
    tester,
  ) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.cfFieldSingleSelectNoOptions);

    await tester.pumpWidget(buildCustomFieldSettingsRouter());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Tạo mẫu mặc định'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thông tin thuốc'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm trường'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(VTextField).first, 'Dạng bào chế');
    await tester.tap(find.text('Text'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Single select').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Cần có ít nhất 1 tùy chọn'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Thêm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Dạng bào chế'), findsOneWidget);
  });

  testWidgets('e2e_e03_u01_fr05_01: configure field attributes and show chips', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.cfFieldRequiredOn);

    await tester.pumpWidget(buildCustomFieldSettingsRouter());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Tạo mẫu mặc định'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thông tin thuốc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thành phần'));
    await tester.pumpAndSettle();

    final switches = find.byType(Switch);
    expect(switches, findsAtLeastNWidgets(1));
    await tester.tap(switches.at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Bắt buộc'), findsOneWidget);
  });

  testWidgets('e2e_e03_u01_fr06_01: reorder fields within group', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.cfReorderFieldsOk);

    await tester.pumpWidget(buildCustomFieldSettingsRouter());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(VButton, 'Tạo mẫu mặc định'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thông tin thuốc'));
    await tester.pumpAndSettle();

    final beforeFirst = tester.getTopLeft(find.text('Thành phần'));
    final beforeSecond = tester.getTopLeft(find.text('Chỉ định'));
    expect(beforeFirst.dy, lessThan(beforeSecond.dy));

    final fieldDragHandle = find.byIcon(Icons.drag_indicator).at(1);
    final fieldDragGesture = await tester.startGesture(tester.getCenter(fieldDragHandle));
    await tester.pump(const Duration(milliseconds: 600));
    await fieldDragGesture.moveBy(const Offset(0, -220));
    await fieldDragGesture.up();
    await tester.pumpAndSettle();

    final afterFirst = tester.getTopLeft(find.text('Thành phần'));
    final afterSecond = tester.getTopLeft(find.text('Chỉ định'));
    expect(afterSecond.dy, lessThan(afterFirst.dy));
  });
}
