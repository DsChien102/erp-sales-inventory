import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/logic/sales_return_exchange_session_state.dart';
import 'package:erp/features/sales/presentation/support/sales_return_exchange_session_draft.dart';

void main() {
  group('SalesReturnExchangeSessionDraft.buildLines', () {
    test('sets sourceExchangeLineId for an exchanged-in returnable unit', () {
      final lines = SalesReturnExchangeSessionDraft.buildLines(
        returnEdits: [
          const SalesReturnLineEdit(salesOrderLineId: 'ex-line-1', quantityMicros: 1000000),
        ],
        exchangeEdits: const [],
        returnableLines: [
          ReturnableOrderLineDto(
            sourceExchangeLineId: 'ex-line-1',
            product: const ProductSnapshotDto(productId: 'p-b', sku: null, displayName: 'B'),
            unit: const ProductUnitSnapshotDto(
              productUnitId: 'u-b',
              unitCode: null,
              unitName: 'lọ',
            ),
            soldQuantity: const QuantityDto(quantityMicros: 1000000),
            returnableQuantity: const QuantityDto(quantityMicros: 1000000),
            originalUnitPrice: const MoneyDto(amountMinor: 1100000, currencyCode: 'VND'),
          ),
        ],
      );
      final line = lines.single;
      expect(line.sourceExchangeLineId, 'ex-line-1');
      expect(line.originalSalesOrderLineId, isNull);
      expect(line.productId, 'p-b');
    });
  });
}
