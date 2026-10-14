import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('B1: LotDate.tryParse đúng cách ghi', () {
    test('ngày / tháng / năm', () {
      final d = LotDate.tryParse('15/09/2026', DatePrecision.day)!;
      expect((d.day, d.month, d.year), (15, 9, 2026));
      expect(d.precision, DatePrecision.day);
      expect(d.format(), '15/09/2026');

      final m = LotDate.tryParse('11/2027', DatePrecision.month)!;
      expect((m.day, m.month, m.year), (null, 11, 2027));
      expect(m.format(), '11/2027');

      final y = LotDate.tryParse('2027', DatePrecision.year)!;
      expect((y.day, y.month, y.year), (null, null, 2027));
      expect(y.format(), '2027');
    });
  });

  group('B2: LotDate.tryParse từ chối đầu vào sai', () {
    test('ngày không tồn tại, tháng 13, sai dấu', () {
      expect(LotDate.tryParse('31/02/2026', DatePrecision.day), isNull);
      expect(LotDate.tryParse('13/2026', DatePrecision.month), isNull);
      expect(LotDate.tryParse('15-09-2026', DatePrecision.day), isNull);
      expect(LotDate.tryParse('', DatePrecision.year), isNull);
    });
  });
}
