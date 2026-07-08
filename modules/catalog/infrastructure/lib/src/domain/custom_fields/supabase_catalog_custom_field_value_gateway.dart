import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'custom_field_rpc_mapper.dart';

final class SupabaseCatalogCustomFieldValueGateway implements ICatalogCustomFieldValueGateway {
  SupabaseCatalogCustomFieldValueGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<ProductCustomFieldValuesDto> getValues({
    required String tenantId,
    required String productId,
    bool includeInactiveValues = false,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'get_product_custom_field_values',
        params: CustomFieldRpcMapper.getProductCustomFieldValuesParams(
          tenantId: tenantId,
          productId: productId,
          includeInactiveValues: includeInactiveValues,
        ),
      );

      if (row.isEmpty) {
        throw ApplicationException('Product not found');
      }

      return CustomFieldRpcMapper.productCustomFieldValuesFromJson(row);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<UpsertCustomFieldValuesResult> upsertValues({
    required UpsertCustomFieldValuesCommand command,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'upsert_product_custom_field_values',
        params: CustomFieldRpcMapper.upsertProductCustomFieldValuesParams(
          command: command,
        ),
      );

      if (row.isEmpty) {
        throw ApplicationException(
          'Upsert product custom field values did not return a result.',
        );
      }

      return CustomFieldRpcMapper.upsertProductCustomFieldValuesResultFromJson(
        row,
      );
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
