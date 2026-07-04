import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'product_rpc_mapper.dart';

final class SupabaseProductDuplicateChecker implements IProductDuplicateChecker {
  SupabaseProductDuplicateChecker({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<List<ProductDuplicateMatch>> findMatches({
    required TenantId tenantId,
    Sku? sku,
    Barcode? barcode,
    ProductId? excludeProductId,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'check_duplicate_product_code',
        params: ProductRpcMapper.checkDuplicateParams(
          tenantId: tenantId.value,
          sku: sku?.value,
          barcode: barcode?.value,
          excludeProductId: excludeProductId?.value,
        ),
      );

      return rows
          .map(
            (row) => ProductDuplicateMatch(
              field: ProductRpcMapper.duplicateFieldFromRpc(
                row['duplicate_field'] as String,
              ),
              productId: ProductId(row['product_id'] as String),
              productName: row['product_name'] as String,
              matchedValue: row['matched_value'] as String,
            ),
          )
          .toList(growable: false);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
