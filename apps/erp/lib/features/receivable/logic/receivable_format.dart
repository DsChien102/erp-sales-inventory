import 'package:erp/core/formatting/money_formatter.dart';

/// "18.000.000 ₫" (TH-06 5.6) — khác `MoneyFormatter.formatMinor` (`18.000.000đ`).
String formatVnd(int minor) => '${MoneyFormatter.formatMinorPlain(minor)} ₫';

/// "18.000.000" (lịch sử, khối chia, dòng đơn CN-03).
String formatVndBare(int minor) => MoneyFormatter.formatMinorPlain(minor);

enum DueKind { overdue, today, upcoming, none }

class DueLabel {
  const DueLabel(this.kind, this.text, {this.days});

  final DueKind kind;
  final int? days;
  final String text;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

String _two(int n) => n.toString().padLeft(2, '0');

DueLabel _label({required int overdueDays, required DateTime? dueDate, required DateTime today}) {
  if (overdueDays > 0) {
    return DueLabel(DueKind.overdue, 'Quá hạn $overdueDays ngày', days: overdueDays);
  }
  if (dueDate == null) return const DueLabel(DueKind.none, 'Không có hẹn');
  final due = _day(dueDate);
  final now = _day(today);
  if (!due.isAfter(now)) return const DueLabel(DueKind.today, 'Đến hạn hôm nay');
  return DueLabel(DueKind.upcoming, 'Hẹn ${_two(due.day)}/${_two(due.month)}');
}

/// BR-30: số ngày quá hạn lấy từ server; app chỉ tách "hôm nay" / "hẹn".
DueLabel orderDueLabel({
  required DateTime? dueDate,
  required int overdueDays,
  required DateTime today,
}) => _label(overdueDays: overdueDays, dueDate: dueDate, today: today);

DueLabel customerDueLabel({
  required int maxOverdueDays,
  required DateTime? nextDueDate,
  required DateTime today,
}) => _label(overdueDays: maxOverdueDays, dueDate: nextDueDate, today: today);
