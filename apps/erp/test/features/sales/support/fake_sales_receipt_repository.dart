// ignore_for_file: depend_on_referenced_packages

import 'package:erp/features/sales/data/sales_receipt_repository.dart';
import 'package:vet45_sales_application/application.dart';

class FakeSalesReceiptRepository implements SalesReceiptRepository {
  SalesReceiptDto? generateResult;
  final generateResults = <SalesReceiptDto>[];
  Object? generateError;
  final generateCalls = <({String salesOrderId, int expectedVersion})>[];

  SalesReceiptDto? getResult;
  Object? getError;
  final getCalls = <({String receiptId, int? expectedSourceVersion})>[];

  SalesReceiptDocumentDto? originalResult;
  Object? originalError;
  final originalCalls = <String>[];

  SalesReceiptDto? printedResult;
  Object? printedError;
  final printedCalls = <({String receiptId, String commandId, String idempotencyKey})>[];

  SalesReceiptDto? sharedResult;
  Object? sharedError;
  final sharedCalls = <({String receiptId, String commandId, String idempotencyKey})>[];

  @override
  Future<SalesReceiptDto> generate({
    required String salesOrderId,
    required int expectedVersion,
  }) async {
    generateCalls.add((salesOrderId: salesOrderId, expectedVersion: expectedVersion));
    final e = generateError;
    if (e != null) throw e;
    if (generateResults.isNotEmpty) return generateResults.removeAt(0);
    return generateResult!;
  }

  @override
  Future<SalesReceiptDto> get({
    required String receiptId,
    int? expectedSourceVersion,
  }) async {
    getCalls.add((receiptId: receiptId, expectedSourceVersion: expectedSourceVersion));
    final e = getError;
    if (e != null) throw e;
    return getResult!;
  }

  @override
  Future<SalesReceiptDocumentDto> getOriginal({required String salesOrderId}) async {
    originalCalls.add(salesOrderId);
    final e = originalError;
    if (e != null) throw e;
    return originalResult!;
  }

  @override
  Future<SalesReceiptDto> recordPrinted({
    required String receiptId,
    required String commandId,
    required String idempotencyKey,
  }) async {
    printedCalls.add((receiptId: receiptId, commandId: commandId, idempotencyKey: idempotencyKey));
    final e = printedError;
    if (e != null) throw e;
    return printedResult!;
  }

  @override
  Future<SalesReceiptDto> recordShared({
    required String receiptId,
    required String commandId,
    required String idempotencyKey,
  }) async {
    sharedCalls.add((receiptId: receiptId, commandId: commandId, idempotencyKey: idempotencyKey));
    final e = sharedError;
    if (e != null) throw e;
    return sharedResult!;
  }
}
