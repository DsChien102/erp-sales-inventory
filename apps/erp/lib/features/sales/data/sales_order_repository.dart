import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/sales_order_get_json.dart';
import 'package:erp/features/sales/data/mappers/sales_order_inquiry_json.dart';
import 'package:erp/features/sales/data/sales_order_read_errors.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_sales_application/application.dart';

/// RPC đọc đơn của schema `sales` (get / list / search / detail / timeline / returnSummary / availableActions / cancellation).
class SalesOrderRepository {
  SalesOrderRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
    required Future<String> Function() actorId,
    String Function()? newId,
  }) : _rpc = rpc,
       _tenantId = tenantId,
       _actorId = actorId,
       _newId = newId ?? const Uuid().v4;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;
  final Future<String> Function() _actorId;
  final String Function() _newId;

  Future<SalesOrderResultDto> get({required String salesOrderId}) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_sales_order',
      params: SalesOrderGetJson.params(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
      ),
    );
    return SalesOrderGetJson.salesOrderResultFromJson(_asMap(raw));
  });

  Future<PagedSalesOrderListDto> list({
    String? cursor,
    int pageSize = 50,
    SalesOrderListFilterInput? filter,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'list_sales_orders',
      params: SalesOrderInquiryJson.listParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        cursor: cursor,
        pageSize: pageSize,
        filter: filter,
      ),
    );
    return SalesOrderInquiryJson.pagedListFromJson(_asMap(raw));
  });

  Future<PagedSalesOrderListDto> search({
    required String searchText,
    String? cursor,
    int pageSize = 50,
    SalesOrderListFilterInput? filter,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'search_sales_orders',
      params: SalesOrderInquiryJson.searchParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        searchText: searchText,
        cursor: cursor,
        pageSize: pageSize,
        filter: filter,
      ),
    );
    return SalesOrderInquiryJson.pagedListFromJson(_asMap(raw));
  });

  Future<SalesOrderDetailDto> getDetail({required String salesOrderId}) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_sales_order_detail',
      params: SalesOrderInquiryJson.orderScopedParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
        expectedSourceVersion: null,
      ),
    );
    return SalesOrderInquiryJson.detailFromJson(_asMap(raw));
  });

  Future<SalesOrderTimelineDto> getTimeline({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_sales_order_timeline',
      params: SalesOrderInquiryJson.orderScopedParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    );
    return SalesOrderInquiryJson.timelineFromJson(_asMap(raw));
  });

  Future<SalesOrderReturnSummaryDto> getReturnSummary({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_sales_order_return_summary',
      params: SalesOrderInquiryJson.orderScopedParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    );
    return SalesOrderInquiryJson.returnSummaryFromJson(_asMap(raw));
  });

  Future<AvailablePostSaleActionsDto> getAvailableActions({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_available_post_sale_actions',
      params: SalesOrderInquiryJson.orderScopedParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    );
    return SalesOrderInquiryJson.availableActionsFromJson(_asMap(raw));
  });

  Future<SalesOrderCancellationDetailDto> getCancellation({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _guard(() async {
    final raw = await _rpc.call(
      'sales',
      'get_sales_order_cancellation',
      params: SalesOrderInquiryJson.orderScopedParams(
        queryId: _newId(),
        tenantId: await _tenantId(),
        actorId: await _actorId(),
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    );
    return SalesOrderInquiryJson.cancellationDetailFromJson(_asMap(raw));
  });

  Future<T> _guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on Object catch (error) {
      throw salesOrderReadException(error);
    }
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map) return raw.cast<String, dynamic>();
    throw FormatException('Expected JSON object, got $raw.');
  }
}
