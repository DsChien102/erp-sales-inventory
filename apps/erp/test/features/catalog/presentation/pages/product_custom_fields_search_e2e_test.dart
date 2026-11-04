import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../catalog_e2e_harness.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('e2e_e03_u03_fr02_01: keyword search via searchable custom fields', (tester) async {
    await setUpErpCatalogE2E(scenario: FakeCatalogScenario.customFieldSearchable);

    await tester.pumpWidget(buildCatalogDiscoveryRouter());
    await tester.pumpAndSettle();

    expect(find.textContaining('Amoxicillin 500mg'), findsOneWidget);
    expect(find.textContaining('Vitamin B Complex'), findsOneWidget);

    // Enter a keyword that matches a searchable custom field (e.g. "tiêu hóa")
    await tester.enterText(
      find.byKey(const Key('input_product_search')),
      'tiêu hóa',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify that the product with the matching custom field is returned
    expect(find.textContaining('Amoxicillin 500mg'), findsOneWidget);
    expect(find.textContaining('Vitamin B Complex'), findsNothing);
  });
}
