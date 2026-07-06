import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';
import 'store_price_rule_rpc_mapper.dart';

final class SupabaseStorePriceRuleGateway implements IStorePriceRuleGateway {
  SupabaseStorePriceRuleGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<StorePriceRuleDto?> getRule({required String tenantId}) async {
    try {
      final rows = await _rpcClient.callList(
        'get_store_price_rule',
        params: StorePriceRuleRpcMapper.getStorePriceRuleParams(
          tenantId: tenantId,
        ),
      );
      if (rows.isEmpty) {
        return null;
      }
      return StorePriceRuleRpcMapper.ruleFromRow(rows.first);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<StorePriceRuleDto> upsertRule({
    required String tenantId,
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    StorePriceRuleStatus status = StorePriceRuleStatus.active,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'set_store_price_rule',
        params: StorePriceRuleRpcMapper.setStorePriceRuleParams(
          tenantId: tenantId,
          name: name,
          listMarkupRatio: listMarkupRatio,
          floorMarkupRatio: floorMarkupRatio,
          status: status,
        ),
      );
      if (rows.isEmpty) {
        throw ApplicationException('Set store price rule did not return a result.');
      }
      final rule = StorePriceRuleRpcMapper.ruleFromRow(rows.first);
      if (rule == null) {
        throw ApplicationException('Set store price rule returned invalid data.');
      }
      return rule;
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<ProductUnitPriceSuggestionDto> suggest({
    required SuggestProductUnitPriceQuery query,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'suggest_product_unit_price',
        params: StorePriceRuleRpcMapper.suggestProductUnitPriceParams(
          tenantId: query.tenantId,
          productId: query.productId,
          productUnitId: query.productUnitId,
        ),
      );
      if (rows.isEmpty) {
        throw ApplicationException('Suggest product unit price did not return a result.');
      }
      return StorePriceRuleRpcMapper.suggestionFromRow(rows.first);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }

  @override
  Future<AppliedStorePriceRuleDto> apply({
    required ApplyStorePriceRuleCommand command,
  }) async {
    try {
      final rows = await _rpcClient.callList(
        'apply_store_price_rule',
        params: StorePriceRuleRpcMapper.applyStorePriceRuleParams(
          command: command,
        ),
      );
      if (rows.isEmpty) {
        throw ApplicationException('Apply store price rule did not return a result.');
      }
      return StorePriceRuleRpcMapper.appliedFromRow(rows.first);
    } on RpcException catch (error) {
      throw mapCatalogRpcError(error);
    }
  }
}
