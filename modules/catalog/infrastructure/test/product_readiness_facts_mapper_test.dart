import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_infrastructure/src/domain/product/product_readiness_facts_mapper.dart';

void main() {
  group('ProductReadinessFactsMapper', () {
    test('maps foundation RPC row to domain facts', () {
      final facts = ProductReadinessFactsMapper.fromRow({
        'product_id': 'product-1',
        'product_name': 'Thuốc A',
        'has_base_unit': true,
        'has_images': false,
        'has_stock': false,
        'has_base_price': false,
        'has_price_band': false,
        'has_required_custom_fields': true,
        'stock_mode': 'basic',
        'base_price_mode': 'manual',
      });

      expect(facts.productId, 'product-1');
      expect(facts.productName, 'Thuốc A');
      expect(facts.hasBaseUnit, isTrue);
      expect(facts.stockMode, StockMode.basic);
      expect(facts.basePriceMode, BasePriceMode.manual);
    });

    test('maps advanced and costing modes', () {
      final facts = ProductReadinessFactsMapper.fromRow({
        'product_id': 'product-2',
        'product_name': 'Thuốc B',
        'has_base_unit': true,
        'has_images': true,
        'has_stock': false,
        'has_base_price': false,
        'has_price_band': false,
        'has_required_custom_fields': true,
        'stock_mode': 'advanced',
        'base_price_mode': 'costing_module',
      });

      expect(facts.stockMode, StockMode.advanced);
      expect(facts.basePriceMode, BasePriceMode.costingModule);
    });
  });
}
