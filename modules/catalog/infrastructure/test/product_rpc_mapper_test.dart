import 'package:test/test.dart';
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
  });
}
