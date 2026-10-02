import 'dart:convert';
import 'dart:async';

import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'checkout_precheck_rpc_mapper.dart';

final class SupabaseCheckoutGateway implements ICheckoutGateway {
  SupabaseCheckoutGateway({required IRpcClient rpcClient}) : _rpcClient = rpcClient;

  final IRpcClient _rpcClient;

  @override
  Future<CheckoutPrecheckDto> precheck(
    PrecheckSalesOrderCheckoutQuery query,
  ) async {
    try {
      final json = await _rpcClient.call(
        'precheck_sales_order_checkout',
        params: CheckoutPrecheckRpcMapper.precheckParams(query),
      );
      return CheckoutPrecheckRpcMapper.precheckFromJson(json);
    } on RpcException catch (error) {
      throw _mapSalesRpcError(error);
    } on SalesContractException {
      rethrow;
    } on Object {
      throw const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales checkout precheck failed.',
      );
    }
  }

  @override
  Future<CheckoutResultDto> finalize(FinalizeSalesOrderCommand command) async {
    try {
      final json = await _rpcClient.call(
        'finalize_sales_order',
        params: CheckoutPrecheckRpcMapper.finalizeParams(command),
      );
      return CheckoutPrecheckRpcMapper.checkoutResultFromJson(json);
    } on RpcException catch (error) {
      throw _mapSalesRpcError(error);
    } on SalesContractException {
      rethrow;
    } on TimeoutException {
      throw const SalesContractException(
        'UNCERTAIN_RESULT',
        message: 'Checkout result is uncertain; check the attempt status.',
      );
    } on Object {
      throw const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales checkout finalize failed.',
      );
    }
  }

  @override
  Future<CheckoutResultDto> getResult(
    GetCheckoutResultQuery query,
  ) async {
    try {
      final json = await _rpcClient.call(
        'get_checkout_result',
        params: CheckoutPrecheckRpcMapper.statusParams(query),
      );
      return CheckoutPrecheckRpcMapper.checkoutResultFromJson(json);
    } on RpcException catch (error) {
      throw _mapSalesRpcError(error);
    } on SalesContractException {
      rethrow;
    } on Object {
      throw const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales checkout attempt status lookup failed.',
      );
    }
  }

  static SalesContractException _mapSalesRpcError(RpcException error) {
    try {
      final decoded = jsonDecode(error.message);
      if (decoded is Map) {
        final envelope = decoded.cast<String, dynamic>();
        final code = envelope['code'];
        if (code is String && _stableCodes.contains(code)) {
          final details = envelope['details'];
          return SalesContractException(
            code,
            message: envelope['message'] as String?,
            details: details is Map ? details.cast<String, Object?>() : const {},
          );
        }
      }
    } on Object {
      return const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales checkout precheck failed.',
      );
    }
    return const SalesContractException(
      'DEPENDENCY_UNAVAILABLE',
      message: 'Sales checkout precheck failed.',
    );
  }

  static const _stableCodes = <String>{
    'CHECKOUT_BLOCKED',
    'STALE_VERSION',
    'IDEMPOTENCY_CONFLICT',
    'DEPENDENCY_UNAVAILABLE',
    'UNCERTAIN_RESULT',
    'PRODUCT_NOT_SELLABLE',
    'PERMISSION_DENIED',
    'DATA_SCOPE_DENIED',
    'CONTEXT_INVALID',
    'CHECKOUT_RESULT_NOT_FOUND',
    'PRICE_CHANGED',
    'PRICING_BLOCKED',
  };
}
