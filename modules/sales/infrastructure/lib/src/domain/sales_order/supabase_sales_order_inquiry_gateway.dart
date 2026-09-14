import 'dart:convert';

import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'sales_order_inquiry_rpc_mapper.dart';

final class SupabaseSalesOrderInquiryGateway implements ISalesOrderInquiryGateway {
  SupabaseSalesOrderInquiryGateway({required IRpcClient rpcClient}) : _rpcClient = rpcClient;

  final IRpcClient _rpcClient;

  @override
  Future<PagedSalesOrderListDto> listSalesOrders(ListSalesOrdersQuery query) {
    return _call(
      'list_sales_orders',
      SalesOrderInquiryRpcMapper.listParams(query),
      SalesOrderInquiryRpcMapper.pagedListFromJson,
    );
  }

  @override
  Future<PagedSalesOrderListDto> searchSalesOrders(SearchSalesOrdersQuery query) {
    return _call(
      'search_sales_orders',
      SalesOrderInquiryRpcMapper.searchParams(query),
      SalesOrderInquiryRpcMapper.pagedListFromJson,
    );
  }

  @override
  Future<SalesOrderDetailDto> getSalesOrderDetail(GetSalesOrderDetailQuery query) {
    return _call(
      'get_sales_order_detail',
      SalesOrderInquiryRpcMapper.detailParams(query),
      SalesOrderInquiryRpcMapper.detailFromJson,
    );
  }

  @override
  Future<SalesOrderSettlementDto> getSettlement(GetSalesOrderSettlementQuery query) {
    return _call(
      'get_sales_order_settlement',
      SalesOrderInquiryRpcMapper.settlementParams(query),
      SalesOrderInquiryRpcMapper.settlementFromJson,
    );
  }

  @override
  Future<SalesPaymentTransactionsDto> getPaymentTransactions(
    GetSalesOrderPaymentTransactionsQuery query,
  ) {
    return _call(
      'get_sales_order_payment_transactions',
      SalesOrderInquiryRpcMapper.transactionsParams(query),
      SalesOrderInquiryRpcMapper.transactionsFromJson,
    );
  }

  @override
  Future<SalesOrderTimelineDto> getTimeline(GetSalesOrderTimelineQuery query) {
    return _call(
      'get_sales_order_timeline',
      SalesOrderInquiryRpcMapper.timelineParams(query),
      SalesOrderInquiryRpcMapper.timelineFromJson,
    );
  }

  @override
  Future<SalesOrderReturnSummaryDto> getReturnSummary(
    GetSalesOrderReturnSummaryQuery query,
  ) {
    return _call(
      'get_sales_order_return_summary',
      SalesOrderInquiryRpcMapper.returnSummaryParams(query),
      SalesOrderInquiryRpcMapper.returnSummaryFromJson,
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
      throw const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales order inquiry failed.',
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
        message: 'Sales order inquiry failed.',
      );
    }
    return const SalesContractException(
      'DEPENDENCY_UNAVAILABLE',
      message: 'Sales order inquiry failed.',
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
