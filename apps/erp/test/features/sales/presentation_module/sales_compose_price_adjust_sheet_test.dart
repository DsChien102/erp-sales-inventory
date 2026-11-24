import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/presentation.dart';

import 'support/compose_line_test_data.dart';

final _line = composeTestLine(
  lineId: 'line-1',
  productId: 'product-1',
  productUnitId: 'unit-1',
  productName: 'San pham 1',
  unitLabel: 'Hop',
  quantity: 1,
  baseUnitPrice: composeTestMoney(100000),
  appliedUnitPrice: composeTestMoney(100000),
  listUnitPrice: composeTestMoney(100000),
  floorUnitPrice: composeTestMoney(80000),
);

void main() {
  testWidgets('apply returns normalized unit-price manual intent', (tester) async {
    SalesComposePriceAdjustResult? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await SalesComposePriceAdjustSheet.show(
                  context,
                  line: _line,
                  canSavePrivatePrice: true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chk_save_private_price')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn_apply_price_adjust')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.manualPrice.mode, SalesPriceAdjustMode.unitPrice);
    expect(result!.manualPrice.acceptedUnitPrice.amountMinor, 100000);
    expect(result!.manualPrice.manualUnitPriceMinor, 100000);
    expect(result!.manualPrice.saveAsPrivatePrice, isTrue);
  });

  testWidgets('walk-in customer cannot request private-price persistence', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => SalesComposePriceAdjustSheet.show(
                context,
                line: _line,
                canSavePrivatePrice: false,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Lưu ngay làm giá riêng cho khách hàng này.'), findsOneWidget);
    expect(find.text('Chọn khách hàng để lưu giá riêng.'), findsOneWidget);
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.onChanged, isNull);
  });
}
