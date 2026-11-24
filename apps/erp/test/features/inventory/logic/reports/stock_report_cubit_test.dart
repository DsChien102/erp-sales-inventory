import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/core/inventory_error_codes.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:erp/features/inventory/logic/reports/stock_report_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reports_fakes.dart';

void main() {
  final today = DateTime(2026, 11, 13);

  test('stock_report_load_ready', () async {
    final repo = FakeReportsRepository();
    final cubit = StockReportCubit(repo, ReportPeriod.thisMonth(today));
    await cubit.load();
    expect(cubit.state.status, ReportStatus.ready);
    expect(cubit.state.data!.rows, hasLength(1));
    await cubit.close();
  });

  test('stock_report_denied', () async {
    final repo = FakeReportsRepository()
      ..error = const AppException(InventoryErrorCode.permissionDenied);
    final cubit = StockReportCubit(repo, ReportPeriod.thisMonth(today));
    await cubit.load();
    expect(cubit.state.status, ReportStatus.denied);
    await cubit.close();
  });

  test('stock_report_error_has_message', () async {
    final repo = FakeReportsRepository()..error = Exception('boom');
    final cubit = StockReportCubit(repo, ReportPeriod.thisMonth(today));
    await cubit.load();
    expect(cubit.state.status, ReportStatus.error);
    expect(cubit.state.message, isNotEmpty);
    await cubit.close();
  });

  test('set_period_reloads', () async {
    final repo = FakeReportsRepository();
    final cubit = StockReportCubit(repo, ReportPeriod.thisMonth(today));
    await cubit.load();
    final last = ReportPeriod.lastMonth(today);
    await cubit.setPeriod(last);
    expect(repo.calls, ['stockReport', 'stockReport']);
    expect(repo.lastPeriod, last);
    expect(cubit.state.period, last);
    await cubit.close();
  });

  test('search_debounces_300ms', () async {
    final repo = FakeReportsRepository();
    final cubit = StockReportCubit(repo, ReportPeriod.thisMonth(today));
    await cubit.load();
    cubit.search('v');
    cubit.search('vắc');
    expect(repo.calls, hasLength(1));
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(repo.calls, hasLength(2));
    expect(repo.lastSearch, 'vắc');
    await cubit.close();
  });
}
