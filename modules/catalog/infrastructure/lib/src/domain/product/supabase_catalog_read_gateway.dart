import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'product_control_center_mapper.dart';
import 'product_list_item_mapper.dart';
import 'product_rpc_mapper.dart';

final class SupabaseCatalogReadGateway implements ICatalogReadGateway {
  SupabaseCatalogReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ProductSearchResultDto> search({
    required String tenantId,
    required ProductSearchCriteria criteria,
    required int limit,
    required int offset,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'search_products',
        params: ProductRpcMapper.searchProductsParams(
          tenantId: tenantId,
          criteria: criteria,
          limit: limit,
          offset: offset,
        ),
      );

      if (rows.isEmpty) {
        return const ProductSearchResultDto(items: [], totalCount: 0);
      }

      final totalCount = (rows.first['total_count'] as num?)?.toInt() ?? rows.length;
      final items = rows
          .map(ProductListItemMapper.fromRow)
          .map(ProductListItemAssembler.toDto)
          .toList(growable: false);

      return ProductSearchResultDto(
        items: items,
        totalCount: totalCount,
      );
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<ProductListItemDto?> findByBarcode({
    required String tenantId,
    required String barcode,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'find_product_by_barcode',
        params: ProductRpcMapper.findByBarcodeParams(
          tenantId: tenantId,
          barcode: barcode,
        ),
      );

      if (rows.isEmpty) {
        return null;
      }

      return ProductListItemAssembler.toDto(
        ProductListItemMapper.fromRow(rows.first),
      );
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<ProductControlCenterReadModel?> loadControlCenter({
    required String tenantId,
    required String productId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'get_product_control_center',
        params: ProductRpcMapper.getProductControlCenterParams(
          tenantId: tenantId,
          productId: productId,
        ),
      );

      if (rows.isEmpty) {
        return null;
      }

      final payload = rows.first;
      final json = payload.containsKey('get_product_control_center')
          ? Map<String, dynamic>.from(
              payload['get_product_control_center'] as Map,
            )
          : Map<String, dynamic>.from(payload);

      return ProductControlCenterMapper.fromJson(json);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<List<CustomFieldFilterOptionDto>> listCustomFieldFilterOptions({
    required String tenantId,
    required int maxOptionsPerField,
  }) async {
    throw UnimplementedError(
      'listCustomFieldFilterOptions is not implemented until slice #18 BE.',
    );
  }
}
