import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/catalog/presentation.dart';

import '../../catalog_e2e_harness.dart';

ProductListItemModel _product1() {
  return const ProductListItemModel(
    id: 'product-1',
    name: 'Thuốc A',
    businessStatus: ProductBusinessStatus.active,
    readinessStatus: ProductReadinessStatus.ready,
    baseUnit: 'Hộp',
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('e2e_e07_u04_fr02_01: product change history can be viewed from PCC', (
    tester,
  ) async {
    await setUpErpCatalogE2E(
      scenario: FakeCatalogScenario.scnContractE07U04Fr02_01,
    );

    await tester.pumpWidget(buildPccMaintenanceRouter(_product1()));
    await tester.pumpAndSettle();

    // Scroll to and tap on "Lịch sử thay đổi" section
    final historySection = find.text('Lịch sử thay đổi');
    await tester.dragUntilVisible(
      historySection,
      find.byType(SingleChildScrollView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    
    await tester.tap(historySection);
    await tester.pumpAndSettle();
    
    // Verify we are on Change History page
    expect(find.text('Lịch sử thay đổi'), findsWidgets);
    expect(find.text('Thuốc A'), findsWidgets);
    
    // Price-band history includes both update and creation snapshots.
    expect(find.text('Cập nhật khung giá — Hộp'), findsOneWidget);
    expect(find.text('Tạo khung giá — Hộp'), findsOneWidget);
    expect(
      find.text('Theo khung giá cửa hàng → Nhập thủ công'),
      findsOneWidget,
    );
    expect(find.text('120.000 đ → 125.000 đ'), findsOneWidget);
  });
}
