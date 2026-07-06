import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_infrastructure/src/domain/pricing/store_price_rule_rpc_mapper.dart';

void main() {
  group('StorePriceRuleRpcMapper', () {
    test('maps set store price rule params', () {
      final params = StorePriceRuleRpcMapper.setStorePriceRuleParams(
        tenantId: 'tenant-1',
        name: 'Mặc định bán lẻ',
        listMarkupRatio: 0.5,
        floorMarkupRatio: 0.25,
        status: StorePriceRuleStatus.active,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_status'], 'active');
      expect(params['p_list_markup_ratio'], 0.5);
    });

    test('maps rule row to dto', () {
      final rule = StorePriceRuleRpcMapper.ruleFromRow({
        'id': 'rule-1',
        'tenant_id': 'tenant-1',
        'name': 'Mặc định bán lẻ',
        'status': 'active',
        'calculation_type': 'markup',
        'list_markup_ratio': 0.5,
        'floor_markup_ratio': 0.25,
        'updated_at': '2026-07-06T00:00:00.000Z',
      });

      expect(rule?.name, 'Mặc định bán lẻ');
      expect(rule?.listMarkupRatio, 0.5);
    });

    test('maps suggestion row with soft-fail', () {
      final suggestion = StorePriceRuleRpcMapper.suggestionFromRow({
        'product_id': 'product-7',
        'base_price': 0,
        'currency': 'VND',
        'can_suggest': false,
        'unavailable_reason': 'Cần có Giá cơ sở định giá trước',
      });

      expect(suggestion.canSuggest, isFalse);
      expect(suggestion.unavailableReason, isNotNull);
    });

    test('maps price band source type from rpc', () {
      expect(
        StorePriceRuleRpcMapper.sourceTypeFromRpc('ruleBased'),
        PriceBandSourceType.ruleBased,
      );
      expect(
        StorePriceRuleRpcMapper.sourceTypeFromRpc('manual'),
        PriceBandSourceType.manual,
      );
    });
  });
}
