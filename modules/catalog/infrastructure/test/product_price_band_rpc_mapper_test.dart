import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_infrastructure/src/domain/pricing/product_price_band_rpc_mapper.dart';

void main() {
  group('ProductPriceBandRpcMapper', () {
    test('maps set params with source type and store rule id', () {
      final params = ProductPriceBandRpcMapper.setProductUnitPriceBandParams(
        tenantId: 'tenant-1',
        productId: 'product-4',
        productUnitId: 'unit-lo',
        listPrice: 37500,
        floorPrice: 31250,
        sourceType: PriceBandSourceType.manual,
        storePriceRuleId: 'rule-1',
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-4');
      expect(params['p_product_unit_id'], 'unit-lo');
      expect(params['p_list_price'], 37500);
      expect(params['p_floor_price'], 31250);
      expect(params['p_source_type'], 'manual');
      expect(params['p_store_price_rule_id'], 'rule-1');
    });

    test('maps list rows to ProductUnitPriceBandsDto', () {
      final dto = ProductPriceBandRpcMapper.bandsFromRows([
        {
          'product_id': 'product-9',
          'base_unit_name': 'Lọ',
          'currency': 'VND',
          'base_price': 100000,
          'product_unit_id': 'unit-lo',
          'unit_name': 'Lọ',
          'is_base_unit': true,
          'is_active': true,
          'list_price': 15000,
          'floor_price': 12000,
          'source_type': 'manual',
          'store_price_rule_name': null,
          'is_custom_override': true,
        },
        {
          'product_id': 'product-9',
          'base_unit_name': 'Lọ',
          'currency': 'VND',
          'base_price': 100000,
          'product_unit_id': 'unit-hop',
          'unit_name': 'Hộp',
          'is_base_unit': false,
          'is_active': true,
          'list_price': null,
          'floor_price': null,
          'source_type': null,
          'store_price_rule_name': null,
          'is_custom_override': false,
        },
      ]);

      expect(dto.productId, 'product-9');
      expect(dto.baseUnitName, 'Lọ');
      expect(dto.basePrice, 100000);
      expect(dto.rows, hasLength(2));
      expect(dto.rows.first.isMissing, isFalse);
      expect(dto.rows.last.isMissing, isTrue);
      expect(dto.rows.first.sourceType, PriceBandSourceType.manual);
    });

    test('maps legacy list_price_amount and floor_price_amount keys', () {
      final row = ProductPriceBandRpcMapper.rowFromListRpc({
        'product_unit_id': 'unit-lo',
        'unit_name': 'Lọ',
        'is_base_unit': true,
        'is_active': true,
        'list_price_amount': 15000,
        'floor_price_amount': 12000,
        'source_type': 'manual',
        'store_price_rule_name': null,
        'is_custom_override': false,
      });

      expect(row.listPrice, 15000);
      expect(row.floorPrice, 12000);
      expect(row.isMissing, isFalse);
    });

    test('maps snapshot params and json payload', () {
      final params = ProductPriceBandRpcMapper.getPriceBandSnapshotParams(
        tenantId: 'tenant-1',
        items: const [
          ProductPriceBandSnapshotRequest(
            productId: 'product-1',
            productUnitId: 'product-1-base',
          ),
        ],
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_items'], [
        {
          'product_id': 'product-1',
          'product_unit_id': 'product-1-base',
        },
      ]);

      final dto = ProductPriceBandRpcMapper.snapshotFromJson({
        'items': [
          {
            'product_id': 'product-1',
            'product_unit_id': 'product-1-base',
            'unit_name': 'Hộp',
            'currency': 'VND',
            'list_price': 120000,
            'list_price_missing': false,
            'floor_price': 95000,
            'floor_price_missing': false,
            'floor_price_hidden': false,
            'is_unit_active': true,
            'product_business_status': 'active',
          },
        ],
      });

      expect(dto.items, hasLength(1));
      expect(dto.items.single.listPrice, 120000);
      expect(dto.items.single.floorPrice, 95000);
      expect(dto.items.single.productBusinessStatus, ProductBusinessStatus.active);
    });
  });
}
