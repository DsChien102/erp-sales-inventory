import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SalesReturnExchangeSessionBody', () {
    testWidgets('renders loading / blocked / error keys', (tester) async {
      await tester.pumpWidget(
        _harness(
          const SalesReturnExchangeSessionState(
            orderId: 'order-1',
            status: SalesReturnExchangeSessionStatus.loading,
          ),
        ),
      );
      expect(find.byKey(const Key('wgt_sg11_loading')), findsOneWidget);

      await tester.pumpWidget(
        _harness(
          const SalesReturnExchangeSessionState(
            orderId: 'order-1',
            orderNumber: 'SO-1',
            status: SalesReturnExchangeSessionStatus.blocked,
            blockers: [
              SalesBlockerDto(code: 'X', message: 'Blocked reason'),
            ],
          ),
        ),
      );
      expect(find.byKey(const Key('wgt_sg11_blocked')), findsOneWidget);
      expect(find.text('Blocked reason'), findsOneWidget);

      await tester.pumpWidget(
        _harness(
          const SalesReturnExchangeSessionState(
            orderId: 'order-1',
            status: SalesReturnExchangeSessionStatus.failure,
            screenError: 'Load failed',
          ),
          onRetry: () {},
        ),
      );
      expect(find.byKey(const Key('wgt_sg11_error')), findsOneWidget);
      expect(find.text('Load failed'), findsOneWidget);
    });

    testWidgets('ready shows return lines, expected summary and exchange controls', (tester) async {
      final quantities = <(String, int)>[];
      await tester.pumpWidget(
        _harness(
          _readyState().copyWith(
            returnEdits: const [
              SalesReturnLineEdit(
                salesOrderLineId: 'line-1',
                quantityMicros: QuantityDto.scale,
              ),
            ],
            exchangeEdits: const [
              SalesExchangeLineEdit(
                productId: 'product-2',
                productUnitId: 'unit-2',
                productName: 'Hàng đổi 1',
                sku: 'SKU-2',
                unitLabel: 'chai',
                unitPrice: MoneyDto(amountMinor: 12000, currencyCode: 'VND'),
                quantityMicros: QuantityDto.scale,
              ),
            ],
          ),
          onReturnQuantityChanged: (id, qty) => quantities.add((id, qty)),
        ),
      );

      expect(find.textContaining('SO-2026-00125'), findsOneWidget);
      expect(find.text('Sản phẩm 1'), findsOneWidget);
      expect(find.byKey(const Key('qty_return_line-1')), findsOneWidget);
      expect(find.byKey(const Key('btn_add_exchange_product')), findsOneWidget);
      expect(find.text('Tóm tắt dự kiến'), findsOneWidget);
      expect(find.text('Giá trị hàng trả'), findsOneWidget);
      expect(find.text('Giá trị hàng đổi'), findsOneWidget);
      expect(find.text('Chênh lệch'), findsOneWidget);
      expect(find.text('50.000đ'), findsOneWidget);
      expect(find.text('12.000đ'), findsOneWidget);
      expect(find.text('-38.000đ'), findsOneWidget);

      await tester.tap(
        find
            .descendant(
              of: find.byKey(const Key('qty_return_line-1')),
              matching: find.byType(InkWell),
            )
            .last,
      );
      await tester.pump();
      expect(quantities, [('line-1', QuantityDto.scale * 2)]);
    });

    testWidgets('ready hides temporary reason and condition policy selectors', (tester) async {
      await tester.pumpWidget(
        _harness(
          _readyState().copyWith(
            returnEdits: const [
              SalesReturnLineEdit(
                salesOrderLineId: 'line-1',
                quantityMicros: QuantityDto.scale,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Lý do trả'), findsNothing);
      expect(find.text('Tình trạng'), findsNothing);
      expect(find.byKey(const Key('dropdown_return_reason_line-1')), findsNothing);
      expect(find.byKey(const Key('dropdown_return_condition_line-1')), findsNothing);
    });

    testWidgets('ready shows compact price per unit for return and exchange lines', (tester) async {
      await tester.pumpWidget(
        _harness(
          _readyState().copyWith(
            exchangeEdits: const [
              SalesExchangeLineEdit(
                productId: 'product-2',
                productUnitId: 'unit-2',
                productName: 'Hàng đổi 1',
                sku: 'SKU-2',
                unitLabel: 'chai',
                unitPrice: MoneyDto(amountMinor: 12000, currencyCode: 'VND'),
                quantityMicros: QuantityDto.scale,
              ),
            ],
          ),
        ),
      );

      expect(find.text('50.000đ/Hộp'), findsOneWidget);
      expect(find.text('12.000đ/chai'), findsOneWidget);
      expect(find.textContaining('trả tối đa'), findsNothing);
    });

    testWidgets('picker sheet uses injectible search — no demo rows', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: VButton(
                label: 'open',
                onPressed: () => showSalesExchangeProductPickerSheet(
                  context,
                  searchProducts: (_) async => const [],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input_exchange_product_search')), findsOneWidget);
      expect(find.byKey(const Key('wgt_exchange_picker_empty')), findsOneWidget);
      expect(find.textContaining('AD3EC'), findsNothing);
      expect(find.byKey(const Key('btn_select_exchange_p_ad3ec_5l')), findsNothing);
    });
  });
}

Widget _harness(
  SalesReturnExchangeSessionState state, {
  VoidCallback? onRetry,
  void Function(String, int)? onReturnQuantityChanged,
}) {
  return MaterialApp(
    theme: VTheme.lightTheme,
    home: Scaffold(
      body: SalesReturnExchangeSessionBody(
        state: state,
        onRetry: onRetry,
        onReturnQuantityChanged: onReturnQuantityChanged ?? (id, qty) {},
        onExchangeQuantityChanged: (id, qty) {},
        onAddExchangePressed: () {},
      ),
    ),
  );
}

SalesReturnExchangeSessionState _readyState() {
  return const SalesReturnExchangeSessionState(
    orderId: 'order-1',
    orderNumber: 'SO-2026-00125',
    customerDisplayName: 'Khách A',
    status: SalesReturnExchangeSessionStatus.ready,
    returnableLines: [
      ReturnableOrderLineDto(
        salesOrderLineId: 'line-1',
        product: ProductSnapshotDto(
          productId: 'product-1',
          sku: 'SKU-1',
          displayName: 'Sản phẩm 1',
        ),
        unit: ProductUnitSnapshotDto(
          productUnitId: 'unit-1',
          unitCode: 'BOX',
          unitName: 'Hộp',
        ),
        soldQuantity: QuantityDto(quantityMicros: QuantityDto.scale * 2),
        returnableQuantity: QuantityDto(quantityMicros: QuantityDto.scale * 2),
        originalUnitPrice: MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
      ),
    ],
  );
}
