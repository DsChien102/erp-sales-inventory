/// Số liệu Trang chủ từ `sales.get_home_summary` (10-8b). Tiền là đơn vị nhỏ nhất (đồng).
class HomeSummary {
  const HomeSummary({
    required this.today,
    required this.revenueToday,
    required this.revenueYesterday,
    required this.revenueWeek,
    required this.ordersToday,
    required this.ordersYesterday,
    required this.ordersCash,
    required this.ordersBank,
    required this.ordersDebt,
    required this.ordersUninvoiced,
    required this.cashInTotal,
    required this.cashInCash,
    required this.cashInBank,
    required this.receivableTotal,
    required this.receivableOverdueCount,
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) {
    int n(Object? v) => (v as num?)?.toInt() ?? 0;
    final pay = Map<String, dynamic>.from(json['orders_by_payment'] as Map? ?? const {});
    final cashIn = Map<String, dynamic>.from(json['cash_in_today'] as Map? ?? const {});
    final week = (json['revenue_week'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .map((e) => DayRevenue(_date(e['day']), n(e['revenue'])))
        .toList(growable: false);
    return HomeSummary(
      today: _date(json['today']),
      revenueToday: n(json['revenue_today']),
      revenueYesterday: n(json['revenue_yesterday']),
      revenueWeek: week,
      ordersToday: n(json['orders_today']),
      ordersYesterday: n(json['orders_yesterday']),
      ordersCash: n(pay['cash']),
      ordersBank: n(pay['bank']),
      ordersDebt: n(pay['debt']),
      ordersUninvoiced: (json['orders_uninvoiced'] as num?)?.toInt(),
      cashInTotal: n(cashIn['total']),
      cashInCash: n(cashIn['cash']),
      cashInBank: n(cashIn['bank']),
      receivableTotal: n(json['receivable_total']),
      receivableOverdueCount: n(json['receivable_overdue_count']),
    );
  }

  static DateTime _date(Object? v) {
    final d = DateTime.parse(v as String);
    return DateTime(d.year, d.month, d.day);
  }

  final DateTime today;
  final int revenueToday;
  final int revenueYesterday;

  /// Đủ 7 ngày, cũ → mới (ngày cuối là hôm nay).
  final List<DayRevenue> revenueWeek;
  final int ordersToday;
  final int ordersYesterday;
  final int ordersCash;
  final int ordersBank;
  final int ordersDebt;

  /// `null` khi tổ chức chưa kết nối HĐĐT → ẩn ô "Chưa xuất hoá đơn".
  final int? ordersUninvoiced;
  final int cashInTotal;
  final int cashInCash;
  final int cashInBank;
  final int receivableTotal;
  final int receivableOverdueCount;
}

class DayRevenue {
  const DayRevenue(this.day, this.revenueMinor);

  final DateTime day;
  final int revenueMinor;
}
