import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'product_price_band_rpc_mapper.dart';

final class SupabaseProductPriceBandGateway implements IProductPriceBandGateway {
  SupabaseProductPriceBandGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ProductUnitPriceBandsDto> listProductUnitPriceBands({
    required String tenantId,
    required String productId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'list_product_unit_price_bands',
        params: ProductPriceBandRpcMapper.listProductUnitPriceBandsParams(
          tenantId: tenantId,
          productId: productId,
        ),
      );
      if (rows.isEmpty) {
        throw ApplicationException('Product unit price bands did not return a result.');
      }
      return ProductPriceBandRpcMapper.bandsFromRows(rows);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<ProductPriceBandSnapshotDto> getPriceBandSnapshot({
    required String tenantId,
    required List<ProductPriceBandSnapshotRequest> items,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'get_product_price_band_snapshot',
        params: ProductPriceBandRpcMapper.getPriceBandSnapshotParams(
          tenantId: tenantId,
          items: items,
        ),
      );
      return ProductPriceBandRpcMapper.snapshotFromJson(row);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<void> setProductUnitPriceBand({
    required String tenantId,
    required String productId,
    required String productUnitId,
    required int listBeforeVat,
    required int listAfterVat,
    int? floorBeforeVat,
    required PriceBandSourceType sourceType,
    int? floorAfterVat,
    DateTime? effectiveFrom,
    DateTime? effectiveTo,
    ProductPriceBandStatus? status,
    String? storePriceRuleId,
  }) async {
    try {
      await _rpcClient.callList(
        'set_product_unit_price_band',
        params: ProductPriceBandRpcMapper.setProductUnitPriceBandParams(
          tenantId: tenantId,
          productId: productId,
          productUnitId: productUnitId,
          listBeforeVat: listBeforeVat,
          floorBeforeVat: floorBeforeVat,
          listAfterVat: listAfterVat,
          floorAfterVat: floorAfterVat,
          effectiveFrom: effectiveFrom,
          effectiveTo: effectiveTo,
          status: status,
          sourceType: sourceType,
          storePriceRuleId: storePriceRuleId,
        ),
      );
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
