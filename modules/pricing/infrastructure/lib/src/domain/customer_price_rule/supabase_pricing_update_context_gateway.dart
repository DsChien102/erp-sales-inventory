import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/pricing_error_mapper.dart';
import 'pricing_update_rpc_mapper.dart';

final class SupabasePricingUpdateContextGateway
    implements ICustomerPriceRuleUpdateContextPort {
  SupabasePricingUpdateContextGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<CustomerPriceRuleUpdateContext> load(
    UpdateCustomerPriceRuleCommand command,
  ) async {
    try {
      final json = await _rpcClient.callMap(
        'get_customer_price_rule_update_context',
        params: PricingUpdateRpcMapper.contextParams(command),
      );
      return PricingUpdateRpcMapper.contextFromJson(
        command: command,
        json: json,
      );
    } on RpcException catch (error) {
      throw mapPricingRpcError(error);
    } on PricingBlockedException {
      rethrow;
    } on Object catch (error) {
      throw PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Pricing operation failed.',
        details: {
          'error': error,
          'params': PricingUpdateRpcMapper.contextParams(command),
        },
      );
    }
  }
}
