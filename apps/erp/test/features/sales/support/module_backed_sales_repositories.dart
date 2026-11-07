// ignore_for_file: depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/sales_finalize_request.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:erp/features/sales/data/sales_payment_repository.dart';
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
