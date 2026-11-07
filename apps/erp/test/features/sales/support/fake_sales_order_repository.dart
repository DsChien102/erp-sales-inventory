// ignore_for_file: depend_on_referenced_packages

import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/models.dart';

class FakeSalesOrderRepository implements SalesOrderRepository {
  SalesOrderResultDto? result;
  Object? error;
  final getCalls = <String>[];

  PagedSalesOrderListDto? listResult;
  Object? listError;
  final listCalls = <({String? cursor, int pageSize, SalesOrderListFilterInput? filter})>[];

  PagedSalesOrderListDto? searchResult;
  Object? searchError;
  final searchCalls =
      <({String searchText, String? cursor, int pageSize, SalesOrderListFilterInput? filter})>[];

  SalesOrderDetailDto? detailResult;
  Object? detailError;
  final detailCalls = <String>[];

  SalesOrderTimelineDto? timelineResult;
  Object? timelineError;
  final timelineCalls = <({String salesOrderId, int? expectedSourceVersion})>[];

  SalesOrderReturnSummaryDto? returnSummaryResult;
  Object? returnSummaryError;
  final returnSummaryCalls = <({String salesOrderId, int? expectedSourceVersion})>[];

  AvailablePostSaleActionsDto? actionsResult;
  Object? actionsError;
  final actionsCalls = <({String salesOrderId, int? expectedSourceVersion})>[];

  SalesOrderCancellationDetailDto? cancellationResult;
  Object? cancellationError;
  final cancellationCalls = <({String salesOrderId, int? expectedSourceVersion})>[];

  @override
  Future<SalesOrderResultDto> get({required String salesOrderId}) async {
    getCalls.add(salesOrderId);
    final e = error;
    if (e != null) throw e;
    return result!;
  }

  @override
  Future<PagedSalesOrderListDto> list({
    String? cursor,
    int pageSize = 50,
    SalesOrderListFilterInput? filter,
  }) async {
    listCalls.add((cursor: cursor, pageSize: pageSize, filter: filter));
    final e = listError;
    if (e != null) throw e;
    return listResult!;
  }

  @override
  Future<PagedSalesOrderListDto> search({
    required String searchText,
    String? cursor,
    int pageSize = 50,
    SalesOrderListFilterInput? filter,
  }) async {
    searchCalls.add((searchText: searchText, cursor: cursor, pageSize: pageSize, filter: filter));
    final e = searchError;
    if (e != null) throw e;
    return searchResult!;
  }

  @override
  Future<SalesOrderDetailDto> getDetail({required String salesOrderId}) async {
    detailCalls.add(salesOrderId);
    final e = detailError;
    if (e != null) throw e;
    return detailResult!;
  }

  @override
  Future<SalesOrderTimelineDto> getTimeline({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) async {
    timelineCalls.add((salesOrderId: salesOrderId, expectedSourceVersion: expectedSourceVersion));
    final e = timelineError;
    if (e != null) throw e;
    return timelineResult!;
  }

  @override
  Future<SalesOrderReturnSummaryDto> getReturnSummary({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) async {
    returnSummaryCalls.add((
      salesOrderId: salesOrderId,
      expectedSourceVersion: expectedSourceVersion,
    ));
    final e = returnSummaryError;
    if (e != null) throw e;
    return returnSummaryResult!;
  }

  @override
  Future<AvailablePostSaleActionsDto> getAvailableActions({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) async {
    actionsCalls.add((salesOrderId: salesOrderId, expectedSourceVersion: expectedSourceVersion));
    final e = actionsError;
    if (e != null) throw e;
    return actionsResult!;
  }

  @override
  Future<SalesOrderCancellationDetailDto> getCancellation({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) async {
    cancellationCalls.add((
      salesOrderId: salesOrderId,
      expectedSourceVersion: expectedSourceVersion,
    ));
    final e = cancellationError;
    if (e != null) throw e;
    return cancellationResult!;
  }
}
