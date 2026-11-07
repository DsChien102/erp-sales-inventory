// ignore_for_file: depend_on_referenced_packages

import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:vet45_sales_application/application.dart';

class FakeSalesOrderRepository implements SalesOrderRepository {
  SalesOrderResultDto? result;
  Object? error;
  final getCalls = <String>[];

  @override
  Future<SalesOrderResultDto> get({required String salesOrderId}) async {
    getCalls.add(salesOrderId);
    final e = error;
    if (e != null) throw e;
    return result!;
  }
}
