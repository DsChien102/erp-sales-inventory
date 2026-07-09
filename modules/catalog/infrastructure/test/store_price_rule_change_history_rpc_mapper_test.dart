import 'package:test/test.dart';
import 'package:vet45_catalog_infrastructure/src/domain/pricing/store_price_rule_change_history_rpc_mapper.dart';

void main() {
  group('StorePriceRuleChangeHistoryRpcMapper', () {
    test('params maps tenant pagination', () {
      final params = StorePriceRuleChangeHistoryRpcMapper.params(
        tenantId: 'tenant-1',
        limit: 25,
        offset: 10,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_limit'], 25);
      expect(params['p_offset'], 10);
    });

    test('resultFromJson maps list/floor before after and is_current', () {
      final result = StorePriceRuleChangeHistoryRpcMapper.resultFromJson({
        'items': [
          {
            'id': 'h1',
            'occurred_at': '2026-07-09T07:30:00.000Z',
            'actor_display_name': 'abc12345',
            'summary': 'Cập nhật khung giá cửa hàng',
            'list_markup_before': 0.12,
            'list_markup_after': 0.15,
            'floor_markup_before': 0.10,
            'floor_markup_after': 0.10,
            'is_current': true,
          },
        ],
        'total_count': 1,
      });

      expect(result.items, hasLength(1));
      expect(result.items.single.listMarkupAfter, 0.15);
      expect(result.items.single.floorMarkupBefore, 0.10);
      expect(result.items.single.isCurrent, isTrue);
      expect(result.totalCount, 1);
    });
  });
}
