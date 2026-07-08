import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_infrastructure/src/domain/lifecycle/product_change_history_rpc_mapper.dart';

void main() {
  group('ProductChangeHistoryRpcMapper', () {
    test('maps params with categories', () {
      final params = ProductChangeHistoryRpcMapper.getProductChangeHistoryParams(
        tenantId: 'tenant-1',
        productId: 'product-1',
        limit: 25,
        offset: 10,
        changeCategories: const [
          ProductChangeCategory.pricing,
          ProductChangeCategory.profile,
        ],
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_limit'], 25);
      expect(params['p_offset'], 10);
      expect(params['p_categories'], ['pricing', 'profile']);
    });

    test('maps null categories when filter empty', () {
      final params = ProductChangeHistoryRpcMapper.getProductChangeHistoryParams(
        tenantId: 'tenant-1',
        productId: 'product-1',
        limit: 50,
        offset: 0,
      );

      expect(params['p_categories'], isNull);
    });

    test('maps json payload to page', () {
      final page = ProductChangeHistoryRpcMapper.pageFromJson({
        'total_count': 2,
        'items': [
          {
            'id': 'history-1',
            'occurred_at': '2026-06-02T10:00:00.000Z',
            'actor_display_name': 'user-abc',
            'change_type': 'set_product_unit_price_band',
            'summary': 'Cập nhật khung giá',
            'value_before': '120000',
            'value_after': '125000',
            'change_category': 'pricing',
            'source': 'user',
            'is_sensitive_masked': false,
          },
          {
            'id': 'history-2',
            'occurred_at': '2026-06-01T09:00:00.000Z',
            'actor_display_name': 'user-def',
            'change_type': 'update_product_profile',
            'summary': 'Cập nhật hồ sơ',
            'value_before': 'Old',
            'value_after': 'New',
            'change_category': 'profile',
            'source': 'user',
            'is_sensitive_masked': false,
          },
        ],
      });

      expect(page.totalCount, 2);
      expect(page.items, hasLength(2));
      expect(page.items.first.changeCategory, ProductChangeCategory.pricing);
      expect(page.items.last.changeCategory, ProductChangeCategory.profile);
    });

    test('maps masked pricing row', () {
      final row = ProductChangeHistoryRpcMapper.readRowFromJson({
        'id': 'history-masked',
        'occurred_at': '2026-06-02T10:00:00.000Z',
        'actor_display_name': 'user-abc',
        'change_type': 'set_product_unit_price_band',
        'summary': 'Thay đổi giá (ẩn)',
        'value_before': null,
        'value_after': null,
        'change_category': 'pricing',
        'source': 'user',
        'is_sensitive_masked': true,
      });

      expect(row.isSensitiveMasked, isTrue);
      expect(row.valueBefore, isNull);
      expect(row.valueAfter, isNull);
    });
  });
}
