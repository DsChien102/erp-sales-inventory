import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/pricing_error_mapper.dart';
import 'customer_price_rule_import_rpc_mapper.dart';

final class SupabaseCustomerPriceRuleImportGateway
    implements ICustomerPriceRuleImportGateway {
  SupabaseCustomerPriceRuleImportGateway({
    required SupabaseSchemaRpcClient rpcClient,
  }) : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<CustomerPriceRuleImportDetailDto> create({
    required String tenantId,
    required String templateVersion,
    required String originalFileName,
    required CustomerPriceRuleImportMode importMode,
    required CustomerPriceRuleImportParseResult parseResult,
  }) async {
    try {
      final json = await _rpcClient.callMap(
        'create_customer_price_rule_import',
        params: CustomerPriceRuleImportRpcMapper.createParams(
          tenantId: tenantId,
          templateVersion: templateVersion,
          originalFileName: originalFileName,
          importMode: importMode,
          parseResult: parseResult,
        ),
      );
      return CustomerPriceRuleImportRpcMapper.detailFromJson(json);
    } on RpcException catch (error) {
      throw mapPricingRpcError(error);
    } on PricingBlockedException {
      rethrow;
    } on FormatException {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Import response mapping failed.',
      );
    } on Object {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Import operation failed.',
      );
    }
  }

  @override
  Future<CustomerPriceRuleImportDetailDto> get({
    required String tenantId,
    required String importId,
    required CustomerPriceRuleImportRowStatus? rowStatus,
    required String? cursor,
    required int limit,
  }) async {
    try {
      final json = await _rpcClient.callMap(
        'get_customer_price_rule_import',
        params: CustomerPriceRuleImportRpcMapper.getParams(
          tenantId: tenantId,
          importId: importId,
          rowStatus: rowStatus,
          cursor: cursor,
          limit: limit,
        ),
      );
      return CustomerPriceRuleImportRpcMapper.detailFromJson(json);
    } on RpcException catch (error) {
      throw mapPricingRpcError(error);
    } on PricingBlockedException {
      rethrow;
    } on FormatException {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Import response mapping failed.',
      );
    } on Object {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Import operation failed.',
      );
    }
  }

  @override
  Future<CustomerPriceRuleImportResultDto> confirm({
    required String tenantId,
    required String importId,
    required int expectedVersion,
    required DateTime businessDate,
    required bool acknowledgeWarningRows,
  }) async {
    try {
      final json = await _rpcClient.callMap(
        'confirm_customer_price_rule_import',
        params: CustomerPriceRuleImportRpcMapper.confirmParams(
          tenantId: tenantId,
          importId: importId,
          expectedVersion: expectedVersion,
          businessDate: businessDate,
          acknowledgeWarningRows: acknowledgeWarningRows,
        ),
      );
      return CustomerPriceRuleImportRpcMapper.resultFromJson(json);
    } on RpcException catch (error) {
      throw mapPricingRpcError(error);
    } on PricingBlockedException {
      rethrow;
    } on FormatException {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Import response mapping failed.',
      );
    } on Object {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Import operation failed.',
      );
    }
  }

  @override
  Future<CustomerPriceRuleImportDto> cancel({
    required String tenantId,
    required String importId,
    required int expectedVersion,
  }) async {
    try {
      final json = await _rpcClient.callMap(
        'cancel_customer_price_rule_import',
        params: CustomerPriceRuleImportRpcMapper.cancelParams(
          tenantId: tenantId,
          importId: importId,
          expectedVersion: expectedVersion,
        ),
      );
      return CustomerPriceRuleImportRpcMapper.batchFromJson(json);
    } on RpcException catch (error) {
      throw mapPricingRpcError(error);
    } on PricingBlockedException {
      rethrow;
    } on FormatException {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Import response mapping failed.',
      );
    } on Object {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Import operation failed.',
      );
    }
  }
}
