import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'product_rpc_mapper.dart';

final class SupabaseProductDeletionGateway implements IProductDeletionGateway {
  SupabaseProductDeletionGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ProductDeletionEligibilityDto> checkDeletionEligibility(
    CheckProductDeletionEligibilityQuery query,
  ) async {
    try {
      final rows = await _rpcClient.callList(
        'check_product_deletion_eligibility',
        params: ProductRpcMapper.checkProductDeletionEligibilityParams(query),
      );

      if (rows.isEmpty) {
        throw ApplicationException(
          'Product deletion eligibility did not return a result.',
        );
      }

      return ProductRpcMapper.productDeletionEligibilityFromRow(rows.first);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
