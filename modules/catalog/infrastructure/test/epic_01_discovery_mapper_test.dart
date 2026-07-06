import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

import 'package:vet45_catalog_infrastructure/src/domain/product/product_control_center_mapper.dart';
import 'package:vet45_catalog_infrastructure/src/domain/product/product_list_item_mapper.dart';

void main() {
  group('ProductListItemMapper', () {
    test('maps search RPC row to read model', () {
      final row = ProductListItemMapper.fromRow({
        'product_id': 'product-1',
        'name': 'Amoxicillin 500mg',
        'trade_name': 'Amox 500',
        'sku': 'SP0001',
        'barcode': '8930000000001',
        'primary_image_url': 'https://example.com/a.jpg',
        'business_status': 'active',
        'is_soft_deleted': false,
        'base_unit_name': 'Hộp',
        'stock_qty': 150,
        'list_price': 120000,
        'floor_price': 95000,
        'updated_at': '2026-06-01T10:00:00Z',
        'has_base_unit': true,
        'has_images': true,
        'has_stock': true,
        'has_base_price': true,
        'has_price_band': true,
        'has_required_custom_fields': true,
        'stock_mode': 'basic',
        'base_price_mode': 'manual',
        'total_count': 1,
      });

      expect(row.id, 'product-1');
      expect(row.facts.hasPriceBand, isTrue);
      expect(row.stockQuantity, 150);
      expect(row.businessStatus, ProductStatus.active);
    });
  });

  group('ProductControlCenterMapper', () {
    test('maps control center JSON payload', () {
      final model = ProductControlCenterMapper.fromJson({
        'product_id': 'product-1',
        'name': 'Amoxicillin 500mg',
        'trade_name': 'Amox 500',
        'sku': 'SP0001',
        'barcode': '8930000000001',
        'description': 'desc',
        'note': 'note',
        'business_status': 'active',
        'is_soft_deleted': false,
        'primary_image_url': 'https://example.com/a.jpg',
        'images': ['https://example.com/a.jpg'],
        'base_unit_name': 'Hộp',
        'conversion_units': [
          {
            'name': 'Vỉ',
            'conversion_rate': 10,
            'is_active': true,
          },
        ],
        'stock_mode': 'basic',
        'stock_qty': 150,
        'stock_version': 3,
        'base_price_mode': 'manual',
        'base_price_amount': 80000,
        'base_price_currency': 'VND',
        'list_price': 120000,
        'floor_price': 95000,
        'price_band_source_type': 'manual',
        'store_price_rule_name': null,
        'is_custom_override': true,
        'has_base_unit': true,
        'has_images': true,
        'has_stock': true,
        'has_base_price': true,
        'has_price_band': true,
        'has_required_custom_fields': true,
        'change_history_preview': [
          {
            'id': 'history-1',
            'occurred_at': '2026-06-01T10:00:00Z',
            'actor_display_name': 'user-1',
            'change_type': 'product_created',
            'summary': 'Tạo sản phẩm',
          },
        ],
      });

      expect(model.productId, 'product-1');
      expect(model.stockVersion, 3);
      expect(model.conversionUnits.single.name, 'Vỉ');
      expect(model.changeHistoryPreview, hasLength(1));
      expect(model.facts.hasPriceBand, isTrue);
      expect(model.priceBandSourceType, PriceBandSourceType.manual);
      expect(model.isCustomOverride, isTrue);
    });
  });
}
