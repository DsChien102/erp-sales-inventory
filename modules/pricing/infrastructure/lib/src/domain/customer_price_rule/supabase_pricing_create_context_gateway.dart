import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/pricing_error_mapper.dart';
import 'pricing_rpc_mapper.dart';

final class SupabasePricingCreateContextGateway
    implements ICustomerPriceRuleCreateContextPort {
  SupabasePricingCreateContextGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<CustomerPriceRuleCreateContext> load(
    CreateCustomerPriceRuleCommand command,
  ) async {
    try {
      final json = await _rpcClient.callMap(
        'get_customer_price_rule_create_context',
        params: PricingRpcMapper.createContextParams(command),
      );
      return PricingRpcMapper.createContextFromJson(json);
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
