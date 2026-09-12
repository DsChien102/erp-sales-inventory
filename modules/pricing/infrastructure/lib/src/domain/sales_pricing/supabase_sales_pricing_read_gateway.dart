import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/pricing_error_mapper.dart';
import 'sales_pricing_rpc_mapper.dart';

final class SupabaseSalesPricingReadGateway
    implements ISalesPricingReadGateway {
  SupabaseSalesPricingReadGateway({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<SalesWorkingStatePricingPreviewDto> previewWorkingState(
    SalesWorkingStatePricingInput input,
  ) async {
    try {
      final payload = await _rpcClient.callScalar<Object?>(
        'preview_sales_working_state_pricing',
        params: SalesPricingRpcMapper.previewParams(input),
      );
      return SalesPricingRpcMapper.previewFromPayload(
        payload,
        expectedContextVersion: input.contextVersion,
        expectedCurrencyCode: input.currencyCode,
        expectedLocalLineIds: input.lines
            .map((line) => line.localLineId)
            .toList(growable: false),
      );
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
  Future<SalesManualPriceEvaluationDto> evaluateManualPrice(
    EvaluateSalesManualPriceQuery query,
  ) async {
    try {
      final payload = await _rpcClient.callScalar<Object?>(
        'evaluate_sales_manual_price',
        params: SalesPricingRpcMapper.manualEvaluationParams(query),
      );
      return SalesPricingRpcMapper.manualEvaluationFromPayload(payload);
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
