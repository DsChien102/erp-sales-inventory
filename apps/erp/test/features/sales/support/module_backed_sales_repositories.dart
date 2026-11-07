// ignore_for_file: depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/data/models/sales_cancellation_request.dart';
import 'package:erp/features/sales/data/models/sales_finalize_request.dart';
import 'package:erp/features/sales/data/models/sales_record_payment.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:erp/features/sales/data/sales_cancellation_repository.dart';
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
    Map<String, dynamic>? details;
    if (e.details.isNotEmpty) {
      final rawBlockers = e.details['blockers'];
      if (rawBlockers is List) {
        details = <String, dynamic>{
          'blockers': [
            for (final b in rawBlockers)
              if (b is SalesBlockerDto)
                <String, dynamic>{
                  'code': b.code,
                  'message': b.message,
                  'field': b.field,
                }
              else if (b is Map)
                b.cast<String, dynamic>(),
          ],
        };
      } else {
        details = Map<String, dynamic>.from(e.details);
      }
    }
    throw AppException(
      e.code == 'PERMISSION_DENIED' ? 'NO_PERMISSION' : e.code,
      serverMessage: e.message,
      details: details,
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

  @override
  Future<SalesRecordPaymentResult> recordPayment(SalesRecordPaymentRequest request) async {
    return const SalesRecordPaymentResult(
      transactionId: 'tx-recorded',
      outstandingMinor: 0,
      paymentStatus: 'paid',
      version: 2,
    );
  }
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

class ModuleBackedSalesCancellationRepository implements SalesCancellationRepository {
  ModuleBackedSalesCancellationRepository(this.module);
  final ISalesModule module;

  @override
  Future<CancellationPrecheckDto> precheck({
    required String salesOrderId,
    required int expectedSourceVersion,
  }) => _bridge(
    () => module.executeQueryAsync<CancellationPrecheckDto>(
      PrecheckSalesOrderCancellationQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    ),
  );

  @override
  Future<SalesOrderCancellationResultDto> confirm(
    SalesOrderCancellationRequest request,
  ) => _bridge(
    () => module.executeCommandAsync<SalesOrderCancellationResultDto>(
      ConfirmSalesOrderCancellationCommand(
        id: request.commandId,
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: request.salesOrderId,
        reason: CancellationReasonDto(reasonText: request.reasonText),
        idempotencyKey: request.idempotencyKey,
        payloadHash: request.payloadHash,
        correlationId: request.correlationId,
        expectedVersion: request.expectedOrderVersion,
        expectedSettlementVersion: request.expectedSettlementVersion,
      ),
    ),
  );
}

class ModuleBackedReturnExchangeRepository implements ReturnExchangeRepository {
  ModuleBackedReturnExchangeRepository(this.module);
  final ISalesModule module;

  @override
  Future<ReturnExchangePrecheckDto> precheck({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) => _bridge(
    () => module.executeQueryAsync<ReturnExchangePrecheckDto>(
      PrecheckReturnExchangeQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    ),
  );

  @override
  Future<ReturnableOrderLinesDto> getReturnableLines({
    required String salesOrderId,
  }) => _bridge(
    () => module.executeQueryAsync<ReturnableOrderLinesDto>(
      GetReturnableOrderLinesQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
      ),
    ),
  );

  @override
  Future<ReturnExchangePricingPreviewDto> previewPricing({
    required String salesOrderId,
    required List<ReturnExchangePricingLineInput> lines,
  }) => _bridge(
    () => module.executeQueryAsync<ReturnExchangePricingPreviewDto>(
      PreviewReturnExchangePricingQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: salesOrderId,
        lines: lines,
      ),
    ),
  );

  @override
  Future<ReturnExchangeDetailDto> getDetail({
    required String returnExchangeId,
  }) => _bridge(
    () => module.executeQueryAsync<ReturnExchangeDetailDto>(
      GetReturnExchangeDetailQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        returnExchangeId: returnExchangeId,
      ),
    ),
  );

  @override
  Future<ReturnExchangeDraftDto> start(
    ReturnExchangeStartRequest request,
  ) => _bridge(
    () => module.executeCommandAsync<ReturnExchangeDraftDto>(
      StartReturnExchangeCommand(
        id: request.commandId,
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: request.salesOrderId,
        entrySource: request.entrySource,
        lines: request.lines,
        idempotencyKey: request.idempotencyKey,
        payloadHash: request.payloadHash,
        correlationId: request.correlationId,
        expectedVersion: request.expectedVersion,
      ),
    ),
  );

  @override
  Future<ReturnExchangeDraftDto> update(
    ReturnExchangeUpdateRequest request,
  ) => _bridge(
    () => module.executeCommandAsync<ReturnExchangeDraftDto>(
      UpdateReturnExchangeCommand(
        id: request.commandId,
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        returnExchangeId: request.returnExchangeId,
        lines: request.lines,
        idempotencyKey: request.idempotencyKey,
        payloadHash: request.payloadHash,
        correlationId: request.correlationId,
        expectedVersion: request.expectedVersion,
      ),
    ),
  );

  @override
  Future<ReturnExchangeResultDto> cancel(
    ReturnExchangeMutationRequest request,
  ) => _bridge(
    () => module.executeCommandAsync<ReturnExchangeResultDto>(
      CancelReturnExchangeCommand(
        id: request.commandId,
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        returnExchangeId: request.returnExchangeId,
        idempotencyKey: request.idempotencyKey,
        payloadHash: request.payloadHash,
        correlationId: request.correlationId,
        expectedVersion: request.expectedVersion,
      ),
    ),
  );

  @override
  Future<ReturnExchangeResultDto> confirm(
    ReturnExchangeConfirmRequest request,
  ) => _bridge(
    () => module.executeCommandAsync<ReturnExchangeResultDto>(
      ConfirmReturnExchangeCommand(
        id: request.commandId,
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        returnExchangeId: request.returnExchangeId,
        idempotencyKey: request.idempotencyKey,
        payloadHash: request.payloadHash,
        correlationId: request.correlationId,
        expectedVersion: request.expectedVersion,
        settledNowMinor: request.settledNowMinor,
        paymentMethod: request.paymentMethod,
        paymentDueDate: request.paymentDueDate,
      ),
    ),
  );

  @override
  Future<ReturnExchangeValuationDto> evaluate({
    required String returnExchangeId,
    required int expectedSourceVersion,
  }) => _bridge(
    () => module.executeQueryAsync<ReturnExchangeValuationDto>(
      EvaluateReturnPricingImpactQuery(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        returnExchangeId: returnExchangeId,
        expectedSourceVersion: expectedSourceVersion,
      ),
    ),
  );
}
