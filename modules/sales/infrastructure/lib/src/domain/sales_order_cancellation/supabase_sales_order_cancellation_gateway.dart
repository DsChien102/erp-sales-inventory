import 'dart:convert';

import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'sales_order_cancellation_rpc_mapper.dart';

final class SupabaseSalesOrderCancellationGateway implements ISalesOrderCancellationGateway {
  SupabaseSalesOrderCancellationGateway({required IRpcClient rpcClient}) : _rpcClient = rpcClient;

  final IRpcClient _rpcClient;

  @override
  Future<CancellationPrecheckDto> precheck(
    PrecheckSalesOrderCancellationQuery query,
  ) {
    return _call(
      'precheck_sales_order_cancellation',
      SalesOrderCancellationRpcMapper.precheckParams(query),
      SalesOrderCancellationRpcMapper.precheckFromJson,
    );
  }

  @override
  Future<SalesOrderCancellationResultDto> confirm(
    ConfirmSalesOrderCancellationCommand command,
  ) {
    return _call(
      'confirm_sales_order_cancellation',
      SalesOrderCancellationRpcMapper.confirmParams(command),
      SalesOrderCancellationRpcMapper.resultFromJson,
    );
  }

  @override
  Future<SalesOrderCancellationDetailDto> getDetail(
    GetSalesOrderCancellationQuery query,
  ) {
    return _call(
      'get_sales_order_cancellation',
      SalesOrderCancellationRpcMapper.detailParams(query),
      SalesOrderCancellationRpcMapper.detailFromJson,
    );
  }

  @override
  Future<List<CancellationReasonPolicyDto>> listReasons(
    ListSalesOrderCancellationReasonsQuery query,
  ) {
    return _call(
      'list_sales_order_cancellation_reasons',
      SalesOrderCancellationRpcMapper.listReasonsParams(query),
      SalesOrderCancellationRpcMapper.reasonsFromJson,
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
    message: 'Sales order cancellation operation failed.',
  );

  static const _stableCodes = <String>{
    'NOT_FOUND',
    'PERMISSION_DENIED',
    'DATA_SCOPE_DENIED',
    'CANCELLATION_BLOCKED',
    'STALE_VERSION',
    'IDEMPOTENCY_CONFLICT',
    'IMPACT_PENDING',
    'DEPENDENCY_UNAVAILABLE',
  };
}
