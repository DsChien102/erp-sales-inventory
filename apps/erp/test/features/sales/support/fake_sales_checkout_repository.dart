// ignore_for_file: depend_on_referenced_packages

import 'package:erp/features/sales/data/models/sales_finalize_request.dart';
import 'package:erp/features/sales/data/sales_checkout_repository.dart';
import 'package:erp/features/sales/data/models.dart';

class SalesPrecheckCall {
  SalesPrecheckCall({
    required this.storeId,
    required this.customerId,
    required this.currencyCode,
    required this.paymentDueDate,
    required this.lines,
    required this.paymentIntents,
    required this.expectedSourceVersion,
  });
  final String storeId;
  final String? customerId;
  final String currencyCode;
  final DateTime? paymentDueDate;
  final List<CheckoutLineInput> lines;
  final List<PaymentIntentInput> paymentIntents;
  final int? expectedSourceVersion;
}

class SalesGetResultCall {
  SalesGetResultCall({required this.storeId, required this.idempotencyKey});
  final String storeId;
  final String idempotencyKey;
}

/// Hàng đợi `finalizeResults` / `getResultResults`: phần tử là [CheckoutResultDto] (trả về)
/// hoặc đối tượng lỗi (ném). Hết hàng đợi → dùng mặc định (succeeded).
class FakeSalesCheckoutRepository implements SalesCheckoutRepository {
  FakeSalesCheckoutRepository({this.precheckResult});

  CheckoutPrecheckDto? precheckResult;
  Object? precheckError;
  Object? finalizeError;
  Object? getResultError;
  final List<Object> finalizeResults = [];
  final List<Object> getResultResults = [];

  final precheckCalls = <SalesPrecheckCall>[];
  final finalizeCalls = <SalesFinalizeRequest>[];
  final getResultCalls = <SalesGetResultCall>[];

  @override
  Future<CheckoutPrecheckDto> precheck({
    required String storeId,
    String? customerId,
    required String currencyCode,
    DateTime? paymentDueDate,
    required List<CheckoutLineInput> lines,
    required List<PaymentIntentInput> paymentIntents,
    int? expectedSourceVersion,
  }) async {
    precheckCalls.add(
      SalesPrecheckCall(
        storeId: storeId,
        customerId: customerId,
        currencyCode: currencyCode,
        paymentDueDate: paymentDueDate,
        lines: lines,
        paymentIntents: paymentIntents,
        expectedSourceVersion: expectedSourceVersion,
      ),
    );
    final error = precheckError;
    if (error != null) throw error;
    return precheckResult!;
  }

  @override
  Future<CheckoutResultDto> finalize(SalesFinalizeRequest request) async {
    finalizeCalls.add(request);
    final error = finalizeError;
    if (error != null) throw error;
    return _next(
      finalizeResults,
      CheckoutResultDto(
        idempotencyKey: request.idempotencyKey,
        salesOrderId: 'order-1',
        salesOrderVersion: 1,
        status: CheckoutResultStatus.succeeded,
      ),
    );
  }

  @override
  Future<CheckoutResultDto> getResult({
    required String storeId,
    required String idempotencyKey,
  }) async {
    getResultCalls.add(SalesGetResultCall(storeId: storeId, idempotencyKey: idempotencyKey));
    final error = getResultError;
    if (error != null) throw error;
    return _next(
      getResultResults,
      CheckoutResultDto(
        idempotencyKey: idempotencyKey,
        salesOrderId: 'order-1',
        salesOrderVersion: 1,
        status: CheckoutResultStatus.succeeded,
      ),
    );
  }

  CheckoutResultDto _next(List<Object> queue, CheckoutResultDto fallback) {
    if (queue.isEmpty) return fallback;
    final item = queue.removeAt(0);
    if (item is CheckoutResultDto) return item;
    throw item;
  }
}
