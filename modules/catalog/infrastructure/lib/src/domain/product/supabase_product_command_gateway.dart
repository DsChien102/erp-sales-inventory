import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'product_rpc_mapper.dart';

final class SupabaseProductCommandGateway implements IProductCommandGateway {
  SupabaseProductCommandGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<String> create({
    required Product product,
    required String idempotencyKey,
  }) async {
    try {
      final productId = await _rpcClient.callScalar<String>(
        'create_product',
        params: ProductRpcMapper.createProductParams(
          product: product,
          idempotencyKey: idempotencyKey,
        ),
      );

      if (productId == null || productId.isEmpty) {
        throw ApplicationException('Product create did not return an id.');
      }

      return productId;
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
