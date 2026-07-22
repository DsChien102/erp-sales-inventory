import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/pricing_error_mapper.dart';
import 'customer_price_rule_detail_rpc_mapper.dart';
import 'customer_price_rule_history_rpc_mapper.dart';
import 'customer_price_rule_search_rpc_mapper.dart';
import 'pricing_resolve_applicable_rpc_mapper.dart';

final class SupabaseCustomerPriceRuleReadGateway
    implements IPricingReadGateway {
  SupabaseCustomerPriceRuleReadGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<CustomerPriceRuleSearchResultDto> searchCustomerPriceRules(
    SearchCustomerPriceRulesQuery query,
  ) async {
    try {
      final json = await _rpcClient.callMap(
        'search_customer_price_rules',
        params: CustomerPriceRuleSearchRpcMapper.params(query),
      );
      return CustomerPriceRuleSearchRpcMapper.resultFromJson(json);
    } on RpcException catch (error) {
      throw mapPricingRpcError(error);
    } on PricingBlockedException {
      rethrow;
    } on Object {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Pricing operation failed.',
      );
    }
  }

  @override
  Future<CustomerPriceRuleDetailDto> getCustomerPriceRuleDetail(
    GetCustomerPriceRuleDetailQuery query,
  ) async {
    try {
      final json = await _rpcClient.callMap(
        'get_customer_price_rule_detail',
        params: CustomerPriceRuleDetailRpcMapper.params(query),
      );
      return CustomerPriceRuleDetailRpcMapper.detailFromJson(json);
    } on RpcException catch (error) {
      throw mapPricingRpcError(error);
    } on PricingBlockedException {
      rethrow;
    } on Object {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Pricing operation failed.',
      );
    }
  }

  @override
  Future<CursorPageDto<CustomerPriceRuleActivityDto>>
  getCustomerPriceRuleHistory(GetCustomerPriceRuleHistoryQuery query) async {
    try {
      final json = await _rpcClient.callMap(
        'get_customer_price_rule_history',
        params: CustomerPriceRuleHistoryRpcMapper.params(query),
      );
      return CustomerPriceRuleHistoryRpcMapper.pageFromJson(json);
    } on RpcException catch (error) {
      throw mapPricingRpcError(error);
    } on PricingBlockedException {
      rethrow;
    } on FormatException {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Pricing operation failed.',
      );
    } on Object {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Pricing operation failed.',
      );
    }
  }

  @override
  Future<ResolveApplicableCustomerPriceRuleResultDto>
  resolveApplicableCustomerPriceRule(
    ResolveApplicableCustomerPriceRuleQuery query,
  ) async {
    try {
      final json = await _rpcClient.callMap(
        'resolve_applicable_customer_price_rule',
        params: PricingResolveApplicableRpcMapper.params(query),
      );
      return PricingResolveApplicableRpcMapper.resultFromJson(json);
    } on RpcException catch (error) {
      throw mapPricingRpcError(error);
    } on PricingBlockedException {
      rethrow;
    } on Object {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Pricing operation failed.',
      );
    }
  }
}
