import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:erp/features/inventory/logic/reports/supplier_purchase_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reports_fakes.dart';

void main() {
  final today = DateTime(2026, 11, 13);

  test('supplier_purchase_load_and_set_period', () async {
    final repo = FakeReportsRepository();
    final cubit = SupplierPurchaseCubit(repo, ReportPeriod.thisMonth(today));
    await cubit.load();
    expect(cubit.state.status, ReportStatus.ready);
    await cubit.setPeriod(ReportPeriod.lastMonth(today));
    expect(repo.calls, ['supplierPurchases', 'supplierPurchases']);
    await cubit.close();
  });

  test('supplier_purchase_denied', () async {
    final repo = FakeReportsRepository()
      ..error = const AppException(InventoryErrorCode.permissionDenied);
    final cubit = SupplierPurchaseCubit(repo, ReportPeriod.thisMonth(today));
    await cubit.load();
    expect(cubit.state.status, ReportStatus.denied);
    await cubit.close();
  });
}
