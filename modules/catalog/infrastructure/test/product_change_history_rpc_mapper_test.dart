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
        'price_band_change': {
          'product_unit_id': 'unit-lo',
          'unit_name': 'Lọ',
          'currency': 'VND',
          'trigger': 'direct',
          'before': null,
          'after': {
            'source_type': 'manual',
            'list_price': 55000,
            'floor_price': 53000,
          },
        },
      });

      expect(row.isSensitiveMasked, isTrue);
      expect(row.valueBefore, isNull);
      expect(row.valueAfter, isNull);
      expect(row.priceBandChange, isNull);
    });

    test('maps structured price-band update snapshot', () {
      final row = ProductChangeHistoryRpcMapper.readRowFromJson({
        'id': 'history-price-update',
        'occurred_at': '2026-07-15T10:00:00.000Z',
        'actor_display_name': 'Nguyễn Văn A',
        'change_type': 'set_product_unit_price_band',
        'summary': 'Cập nhật khung giá — Lọ',
        'change_category': 'pricing',
        'source': 'user',
        'is_sensitive_masked': false,
        'price_band_change': {
          'product_unit_id': 'unit-lo',
          'unit_name': 'Lọ',
          'currency': 'VND',
          'trigger': 'direct',
          'before': {
            'source_type': 'ruleBased',
            'list_price': 52500,
            'floor_price': 52000,
          },
          'after': {
            'source_type': 'manual',
            'list_price': 55000,
            'floor_price': 53000,
          },
        },
      });

      final change = row.priceBandChange!;
      expect(change.productUnitId, 'unit-lo');
      expect(change.unitName, 'Lọ');
      expect(change.currency, 'VND');
      expect(change.trigger, ProductPriceBandHistoryTrigger.direct);
      expect(change.before!.sourceType, PriceBandSourceType.ruleBased);
      expect(change.before!.listPrice, 52500);
      expect(change.before!.floorPrice, 52000);
      expect(change.after.sourceType, PriceBandSourceType.manual);
      expect(change.after.listPrice, 55000);
      expect(change.after.floorPrice, 53000);
    });

    test('maps price-band creation with null before snapshot', () {
      final row = ProductChangeHistoryRpcMapper.readRowFromJson({
        'id': 'history-price-create',
        'occurred_at': '2026-07-15T09:00:00.000Z',
        'actor_display_name': 'Nguyễn Văn A',
        'change_type': 'set_initial_price_band',
        'summary': 'Tạo khung giá — Lọ',
        'change_category': 'pricing',
        'source': 'user',
        'is_sensitive_masked': false,
        'price_band_change': {
          'product_unit_id': 'unit-lo',
          'unit_name': 'Lọ',
          'currency': 'VND',
          'trigger': 'direct',
          'before': null,
          'after': {
            'source_type': 'customConfig',
            'list_price': 65000,
            'floor_price': null,
          },
        },
      });

      expect(row.priceBandChange!.before, isNull);
      expect(
        row.priceBandChange!.after.sourceType,
        PriceBandSourceType.customConfig,
      );
      expect(row.priceBandChange!.after.floorPrice, isNull);
    });

    test('keeps legacy and malformed price-band rows backward compatible', () {
      final legacy = ProductChangeHistoryRpcMapper.readRowFromJson({
        'id': 'history-legacy',
        'occurred_at': '2026-07-15T08:00:00.000Z',
        'actor_display_name': 'Nguyễn Văn A',
        'change_type': 'set_product_unit_price_band',
        'summary': 'Cập nhật khung giá',
        'change_category': 'pricing',
        'source': 'user',
        'is_sensitive_masked': false,
      });
      final malformed = ProductChangeHistoryRpcMapper.readRowFromJson({
        'id': 'history-malformed',
        'occurred_at': '2026-07-15T08:30:00.000Z',
        'actor_display_name': 'Nguyễn Văn A',
        'change_type': 'set_product_unit_price_band',
        'summary': 'Cập nhật khung giá',
        'change_category': 'pricing',
        'source': 'user',
        'is_sensitive_masked': false,
        'price_band_change': {
          'product_unit_id': 'unit-lo',
          'unit_name': 'Lọ',
          'currency': 'VND',
          'trigger': 'unknown',
          'after': {'source_type': 'invalid', 'list_price': '55000'},
        },
      });

      expect(legacy.priceBandChange, isNull);
      expect(malformed.priceBandChange, isNull);
    });
  });
}
