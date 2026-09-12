import 'dart:convert';

import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'sales_order_read_rpc_mapper.dart';

final class SupabaseSalesOrderReadGateway implements ISalesOrderReadGateway {
  SupabaseSalesOrderReadGateway({required IRpcClient rpcClient}) : _rpcClient = rpcClient;

  final IRpcClient _rpcClient;

  @override
  Future<SalesOrderResultDto> getSalesOrder(GetSalesOrderQuery query) {
    return _call(
      'get_sales_order',
      SalesOrderReadRpcMapper.getSalesOrderParams(query),
      SalesOrderReadRpcMapper.salesOrderResultFromJson,
    );
  }

  @override
  Future<SalesOrderPaymentSummaryDto> getPaymentSummary(
    GetSalesOrderPaymentSummaryQuery query,
  ) {
    return _call(
      'get_sales_order_payment_summary',
      SalesOrderReadRpcMapper.paymentSummaryParams(query),
      SalesOrderReadRpcMapper.paymentSummaryFromJson,
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
    } on FormatException {
      throw const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales order read failed.',
      );
    } on Object {
      throw const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales order read failed.',
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
        message: 'Sales order read failed.',
      );
    }
    return const SalesContractException(
      'DEPENDENCY_UNAVAILABLE',
      message: 'Sales order read failed.',
    );
  }

  static const _stableCodes = <String>{
    'NOT_FOUND',
    'PERMISSION_DENIED',
    'PROJECTION_PENDING',
    'DATA_SCOPE_DENIED',
    'STALE_VERSION',
    'DEPENDENCY_UNAVAILABLE',
  };
}
