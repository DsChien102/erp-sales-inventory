import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/pricing_error_mapper.dart';
import 'pricing_delete_rpc_mapper.dart';
import 'pricing_disable_rpc_mapper.dart';
import 'pricing_reenable_rpc_mapper.dart';
import 'pricing_rpc_mapper.dart';
import 'pricing_update_rpc_mapper.dart';

final class SupabaseCustomerPriceRuleCommandGateway
    implements ICustomerPriceRuleCommandGateway {
  SupabaseCustomerPriceRuleCommandGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<CreateCustomerPriceRuleResult> create({
    required CustomerPriceRule candidate,
    required String idempotencyKey,
    required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false,
  }) async {
    try {
      final json = await _rpcClient.callMap(
        'create_customer_price_rule',
        params: PricingRpcMapper.createParams(
          candidate: candidate,
          idempotencyKey: idempotencyKey,
          acknowledgeFloorWarning: acknowledgeFloorWarning,
          acknowledgeOverwrite: acknowledgeOverwrite,
        ),
      );
      return PricingRpcMapper.createResultFromJson(json);
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
  Future<CustomerPriceRuleDetailDto> update({
    required CustomerPriceRule candidate,
    required int expectedVersion,
    required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false,
  }) async {
    try {
      final json = await _rpcClient.callMap(
        'update_customer_price_rule',
        params: PricingUpdateRpcMapper.updateParams(
          candidate: candidate,
          expectedVersion: expectedVersion,
          acknowledgeFloorWarning: acknowledgeFloorWarning,
          acknowledgeOverwrite: acknowledgeOverwrite,
        ),
      );
      return PricingUpdateRpcMapper.updateResultFromJson(json);
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
  Future<CustomerPriceRuleDetailDto> disable({
    required String tenantId,
    required String ruleId,
    required int expectedVersion,
    required String? reason,
  }) async {
    try {
      final json = await _rpcClient.callMap(
        'disable_customer_price_rule',
        params: PricingDisableRpcMapper.params(
          tenantId: tenantId,
          ruleId: ruleId,
          expectedVersion: expectedVersion,
          reason: reason,
        ),
      );
      return PricingDisableRpcMapper.resultFromJson(json);
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
  Future<CustomerPriceRuleDetailDto> delete({
    required String tenantId,
    required String ruleId,
    required int expectedVersion,
  }) async {
    try {
      final json = await _rpcClient.callMap(
        'delete_customer_price_rule',
        params: PricingDeleteRpcMapper.params(
          tenantId: tenantId,
          ruleId: ruleId,
          expectedVersion: expectedVersion,
        ),
      );
      return PricingDeleteRpcMapper.resultFromJson(json);
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
  Future<CustomerPriceRuleDetailDto> reenable({
    required String tenantId,
    required String ruleId,
    required int expectedVersion,
    required DateTime businessDate,
    required String? precheckToken,
    required bool acknowledgeFloorWarning,
  }) async {
    try {
      final json = await _rpcClient.callMap(
        'reenable_customer_price_rule',
        params: PricingReenableRpcMapper.reenableParams(
          ReenableCustomerPriceRuleCommand(
            tenantId: tenantId,
            ruleId: ruleId,
            expectedVersion: expectedVersion,
            businessDate: businessDate,
            precheckToken: precheckToken,
            acknowledgeFloorWarning: acknowledgeFloorWarning,
          ),
        ),
      );
      return PricingReenableRpcMapper.reenableResultFromJson(json);
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
