import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/pricing_error_mapper.dart';
import 'remembered_price_rpc_mapper.dart';

final class SupabaseRememberedPriceGateway implements IRememberedPriceGateway {
  SupabaseRememberedPriceGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<RememberedPriceOutcomeDto> save(RememberedPriceRequest request) async {
    try {
      final json = await _rpcClient.callMap(
        'save_remembered_price_from_order',
        params: RememberedPriceRpcMapper.params(request),
      );
      return RememberedPriceRpcMapper.outcomeFromJson(json);
    } on RpcException catch (error) {
      throw mapPricingRpcError(error);
    } on PricingBlockedException {
      rethrow;
    } on FormatException {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Remembered price response mapping failed.',
      );
    } on Object {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Remembered price operation failed.',
      );
    }
  }
}
