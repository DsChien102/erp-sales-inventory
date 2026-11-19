
import 'dart:async';

import 'package:erp/features/sales/data/sales_payment_repository.dart';
import 'package:erp/features/sales/data/models.dart';

class SalesPaymentCall {
  SalesPaymentCall({
    required this.salesOrderId,
    required this.expectedSourceVersion,
    this.cursor,
    this.pageSize,
  });
  final String salesOrderId;
  final int? expectedSourceVersion;
  final String? cursor;
  final int? pageSize;
}

class FakeSalesPaymentRepository implements SalesPaymentRepository {
  SalesOrderPaymentSummaryDto? summaryResult;
  SalesOrderSettlementDto? settlementResult;

  /// Hàng đợi trang giao dịch; hết thì dùng [transactionsResult].
  SalesPaymentTransactionsDto? transactionsResult;
  final List<SalesPaymentTransactionsDto> transactionsPages = [];

  Object? summaryError;
  Object? settlementError;
  Object? transactionsError;

  final summaryCalls = <SalesPaymentCall>[];
  final settlementCalls = <SalesPaymentCall>[];
  final transactionsCalls = <SalesPaymentCall>[];

  @override
  Future<SalesOrderPaymentSummaryDto> getSummary({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) async {
    summaryCalls.add(
      SalesPaymentCall(salesOrderId: salesOrderId, expectedSourceVersion: expectedSourceVersion),
    );
    final error = summaryError;
    if (error != null) throw error;
    return summaryResult!;
  }

  @override
  Future<SalesOrderSettlementDto> getSettlement({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) async {
    settlementCalls.add(
      SalesPaymentCall(salesOrderId: salesOrderId, expectedSourceVersion: expectedSourceVersion),
    );
    final error = settlementError;
    if (error != null) throw error;
    return settlementResult!;
  }

  @override
  Future<SalesPaymentTransactionsDto> getTransactions({
    required String salesOrderId,
    int? expectedSourceVersion,
    String? cursor,
    int pageSize = 25,
  }) async {
    transactionsCalls.add(
      SalesPaymentCall(
        salesOrderId: salesOrderId,
        expectedSourceVersion: expectedSourceVersion,
        cursor: cursor,
        pageSize: pageSize,
      ),
    );
    final error = transactionsError;
    if (error != null) throw error;
    if (transactionsPages.isNotEmpty) return transactionsPages.removeAt(0);
    return transactionsResult!;
  }
}
