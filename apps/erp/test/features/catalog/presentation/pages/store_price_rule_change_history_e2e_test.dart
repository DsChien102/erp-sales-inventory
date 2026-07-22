import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/application.dart';

void main() {
  group('e2e_e06_u02_store_rule_history', () {
    test('e2e_e06_u02_hist_01 two saves produce paginated history', () async {
      final module = FakeCatalogModule();

      await module.executeCommandAsync(
        SetStorePriceRuleCommand(
          tenantId: 'tenant-1',
          name: 'Mặc định bán lẻ',
          listMarkupRatio: 0.12,
          floorMarkupRatio: 0.10,
        ),
      );
      await module.executeCommandAsync(
        SetStorePriceRuleCommand(
          tenantId: 'tenant-1',
          name: 'Mặc định bán lẻ',
          listMarkupRatio: 0.15,
          floorMarkupRatio: 0.10,
        ),
      );

      final history = await module.executeQueryAsync(
        GetStorePriceRuleChangeHistoryQuery(
          tenantId: 'tenant-1',
          limit: 10,
          offset: 0,
        ),
      );

      expect(history.items, hasLength(2));
      expect(history.items.first.isCurrent, isTrue);
      expect(history.items.first.listMarkupAfter, 0.15);
      expect(history.totalCount, 2);
    });
  });
}
