
import 'package:erp/features/sales/data/models/sales_cancellation_request.dart';
import 'package:erp/features/sales/data/sales_cancellation_repository.dart';
import 'package:erp/features/sales/data/models.dart';

class FakeSalesCancellationRepository implements SalesCancellationRepository {
  CancellationPrecheckDto? precheckResult;
  final precheckResults = <CancellationPrecheckDto>[];
  Object? precheckError;
  final precheckCalls = <({String salesOrderId, int expectedSourceVersion})>[];

  SalesOrderCancellationResultDto? confirmResult;
  final confirmResults = <SalesOrderCancellationResultDto>[];
  Object? confirmError;
  final confirmCalls = <SalesOrderCancellationRequest>[];

  @override
  Future<CancellationPrecheckDto> precheck({
    required String salesOrderId,
    required int expectedSourceVersion,
  }) async {
    precheckCalls.add((
      salesOrderId: salesOrderId,
      expectedSourceVersion: expectedSourceVersion,
    ));
    final e = precheckError;
    if (e != null) throw e;
    if (precheckResults.isNotEmpty) return precheckResults.removeAt(0);
    return precheckResult!;
  }

  @override
  Future<SalesOrderCancellationResultDto> confirm(
    SalesOrderCancellationRequest request,
  ) async {
    confirmCalls.add(request);
    final e = confirmError;
    if (e != null) throw e;
    if (confirmResults.isNotEmpty) return confirmResults.removeAt(0);
    return confirmResult!;
  }
}

