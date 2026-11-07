// ignore_for_file: depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/sales_finalize_request.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import 'package:vet45_sales_application/application.dart';

/// Cầu nối cho test cũ có fake `ISalesModule` ghi lại truy vấn: repository mới gọi
/// vào cùng fake đó, lỗi `SalesContractException` đổi sang `AppException` như repository thật
/// (PERMISSION_DENIED → NO_PERMISSION). Xoá cùng module ở 8-C.
Future<T> _bridge<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on SalesContractException catch (e) {
    throw AppException(
      e.code == 'PERMISSION_DENIED' ? 'NO_PERMISSION' : e.code,
      serverMessage: e.message,
    );
  }
}

class ModuleBackedSalesPaymentRepository implements SalesPaymentRepository {
  ModuleBackedSalesPaymentRepository(this.module);
  final ISalesModule module;

  @override
  Future<SalesOrderPaymentSummaryDto> getSummary({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _bridge(
    () => module.executeQueryAsync<SalesOrderPaymentSummaryDto>(
      GetSalesOrderPaymentSummaryQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    ),
  );

  @override
  Future<SalesOrderSettlementDto> getSettlement({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _bridge(
    () => module.executeQueryAsync<SalesOrderSettlementDto>(
      GetSalesOrderSettlementQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    ),
  );

  @override
  Future<SalesPaymentTransactionsDto> getTransactions({
    required String salesOrderId,
    int? expectedSourceVersion,
    String? cursor,
    int pageSize = 25,
  }) => _bridge(
    () => module.executeQueryAsync<SalesPaymentTransactionsDto>(
      GetSalesOrderPaymentTransactionsQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
        cursor: cursor,
        pageSize: pageSize,
      ),
    ),
  );
}

class ModuleBackedSalesOrderRepository implements SalesOrderRepository {
  ModuleBackedSalesOrderRepository(this.module);
  final ISalesModule module;

  @override
  Future<SalesOrderResultDto> get({required String salesOrderId}) => _bridge(
    () => module.executeQueryAsync<SalesOrderResultDto>(
      GetSalesOrderQuery(tenantId: 'tenant-1', actorId: 'actor-1', salesOrderId: salesOrderId),
    ),
  );

  @override
  Future<PagedSalesOrderListDto> list({
    String? cursor,
    int pageSize = 50,
    SalesOrderListFilterInput? filter,
  }) => _bridge(
    () => module.executeQueryAsync<PagedSalesOrderListDto>(
      ListSalesOrdersQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        cursor: cursor,
        pageSize: pageSize,
        filter: filter,
      ),
    ),
  );

  @override
  Future<PagedSalesOrderListDto> search({
    required String searchText,
    String? cursor,
    int pageSize = 50,
    SalesOrderListFilterInput? filter,
  }) => _bridge(
    () => module.executeQueryAsync<PagedSalesOrderListDto>(
      SearchSalesOrdersQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        searchText: searchText,
        cursor: cursor,
        pageSize: pageSize,
        filter: filter,
      ),
    ),
  );

  @override
  Future<SalesOrderDetailDto> getDetail({required String salesOrderId}) => _bridge(
    () => module.executeQueryAsync<SalesOrderDetailDto>(
      GetSalesOrderDetailQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
      ),
    ),
  );

