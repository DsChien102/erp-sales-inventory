import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VDateTime', () {
    test('toIct correctly shifts UTC instant by +7 hours', () {
      final utcInstant = DateTime.utc(2026, 9, 9, 9, 2);
      final ict = VDateTime.toIct(utcInstant);

      expect(ict.year, 2026);
      expect(ict.month, 9);
      expect(ict.day, 9);
      expect(ict.hour, 16);
      expect(ict.minute, 2);
    });

    test('toIct crosses date boundary around midnight UTC', () {
      // 18:30 UTC on 2026-09-08 is 01:30 ICT on 2026-09-09
      final utcInstant = DateTime.utc(2026, 9, 8, 18, 30);
      final ict = VDateTime.toIct(utcInstant);

      expect(ict.year, 2026);
      expect(ict.month, 9);
      expect(ict.day, 9);
      expect(ict.hour, 1);
      expect(ict.minute, 30);
    });

    test('date and time formatting output matches ICT wall clock', () {
      final utcInstant = DateTime.utc(2026, 9, 9, 9, 2);
      expect(VDateTime.date(utcInstant), '09/09/2026');
      expect(VDateTime.time(utcInstant), '16:02');
      expect(VDateTime.dateTime(utcInstant), '09/09/2026 · 16:02');
    });

    test('calendarDate formats without timezone shifting', () {
      final calendarDateUtc = DateTime.utc(2026, 9, 9);
      expect(VDateTime.calendarDate(calendarDateUtc), '09/09/2026');

      final calendarDateLocal = DateTime(2026, 8, 30);
      expect(VDateTime.calendarDate(calendarDateLocal), '30/08/2026');
    });

    test('parseAndFormatCalendarDate safely formats YYYY-MM-DD strings', () {
      expect(VDateTime.parseAndFormatCalendarDate('2026-09-09'), '09/09/2026');
      expect(VDateTime.parseAndFormatCalendarDate('2026-1-5'), '05/01/2026');
      expect(VDateTime.parseAndFormatCalendarDate(null), 'Không giới hạn');
      expect(VDateTime.parseAndFormatCalendarDate(''), 'Không giới hạn');
      expect(
        VDateTime.parseAndFormatCalendarDate(null, fallback: '--'),
        '--',
      );
    });

    test('currentBusinessDate returns ICT calendar date', () {
      // At 23:00 UTC on 2026-09-08 -> 06:00 ICT on 2026-09-09
      final earlyMorning = DateTime.utc(2026, 9, 8, 23, 0);
      final businessDate = VDateTime.currentBusinessDate(earlyMorning);

      expect(businessDate, DateTime.utc(2026, 9, 9));
    });

    test('businessDayRangeUtc returns exact [00:00 ICT, 24:00 ICT) in UTC', () {
      final instant = DateTime.utc(2026, 9, 9, 10, 0); // 17:00 ICT on Sept 9
      final range = VDateTime.businessDayRangeUtc(now: instant, days: 1);

      // Sept 9 ICT starts at 2026-09-08 17:00:00Z and ends at 2026-09-09 17:00:00Z
      expect(range.fromUtc, DateTime.utc(2026, 9, 8, 17, 0));
      expect(range.toUtc, DateTime.utc(2026, 9, 9, 17, 0));
    });

    test('businessDayRangeUtc for 7 days spans 7 complete ICT days', () {
      final instant = DateTime.utc(2026, 9, 9, 10, 0); // Sept 9 ICT
      final range = VDateTime.businessDayRangeUtc(now: instant, days: 7);

      // Sept 3 to Sept 9 (7 days)
      expect(range.fromUtc, DateTime.utc(2026, 9, 2, 17, 0));
      expect(range.toUtc, DateTime.utc(2026, 9, 9, 17, 0));
    });
  });
}
