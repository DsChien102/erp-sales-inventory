import 'package:equatable/equatable.dart';

enum ReportPeriodKind { thisMonth, lastMonth, custom }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _pad2(int n) => n.toString().padLeft(2, '0');

/// `yyyy-MM-dd` — dạng gửi RPC và đặt trên query route.
String reportIsoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${_pad2(d.month)}-${_pad2(d.day)}';

/// Kỳ báo cáo theo ngày nghiệp vụ (cả hai đầu đều tính).
class ReportPeriod extends Equatable {
  ReportPeriod({required DateTime from, required DateTime to})
      : from = _dateOnly(from),
        to = _dateOnly(to);

  final DateTime from;
  final DateTime to;

  /// 01 → hôm nay.
  factory ReportPeriod.thisMonth(DateTime today) {
    final t = _dateOnly(today);
    return ReportPeriod(from: DateTime(t.year, t.month, 1), to: t);
  }

  /// Đủ tháng trước.
  factory ReportPeriod.lastMonth(DateTime today) {
    final t = _dateOnly(today);
    return ReportPeriod(
      from: DateTime(t.year, t.month - 1, 1),
      to: DateTime(t.year, t.month, 0),
    );
  }

  /// 01 → `min(cuối tháng, hôm nay)` của tháng `month`.
  factory ReportPeriod.ofMonth(DateTime month, DateTime today) {
    final t = _dateOnly(today);
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    return ReportPeriod(from: first, to: last.isAfter(t) ? t : last);
  }

  /// Đọc `?from=yyyy-MM-dd&to=yyyy-MM-dd`; thiếu hoặc sai ⇒ tháng này.
  factory ReportPeriod.fromQuery(
    String? from,
    String? to,
    DateTime today,
  ) {
    final f = from == null ? null : DateTime.tryParse(from.trim());
    final t = to == null ? null : DateTime.tryParse(to.trim());
    if (f == null || t == null || _dateOnly(f).isAfter(_dateOnly(t))) {
      return ReportPeriod.thisMonth(today);
    }
    return ReportPeriod(from: f, to: t);
  }

  Map<String, String> toQuery() => {
        'from': reportIsoDate(from),
        'to': reportIsoDate(to),
      };

  /// `to ≥ hôm nay` ⇒ cột "Khả dụng" có nghĩa.
  bool includesToday(DateTime today) => !to.isBefore(_dateOnly(today));

  @override
  List<Object?> get props => [from, to];
}

ReportPeriodKind kindOf(ReportPeriod p, DateTime today) {
  if (p == ReportPeriod.thisMonth(today)) return ReportPeriodKind.thisMonth;
  if (p == ReportPeriod.lastMonth(today)) return ReportPeriodKind.lastMonth;
  return ReportPeriodKind.custom;
}

/// `dd/MM – dd/MM/yyyy` (khác năm ⇒ ghi đủ năm hai đầu).
String reportPeriodRange(ReportPeriod p) {
  final a = '${_pad2(p.from.day)}/${_pad2(p.from.month)}';
  final b = '${_pad2(p.to.day)}/${_pad2(p.to.month)}/${p.to.year}';
  if (p.from.year != p.to.year) {
    return '$a/${p.from.year} – $b';
  }
  return '$a – $b';
}

/// `Tháng MM/yyyy` khi `from` là mùng 1 và cùng tháng với `to`; khác ⇒ khoảng ngày.
String reportPeriodLabel(ReportPeriod p) {
  if (p.from.day == 1 &&
      p.from.year == p.to.year &&
      p.from.month == p.to.month) {
    return 'Tháng ${_pad2(p.from.month)}/${p.from.year}';
  }
  return reportPeriodRange(p);
}

/// Lỗi ô "Tùy chọn" của sheet "Chọn kỳ"; hợp lệ ⇒ `null`.
String? customRangeError(DateTime? from, DateTime? to) {
  if (from == null || to == null) return 'Nhập ngày theo dạng dd/mm/yyyy';
  if (_dateOnly(from).isAfter(_dateOnly(to))) {
    return 'Ngày bắt đầu phải trước ngày kết thúc';
  }
  return null;
}
