import 'package:erp/features/catalog/data/product_price_repository.dart';
import 'package:erp/features/catalog/presentation/pages/settings/store_price_rule_change_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../../support/catalog_test_registry.dart';

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('wgt_e06_u02_hist_01 shows history from fake module', (tester) async {
    registerFakeCatalog(getIt);
    final priceRepo = getIt<ProductPriceRepository>();

    await priceRepo.setStorePriceRule(
      name: 'Mặc định bán lẻ',
      listMarkupRatio: 0.12,
      floorMarkupRatio: 0.10,
    );
    await priceRepo.setStorePriceRule(
      name: 'Mặc định bán lẻ',
      listMarkupRatio: 0.15,
      floorMarkupRatio: 0.10,
    );

    await tester.pumpWidget(
      const MaterialApp(home: StorePriceRuleChangeHistoryPage()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lịch sử thay đổi'), findsOneWidget);
    expect(find.text('Bởi: fake-user'), findsWidgets);
    expect(find.text('Hiện tại'), findsOneWidget);
    expect(find.text('+15.0%'), findsOneWidget);
  });
}
