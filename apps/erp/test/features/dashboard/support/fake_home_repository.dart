import 'dart:async';

import 'package:erp/features/dashboard/data/home_repository.dart';
import 'package:erp/features/dashboard/data/models/home_summary.dart';

/// Số đúng `SAMPLE` của prototype (`specs/prototype/home/html/app/board.js:14-35`).
HomeSummary sampleHomeSummary({
  int revenueToday = 8420000,
  int revenueYesterday = 7135593,
  List<int>? week,
  int ordersToday = 12,
  int ordersYesterday = 9,
  int? ordersUninvoiced = 2,
  int receivableTotal = 24600000,
  int receivableOverdueCount = 3,
  int cashInTotal = 9560000,
  int cashInCash = 4150000,
  int cashInBank = 5410000,
  int ordersCash = 7,
  int ordersBank = 4,
  int ordersDebt = 1,
}) {
  final values = week ?? [6100000, 7400000, 5200000, 8900000, 7100000, 9600000, revenueToday];
  return HomeSummary(
    today: DateTime(2026, 11, 23),
    revenueToday: revenueToday,
    revenueYesterday: revenueYesterday,
    revenueWeek: [
      for (var i = 0; i < 7; i++) DayRevenue(DateTime(2026, 11, 17 + i), values[i]),
    ],
    ordersToday: ordersToday,
    ordersYesterday: ordersYesterday,
    ordersCash: ordersCash,
    ordersBank: ordersBank,
    ordersDebt: ordersDebt,
    ordersUninvoiced: ordersUninvoiced,
    cashInTotal: cashInTotal,
    cashInCash: cashInCash,
    cashInBank: cashInBank,
    receivableTotal: receivableTotal,
    receivableOverdueCount: receivableOverdueCount,
  );
}

/// Cửa hàng mới: mọi số 0.
HomeSummary emptyHomeSummary() => sampleHomeSummary(
  revenueToday: 0,
  revenueYesterday: 0,
  week: List.filled(7, 0),
  ordersToday: 0,
  ordersYesterday: 0,
  ordersUninvoiced: 0,
  receivableTotal: 0,
  receivableOverdueCount: 0,
  cashInTotal: 0,
  cashInCash: 0,
  cashInBank: 0,
  ordersCash: 0,
  ordersBank: 0,
  ordersDebt: 0,
);

class FakeHomeRepository implements HomeRepository {
  FakeHomeRepository({HomeSummary? summary, this.error, this.gate, this.tenant = 'org-001'})
    : summary = summary ?? sampleHomeSummary();

  HomeSummary summary;
  Object? error;

  /// Có thì `fetch()` chờ completer này (giữ trạng thái đang tải).
  Completer<HomeSummary>? gate;
  String tenant;
  int calls = 0;

  @override
  Future<HomeSummary> fetch() async {
    calls++;
    final g = gate;
    if (g != null) return g.future;
    final e = error;
    if (e != null) throw e;
    return summary;
  }
}
