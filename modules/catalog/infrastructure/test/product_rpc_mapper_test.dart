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
}
