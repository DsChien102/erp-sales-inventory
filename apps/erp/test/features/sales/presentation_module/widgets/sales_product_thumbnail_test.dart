import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/presentation.dart';

import '../support/compose_line_test_data.dart';

void main() {
  group('SalesSpecialPriceBanner', () {
    testWidgets('omits ribbon when visible is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SalesSpecialPriceBanner(
              visible: false,
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );

      expect(find.byKey(SalesSpecialPriceBanner.bannerKey), findsNothing);
    });

    testWidgets('paints ribbon without requiring thumbnail', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: SalesSpecialPriceBanner(
              child: SizedBox(width: 200, height: 56),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(SalesSpecialPriceBanner.bannerKey), findsOneWidget);
    });
  });

  group('SalesProductThumbnail', () {
    testWidgets('does not own special price banner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(body: SalesProductThumbnail()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SalesSpecialPriceBanner), findsNothing);
      expect(find.byKey(SalesSpecialPriceBanner.bannerKey), findsNothing);
    });
  });

  group('SalesOrderLineRow special pricing badge', () {
    testWidgets('hosts SalesSpecialPriceBanner when showSpecialPriceBadge is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SalesOrderLineRow(
              productName: 'SP A',
              unitPriceLabel: '10.000đ/Hộp',
              quantity: 1,
              onQuantityChanged: (_) {},
              showSpecialPriceBadge: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SalesSpecialPriceBanner), findsOneWidget);
      expect(find.byKey(SalesSpecialPriceBanner.bannerKey), findsOneWidget);
    });
  });

  group('SalesComposeLinesSection special pricing badge', () {
    testWidgets('shows special price badge on line with customer private rule', (
      tester,
    ) async {
      final normalLine = composeTestLine(
        lineId: 'line-1',
        productId: 'prod-1',
        productUnitId: 'unit-1',
        productName: 'Sản phẩm thường',
        unitLabel: 'Hộp',
        quantity: 1,
        baseUnitPrice: composeTestMoney(100000),
        appliedUnitPrice: composeTestMoney(100000),
        listUnitPrice: composeTestMoney(100000),
      );

      final specialLine = composeTestLine(
        lineId: 'line-2',
        productId: 'prod-2',
        productUnitId: 'unit-2',
        productName: 'AD3EC 5L (tyx)',
        unitLabel: 'Can',
        quantity: 1,
        baseUnitPrice: composeTestMoney(2500000),
        appliedUnitPrice: composeTestMoney(2350000),
        listUnitPrice: composeTestMoney(2500000),
        pricingSourceCode: 'CUSTOMER_PRIVATE_RULE',
      );

      expect(normalLine.hasSpecialPricing, isFalse);
      expect(specialLine.hasSpecialPricing, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: SalesComposeLinesSection(
                    lines: [normalLine, specialLine],
                    totals: SalesComposeTotals.fromLines([normalLine, specialLine]),
                    onQuantityChanged: (lineId, qty) => null,
                    onDiscount: (_) {},
                    onDelete: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(SalesSpecialPriceBanner.bannerKey), findsOneWidget);
    });
  });
}
