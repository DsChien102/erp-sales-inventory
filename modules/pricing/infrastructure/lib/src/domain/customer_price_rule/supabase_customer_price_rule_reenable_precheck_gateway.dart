import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/pricing_error_mapper.dart';
import 'pricing_reenable_rpc_mapper.dart';

final class SupabaseCustomerPriceRuleReenablePrecheckGateway
    implements ICustomerPriceRuleReenablePrecheckPort {
  SupabaseCustomerPriceRuleReenablePrecheckGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<CustomerPriceRuleReenablePrecheckDto> precheck(
    PrecheckCustomerPriceRuleReenableQuery query,
  ) async {
    try {
      final json = await _rpcClient.callMap(
        'precheck_customer_price_rule_reenable',
        params: PricingReenableRpcMapper.precheckParams(query),
      );
      return PricingReenableRpcMapper.precheckResultFromJson(json);
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
