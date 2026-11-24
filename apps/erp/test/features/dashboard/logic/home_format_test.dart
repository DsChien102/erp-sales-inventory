import 'package:erp/features/dashboard/logic/home_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('greetingForHour', () {
    expect(greetingForHour(4), 'Chào buổi tối');
    expect(greetingForHour(5), 'Chào buổi sáng');
    expect(greetingForHour(11), 'Chào buổi sáng');
    expect(greetingForHour(12), 'Chào buổi chiều');
    expect(greetingForHour(17), 'Chào buổi chiều');
    expect(greetingForHour(18), 'Chào buổi tối');
  });

  test('dateLine', () {
    expect(dateLine(DateTime(2026, 11, 23)), 'Thứ Hai · 23/11');
    expect(dateLine(DateTime(2026, 11, 29)), 'Chủ Nhật · 29/11');
    expect(dateLine(DateTime(2026, 1, 3)), 'Thứ Bảy · 03/01');
  });

  test('weekdayShort', () {
    expect(weekdayShort(DateTime(2026, 11, 23), today: false), 'T2');
    expect(weekdayShort(DateTime(2026, 11, 28), today: false), 'T7');
    expect(weekdayShort(DateTime(2026, 11, 29), today: false), 'CN');
    expect(weekdayShort(DateTime(2026, 11, 29), today: true), 'NAY');
  });

  test('millions', () {
    expect(millions(8420000), '8,42');
    expect(millions(6100000), '6,1');
    expect(millions(0), '0');
    expect(millions(1050000), '1,05');
    expect(millions(999), '0');
    expect(millions(9600000), '9,6');
  });

  test('millionsTotal', () {
    expect(millionsTotal(52720000), '52,7 triệu');
    expect(millionsTotal(0), '0 triệu');
  });

  test('percentDelta', () {
    expect(percentDelta(8420000, 7135593), (text: '18%', up: true));
    expect(percentDelta(900, 1000), (text: '10%', up: false));
    expect(percentDelta(500, 0), isNull);
    expect(percentDelta(1000, 1000), (text: '0%', up: true));
  });

  test('countDelta', () {
    expect(countDelta(12, 9), (text: '3', up: true));
    expect(countDelta(7, 9), (text: '2', up: false));
    expect(countDelta(9, 9), isNull);
  });

  test('format: all zero', () {
    expect(percentDelta(0, 0), isNull);
    expect(countDelta(0, 0), isNull);
    expect(millions(0), '0');
    expect(millionsTotal(0), '0 triệu');
  });
}
