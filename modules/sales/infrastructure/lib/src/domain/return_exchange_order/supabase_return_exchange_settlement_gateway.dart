import 'dart:convert';

import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'return_exchange_rpc_mapper.dart';

final class SupabaseReturnExchangeSettlementGateway implements IReturnExchangeSettlementGateway {
  SupabaseReturnExchangeSettlementGateway({required IRpcClient rpcClient}) : _rpcClient = rpcClient;

  final IRpcClient _rpcClient;

  @override
  Future<SalesOrderPaymentSummaryDto> recordPayment(
    RecordSalesPaymentCommand command,
  ) {
    return _call(
      'settle_return_exchange_difference',
      ReturnExchangeRpcMapper.settlePaymentParams(command),
      ReturnExchangeRpcMapper.paymentSummaryFromJson,
    );
  }

  @override
  Future<ReturnExchangeSettlementResultDto> recordRefund(
    RecordSalesRefundCommand command,
  ) {
    return _call(
      'settle_return_exchange_difference',
      ReturnExchangeRpcMapper.settleRefundParams(command),
      ReturnExchangeRpcMapper.settlementResultFromJson,
    );
  }

  Future<T> _call<T>(
    String procedure,
    Map<String, dynamic> params,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final json = await _rpcClient.call(procedure, params: params);
      return fromJson(json);
    } on RpcException catch (error) {
      throw _mapSalesRpcError(error);
    } on SalesContractException {
      rethrow;
    } on Object {
      throw _fallbackError;
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
      return _fallbackError;
    }
    return _fallbackError;
  }

  static const _fallbackError = SalesContractException(
    'DEPENDENCY_UNAVAILABLE',
    message: 'Sales return/exchange settlement failed.',
  );

  static const _stableCodes = <String>{
    'NOT_FOUND',
    'PERMISSION_DENIED',
    'DATA_SCOPE_DENIED',
    'RETURN_EXCHANGE_BLOCKED',
    'RETURN_QUANTITY_EXCEEDED',
    'STALE_VERSION',
    'IDEMPOTENCY_CONFLICT',
    'IMPACT_PENDING',
    'DEPENDENCY_UNAVAILABLE',
  };
}