  @override
  Future<SalesOrderTimelineDto> getTimeline({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _bridge(
    () => module.executeQueryAsync<SalesOrderTimelineDto>(
      GetSalesOrderTimelineQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    ),
  );

  @override
  Future<SalesOrderReturnSummaryDto> getReturnSummary({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _bridge(
    () => module.executeQueryAsync<SalesOrderReturnSummaryDto>(
      GetSalesOrderReturnSummaryQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    ),
  );

  @override
  Future<AvailablePostSaleActionsDto> getAvailableActions({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _bridge(
    () => module.executeQueryAsync<AvailablePostSaleActionsDto>(
      GetAvailablePostSaleActionsQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    ),
  );

  @override
  Future<SalesOrderCancellationDetailDto> getCancellation({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _bridge(
    () => module.executeQueryAsync<SalesOrderCancellationDetailDto>(
      GetSalesOrderCancellationQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    ),
  );
}

class ModuleBackedSalesReceiptRepository implements SalesReceiptRepository {
  ModuleBackedSalesReceiptRepository(this.module);
  final ISalesModule module;

  @override
  Future<SalesReceiptDto> generate({
    required String salesOrderId,
    required int expectedVersion,
  }) => _bridge(
    () => module.executeCommandAsync<SalesReceiptDto>(
      GenerateSalesReceiptCommand(
        id: 'cmd-1',
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
        idempotencyKey: 'sales-receipt:tenant-1:$salesOrderId:v$expectedVersion',
        expectedVersion: expectedVersion,
      ),
    ),
  );

  @override
  Future<SalesReceiptDto> get({
    required String receiptId,
    int? expectedSourceVersion,
  }) => _bridge(
    () => module.executeQueryAsync<SalesReceiptDto>(
      GetSalesReceiptQuery(
        id: 'q-1',
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        receiptId: receiptId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    ),
  );

  @override
  Future<SalesReceiptDocumentDto> getOriginal({required String salesOrderId}) => _bridge(
    () => module.executeQueryAsync<SalesReceiptDocumentDto>(
      GetSalesOrderOriginalReceiptQuery(
        id: 'q-1',
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
      ),
    ),
  );

  @override
  Future<SalesReceiptDto> recordPrinted({
    required String receiptId,
    required String commandId,
    required String idempotencyKey,
  }) => _bridge(
    () => module.executeCommandAsync<SalesReceiptDto>(
      RecordSalesReceiptPrintedCommand(
        id: commandId,
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        receiptId: receiptId,
        idempotencyKey: idempotencyKey,
      ),
    ),
  );

  @override
  Future<SalesReceiptDto> recordShared({
    required String receiptId,
    required String commandId,
    required String idempotencyKey,
  }) => _bridge(
    () => module.executeCommandAsync<SalesReceiptDto>(
      RecordSalesReceiptSharedCommand(
        id: commandId,
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        receiptId: receiptId,
        idempotencyKey: idempotencyKey,
      ),
    ),
  );
}

class ModuleBackedSalesCheckoutRepository implements SalesCheckoutRepository {
  ModuleBackedSalesCheckoutRepository(this.module);
  final ISalesModule module;

  @override
  Future<CheckoutPrecheckDto> precheck({
    required String storeId,
    String? customerId,
    required String currencyCode,
    DateTime? paymentDueDate,
    required List<CheckoutLineInput> lines,
    required List<PaymentIntentInput> paymentIntents,
    int? expectedSourceVersion,
  }) => _bridge(
    () => module.executeQueryAsync<CheckoutPrecheckDto>(
      PrecheckSalesOrderCheckoutQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: storeId,
        customerId: customerId,
        currencyCode: currencyCode,
        paymentDueDate: paymentDueDate,
        lines: lines,
        paymentIntents: paymentIntents,
        expectedSourceVersion: expectedSourceVersion,
      ),
    ),
  );

  @override
  Future<CheckoutResultDto> finalize(SalesFinalizeRequest request) => _bridge(
    () => module.executeCommandAsync<CheckoutResultDto>(
      FinalizeSalesOrderCommand(
        id: request.commandId,
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        storeId: request.storeId,
        sourceDraftId: request.sourceDraftId,
        customerId: request.customerId,
        currencyCode: request.currencyCode,
        orderNote: request.orderNote,
        paymentDueDate: request.paymentDueDate,
        lines: request.lines,
        paymentIntents: request.paymentIntents,
        commercialSnapshot: request.commercialSnapshot,
        idempotencyKey: request.idempotencyKey,
        payloadHash: request.payloadHash,
        correlationId: request.correlationId,
        expectedSourceVersion: request.expectedSourceVersion,
      ),
    ),
  );

  @override
  Future<CheckoutResultDto> getResult({
    required String storeId,
    required String idempotencyKey,
  }) => _bridge(
    () => module.executeQueryAsync<CheckoutResultDto>(
      GetCheckoutResultQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        idempotencyKey: idempotencyKey,
        storeId: storeId,
      ),
    ),
  );
}
