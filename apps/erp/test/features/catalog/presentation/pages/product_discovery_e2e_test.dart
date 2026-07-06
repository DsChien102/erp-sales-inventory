import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/testing.dart';

import '../../catalog_e2e_harness.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('e2e_e01_u01_fr01_01: search products by keyword', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.searchWithReadiness);

    await tester.pumpWidget(buildCatalogDiscoveryRouter());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e01_u01_fr01_01')), findsOneWidget);
    expect(find.textContaining('Amoxicillin 500mg'), findsOneWidget);
    expect(find.textContaining('Vitamin B Complex'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('input_product_search')),
      'Amoxicillin',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('Amoxicillin 500mg'), findsOneWidget);
    expect(find.textContaining('Paracetamol'), findsNothing);
  });

  testWidgets('e2e_e01_u02_fr01_01: list to PCC shows operational cards',
      (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.pccIncomplete);

    await tester.pumpWidget(buildCatalogDiscoveryRouter());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Vitamin B Complex'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_e01_u02_fr01_01')), findsOneWidget);
    expect(find.text('Vitamin B Complex'), findsWidgets);
    expect(find.text('Thiếu dữ liệu'), findsOneWidget);
    expect(find.text('Đơn vị'), findsOneWidget);
    expect(find.text('Tồn kho'), findsOneWidget);
    expect(find.text('Khung giá'), findsOneWidget);
    expect(find.textContaining('Chai'), findsWidgets);
    expect(find.textContaining('Thiếu khung giá'), findsOneWidget);
  });
}
