import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_infrastructure/src/domain/product/product_rpc_mapper.dart';

void main() {
  group('ProductRpcMapper (US-02 Operational Data)', () {
    test('setInitialStockParams maps stock profile to RPC parameters', () {
      final profile = ProductStockProfile.basic(initialStock: 150.0);
      final params = ProductRpcMapper.setInitialStockParams(
        productId: 'prod-1',
        tenantId: 'tenant-1',
        profile: profile,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'prod-1');
      expect(params['p_mode'], 'basic');
      expect(params['p_initial_stock'], 150.0);
    });

    test('setManualBasePriceParams maps base price profile to RPC parameters', () {
      final profile = ProductBasePriceProfile.manual(
        basePrice: BasePrice(amount: 85000.0),
      );
      final params = ProductRpcMapper.setManualBasePriceParams(
        productId: 'prod-1',
        tenantId: 'tenant-1',
        profile: profile,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'prod-1');
      expect(params['p_mode'], 'manual');
      expect(params['p_base_price'], 85000.0);
      expect(params['p_currency'], 'VND');
    });

    test('setInitialPriceBandParams maps price band to RPC parameters', () {
      final band = ProductUnitPriceBand(
        id: 'band-1',
        tenantId: 'tenant-1',
        productId: 'prod-1',
        productUnitId: 'unit-box',
        listPrice: ListPrice(amount: 120000.0),
        floorPrice: FloorPrice(amount: 100000.0),
      );
      final params = ProductRpcMapper.setInitialPriceBandParams(
        productId: 'prod-1',
        tenantId: 'tenant-1',
        priceBand: band,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'prod-1');
      expect(params['p_product_unit_id'], 'unit-box');
      expect(params['p_list_price'], 120000.0);
      expect(params['p_floor_price'], 100000.0);
    });

    test('setInitialPriceBandParams omits unit id when base unit not specified', () {
      final band = ProductUnitPriceBand(
        id: 'band-1',
        tenantId: 'tenant-1',
        productId: 'prod-1',
        listPrice: ListPrice(amount: 120000.0),
        floorPrice: FloorPrice(amount: 100000.0),
      );
      final params = ProductRpcMapper.setInitialPriceBandParams(
        productId: 'prod-1',
        tenantId: 'tenant-1',
        priceBand: band,
      );

      expect(params.containsKey('p_product_unit_id'), isFalse);
      expect(params['p_list_price'], 120000.0);
      expect(params['p_floor_price'], 100000.0);
    });
  });

  group('ProductRpcMapper (EPIC-04/US-01 units)', () {
    test('listTenantUnitsParams maps picker params', () {
      final params = ProductRpcMapper.listTenantUnitsParams(
        tenantId: 'tenant-1',
        keyword: 'lo',
        limit: 20,
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_keyword'], 'lo');
      expect(params['p_limit'], 20);
    });

    test('checkDuplicateUnitNameParams maps duplicate-check params', () {
      final params = ProductRpcMapper.checkDuplicateUnitNameParams(
        tenantId: 'tenant-1',
        name: 'Lọ',
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_name'], 'Lọ');
    });

    test('setProductBaseUnitParams maps existing unit selection', () {
      final params = ProductRpcMapper.setProductBaseUnitParams(
        SetProductBaseUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-6',
          selection: const ExistingTenantUnit('unit-lo'),
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-6');
      expect(params['p_tenant_unit_id'], 'unit-lo');
      expect(params['p_new_unit_name'], isNull);
    });

    test('setProductBaseUnitParams maps new unit selection', () {
      final params = ProductRpcMapper.setProductBaseUnitParams(
        SetProductBaseUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-6',
          selection: const NewTenantUnit('Vỉ'),
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-6');
      expect(params['p_tenant_unit_id'], isNull);
      expect(params['p_new_unit_name'], 'Vỉ');
    });
  });

  group('ProductRpcMapper (EPIC-04/US-02 conversion units)', () {
    test('listProductUnitsParams maps query params', () {
      final params = ProductRpcMapper.listProductUnitsParams(
        ListProductUnitsQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
          includeInactive: true,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_include_inactive'], isTrue);
    });

    test('addConversionUnitParams maps command params', () {
      final params = ProductRpcMapper.addConversionUnitParams(
        AddProductConversionUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          unitName: 'Thùng',
          conversionRateToBase: 100,
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_unit_name'], 'Thùng');
      expect(params['p_conversion_rate_to_base'], 100);
    });

    test('deactivateConversionUnitParams maps command params', () {
      final params = ProductRpcMapper.deactivateConversionUnitParams(
        DeactivateProductConversionUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          productUnitId: 'product-1-unit-vi',
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_product_unit_id'], 'product-1-unit-vi');
    });

    test('reactivateConversionUnitParams maps command params', () {
      final params = ProductRpcMapper.reactivateConversionUnitParams(
        ReactivateProductConversionUnitCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          productUnitId: 'product-1-unit-thung',
        ),
      );

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_product_id'], 'product-1');
      expect(params['p_product_unit_id'], 'product-1-unit-thung');
    });

    test('productUnitDtoFromRow maps RPC row fields', () {
      final dto = ProductRpcMapper.productUnitDtoFromRow({
        'id': 'product-1-unit-vi',
        'name': 'Vỉ',
        'conversion_rate_to_base': 10,
        'is_base_unit': false,
        'is_active': true,
      });

      expect(dto.id, 'product-1-unit-vi');
      expect(dto.name, 'Vỉ');
      expect(dto.conversionRateToBase, 10);
      expect(dto.isBaseUnit, isFalse);
      expect(dto.isActive, isTrue);
    });

    test('productUnitMutationResultFromRow maps mutation result row', () {
      final result = ProductRpcMapper.productUnitMutationResultFromRow({
        'product_id': 'product-1',
        'unit': {
          'id': 'product-1-unit-thung',
          'name': 'Thùng',
          'conversion_rate_to_base': 100,
          'is_base_unit': false,
          'is_active': true,
        },
      });

      expect(result.productId, 'product-1');
      expect(result.unit.name, 'Thùng');
      expect(result.unit.isActive, isTrue);
    });
  });
}
