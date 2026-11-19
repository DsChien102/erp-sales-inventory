import 'package:erp/features/inventory/logic/stock/stock_indicator_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('stock_indicator_rules', () {
    test('indicators_follow_bj01_order', () {
      expect(
        stockIndicators(
          available: 0,
          threshold: 10,
          hasExpired: true,
          hasNearExpiry: false,
        ),
        [StockIndicator.out, StockIndicator.expired],
      );
      expect(
        stockIndicators(
          available: 2,
          threshold: 8,
          hasExpired: true,
          hasNearExpiry: false,
        ),
        [StockIndicator.expired, StockIndicator.low],
      );
      expect(
        stockIndicators(
          available: 7,
          threshold: null,
          hasExpired: false,
          hasNearExpiry: false,
        ),
        [StockIndicator.notConfigured],
      );
      expect(
        stockIndicators(
          available: 30,
          threshold: 30,
          hasExpired: false,
          hasNearExpiry: true,
        ),
        [StockIndicator.low, StockIndicator.nearExpiry],
      );
    });

    test('primary_with_filter_falls_back_to_not_configured', () {
      final all = [StockIndicator.nearExpiry, StockIndicator.notConfigured];
      expect(
        primaryIndicator(all, filter: StockIndicator.low),
        StockIndicator.notConfigured,
      );
      expect(primaryIndicator(all), StockIndicator.nearExpiry);
    });

    test('urgency_rank', () {
      expect(urgencyRank([]), 4);
      expect(urgencyRank([StockIndicator.notConfigured]), 5);
      expect(urgencyRank([StockIndicator.expired, StockIndicator.low]), 1);
      expect(urgencyRank([StockIndicator.out]), 0);
      expect(urgencyRank([StockIndicator.low]), 2);
      expect(urgencyRank([StockIndicator.nearExpiry]), 3);
    });

    test('labels_and_tones', () {
      expect(StockIndicator.out.label, 'Hết hàng');
      expect(StockIndicator.out.tone, VComponentTone.danger);
      expect(StockIndicator.expired.label, 'Có lô hết hạn');
      expect(StockIndicator.expired.tone, VComponentTone.danger);
      expect(StockIndicator.low.label, 'Tồn thấp');
      expect(StockIndicator.low.tone, VComponentTone.warning);
      expect(StockIndicator.nearExpiry.label, 'Có lô cận hạn');
      expect(StockIndicator.nearExpiry.tone, VComponentTone.warning);
      expect(StockIndicator.notConfigured.label, 'Chưa có ngưỡng tồn');
      expect(StockIndicator.notConfigured.tone, isNull);
    });
  });
}
