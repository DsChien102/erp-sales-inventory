import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_infrastructure/src/domain/pricing/product_price_band_rpc_mapper.dart';

void main() {
  group('ProductPriceBandRpcMapper', () {
    test('maps set params with before-VAT prices and optional fields', () {
      final effectiveFrom = DateTime.utc(2026, 1, 1);
      final params = ProductPriceBandRpcMapper.setProductUnitPriceBandParams(
        tenantId: 'tenant-1',
        productId: 'product-4',
        productUnitId: 'unit-lo',
        listBeforeVat: 37500,
        floorBeforeVat: 31250,
        listAfterVat: 41250,
        floorAfterVat: 34375,
        effectiveFrom: effectiveFrom,
        status: ProductPriceBandStatus.active,
        sourceType: PriceBandSourceType.manual,
        storePriceRuleId: 'rule-1',
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-4');
      expect(params['p_product_unit_id'], 'unit-lo');
      expect(params['p_list_price_before_vat'], 37500);
      expect(params['p_floor_price_before_vat'], 31250);
      expect(params['p_list_price_after_vat'], 41250);
      expect(params['p_floor_price_after_vat'], 34375);
      expect(params['p_effective_from'], effectiveFrom.toIso8601String());
      expect(params['p_status'], 'active');
      expect(params['p_source_type'], 'manual');
      expect(params['p_store_price_rule_id'], 'rule-1');
    });

    test('maps list rows to ProductUnitPriceBandsDto', () {
      final dto = ProductPriceBandRpcMapper.bandsFromRows([
        {
          'product_id': 'product-9',
          'base_unit_name': 'Lọ',
          'currency': 'VND',
          'base_price_per_base_unit': 100000,
          'base_price': 100000,
          'product_unit_id': 'unit-lo',
          'unit_name': 'Lọ',
          'is_base_unit': true,
          'is_active': true,
          'list_price_before_vat': 15000,
          'floor_price_before_vat': 12000,
          'list_price_after_vat': 16500,
          'floor_price_after_vat': 13200,
          'effective_from': '2026-01-01T00:00:00Z',
          'status': 'active',
          'source_type': 'manual',
          'store_price_rule_name': null,
          'is_custom_override': true,
        },
        {
          'product_id': 'product-9',
          'base_unit_name': 'Lọ',
          'currency': 'VND',
          'base_price_per_base_unit': 100000,
          'base_price': 1000000,
          'product_unit_id': 'unit-hop',
          'unit_name': 'Hộp',
          'is_base_unit': false,
          'is_active': true,
          'list_price_before_vat': null,
          'floor_price_before_vat': null,
          'source_type': null,
          'store_price_rule_name': null,
          'is_custom_override': false,
        },
      ]);

      expect(dto.productId, 'product-9');
      expect(dto.baseUnitName, 'Lọ');
      expect(dto.basePrice, 100000);
      expect(dto.rows, hasLength(2));
      expect(dto.rows.first.basePrice, 100000);
      expect(dto.rows.last.basePrice, 1000000);
      expect(dto.rows.first.isMissing, isFalse);
      expect(dto.rows.first.listBeforeVat, 15000);
      expect(dto.rows.first.floorBeforeVat, 12000);
      expect(dto.rows.first.listAfterVat, 16500);
      expect(dto.rows.first.floorAfterVat, 13200);
      expect(dto.rows.first.status, ProductPriceBandStatus.active);
      expect(dto.rows.last.isMissing, isTrue);
      expect(dto.rows.first.sourceType, PriceBandSourceType.manual);
    });

    test('maps legacy list_price / list_price_amount keys', () {
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

      expect(row.listBeforeVat, 15000);
      expect(row.floorBeforeVat, 12000);
      // Legacy before-only rows are incomplete until list_after is present/backfilled.
      expect(row.isMissing, isTrue);

      final legacyRow = ProductPriceBandRpcMapper.rowFromListRpc({
        'product_unit_id': 'unit-lo',
        'unit_name': 'Lọ',
        'is_base_unit': true,
        'is_active': true,
        'list_price': 16000,
        'floor_price': 13000,
        'list_price_after_vat': 16000,
        'source_type': 'manual',
        'store_price_rule_name': null,
        'is_custom_override': false,
      });

      expect(legacyRow.listBeforeVat, 16000);
      expect(legacyRow.floorBeforeVat, 13000);
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
            'list_price_before_vat': 120000,
            'list_price_before_vat_missing': false,
            'floor_price_before_vat': 95000,
            'floor_price_before_vat_missing': false,
            'floor_price_before_vat_hidden': false,
            'is_unit_active': true,
            'product_business_status': 'active',
          },
        ],
      });

      expect(dto.items, hasLength(1));
      expect(dto.items.single.listBeforeVat, 120000);
      expect(dto.items.single.floorBeforeVat, 95000);
      expect(dto.items.single.productBusinessStatus, ProductBusinessStatus.active);
    });
  });
}
