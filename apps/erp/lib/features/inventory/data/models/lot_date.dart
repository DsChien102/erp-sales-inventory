import 'package:equatable/equatable.dart';

enum DatePrecision { day, month, year }

/// Ngày trên bao bì, giữ đúng cách ghi gốc (SCR-084 v3.9.2).
class LotDate extends Equatable {
  const LotDate({required this.year, this.month, this.day});

  final int year;
  final int? month;
  final int? day;

  DatePrecision get precision =>
      day != null ? DatePrecision.day : (month != null ? DatePrecision.month : DatePrecision.year);

  /// Ngày đầu kỳ — chỉ dùng để so sánh.
  DateTime get start => DateTime(year, month ?? 1, day ?? 1);

  /// 15/09/2026 · 11/2027 · 2027
  String format() {
    String two(int v) => v.toString().padLeft(2, '0');
    return switch (precision) {
      DatePrecision.day => '${two(day!)}/${two(month!)}/$year',
      DatePrecision.month => '${two(month!)}/$year',
      DatePrecision.year => '$year',
    };
  }

  /// Hai ngày không mâu thuẫn: trùng ở mọi phần mà cả hai cùng có.
  bool isConsistentWith(LotDate other) =>
      year == other.year &&
      (month == null || other.month == null || month == other.month) &&
      (day == null || other.day == null || day == other.day);

  static LotDate? tryParse(String input, DatePrecision precision) {
    final parts = input.trim().split('/');
    final expected = switch (precision) {
      DatePrecision.day => 3,
      DatePrecision.month => 2,
      DatePrecision.year => 1,
    };
    if (parts.length != expected) return null;
    final nums = parts.map(int.tryParse).toList();
    if (nums.any((n) => n == null)) return null;
    final year = nums.last!;
    if (year < 1900 || year > 2200) return null;
    final month = expected >= 2 ? nums[expected - 2] : null;
    final day = expected == 3 ? nums[0] : null;
    if (month != null && (month < 1 || month > 12)) return null;
    if (day != null) {
      final d = DateTime(year, month!, day);
      if (d.month != month || d.day != day) return null; // 31/02 sai
    }
    return LotDate(year: year, month: month, day: day);
  }

  /// Tự nhận diện độ chính xác theo số đoạn phân cách bởi `/`
  /// 3 đoạn -> day (dd/mm/yyyy), 2 đoạn -> month (mm/yyyy), 1 đoạn -> year (yyyy)
  static LotDate? tryParseAuto(String input) {
    final parts = input.trim().split('/');
    return switch (parts.length) {
      3 => tryParse(input, DatePrecision.day),
      2 => tryParse(input, DatePrecision.month),
      1 => tryParse(input, DatePrecision.year),
      _ => null,
    };
  }

  @override
  List<Object?> get props => [year, month, day];
}
