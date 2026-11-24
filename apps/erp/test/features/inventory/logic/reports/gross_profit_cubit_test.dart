import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/logic/reports/gross_profit_cubit.dart';
import 'package:erp/features/inventory/logic/reports/gross_profit_state.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reports_fakes.dart';

void main() {
  final today = DateTime(2026, 11, 13);

  test('gross_profit_set_mode_calls_order_rpc', () async {
    final repo = FakeReportsRepository();
    final cubit = GrossProfitCubit(repo, ReportPeriod.thisMonth(today));
    await cubit.load();
    expect(repo.calls, ['grossProfitByProduct']);
    await cubit.setMode(GrossProfitMode.order);
    expect(repo.calls, ['grossProfitByProduct', 'grossProfitByOrder']);
    expect(cubit.state.byOrder, isNotNull);
    expect(cubit.state.mode, GrossProfitMode.order);
    await cubit.close();
  });

  test('gross_profit_denied', () async {
    final repo = FakeReportsRepository()
      ..error = const AppException(InventoryErrorCode.permissionDenied);
    final cubit = GrossProfitCubit(repo, ReportPeriod.thisMonth(today));
    await cubit.load();
    expect(cubit.state.status, ReportStatus.denied);
    await cubit.close();
  });

  test('set_period_reloads', () async {
    final repo = FakeReportsRepository();
    final cubit = GrossProfitCubit(repo, ReportPeriod.thisMonth(today));
    await cubit.load();
    await cubit.setPeriod(ReportPeriod.lastMonth(today));
    expect(repo.calls, hasLength(2));
    expect(repo.lastPeriod, ReportPeriod.lastMonth(today));
    await cubit.close();
  });
}
