import 'package:erp/core/formatting/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyFormatter', () {
    test('formatMinor groups VND with đ suffix', () {
      expect(MoneyFormatter.formatMinor(1245000), '1.245.000đ');
      expect(MoneyFormatter.formatMinor(0), '0đ');
    });

    test('formatMinor keeps leading minus for negative amounts', () {
      expect(MoneyFormatter.formatMinor(-990000), '-990.000đ');
    });

    test('formatMinorPlain omits currency suffix', () {
      expect(MoneyFormatter.formatMinorPlain(360000), '360.000');
      expect(MoneyFormatter.formatMinorPlain(-990000), '-990.000');
    });

    test('format uses currency code for non-VND', () {
      expect(
        MoneyFormatter.format(amountMinor: 1245000, currencyCode: 'USD'),
        '1.245.000 USD',
      );
    });

    test('parseMinor strips grouping, suffix, and whitespace', () {
      expect(MoneyFormatter.parseMinor('1.245.000đ'), 1245000);
      expect(MoneyFormatter.parseMinor(' 360.000 '), 360000);
      expect(MoneyFormatter.parseMinor('abc'), 0);
      expect(MoneyFormatter.parseMinor(''), 0);
    });
  });
}
