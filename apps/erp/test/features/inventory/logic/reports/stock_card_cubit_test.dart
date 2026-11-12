import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:erp/features/inventory/logic/reports/stock_card_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reports_fakes.dart';

void main() {
  final today = DateTime(2026, 11, 13);

  test('stock_card_select_lot_reloads_with_lot', () async {
    final repo = FakeReportsRepository();
    final cubit = StockCardCubit(repo, 'p1', ReportPeriod.thisMonth(today));
    await cubit.load();
    expect(repo.lastLotId, isNull);
    await cubit.selectLot('la');
    expect(repo.calls, ['stockCard', 'stockCard']);
    expect(repo.lastLotId, 'la');
    expect(cubit.state.lotId, 'la');
    expect(cubit.state.data!.closingValue, isNull);
    await cubit.selectLot(null);
    expect(repo.lastLotId, isNull);
    expect(cubit.state.lotId, isNull);
    expect(cubit.state.status, ReportStatus.ready);
    await cubit.close();
  });

  test('set_period_reloads', () async {
    final repo = FakeReportsRepository();
    final cubit = StockCardCubit(repo, 'p1', ReportPeriod.thisMonth(today));
    await cubit.load();
    await cubit.setPeriod(ReportPeriod.lastMonth(today));
    expect(repo.calls, hasLength(2));
    expect(repo.lastPeriod, ReportPeriod.lastMonth(today));
    await cubit.close();
  });
}
