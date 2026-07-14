import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_presentation/presentation.dart';

void main() {
  group('formatCatalogCurrency', () {
    test('rounds floating point list price to match detail display', () {
      expect(formatCatalogCurrency(114999.99999999999), '115,000 đ');
    });

    test('formats thousand separators', () {
      expect(formatCatalogCurrency(100000), '100,000 đ');
      expect(formatCatalogCurrency(115000), '115,000 đ');
    });

    test('null is placeholder', () {
      expect(formatCatalogCurrency(null), '--');
    });
  });

  group('formatCatalogCurrencyAmount', () {
    test('formats without suffix', () {
      expect(formatCatalogCurrencyAmount(45000), '45,000');
      expect(formatCatalogCurrencyAmount(null), isNull);
    });
  });

  group('parseCatalogCurrencyAmount', () {
    test('parses dot and comma separators', () {
      expect(parseCatalogCurrencyAmount('45.000'), 45000);
      expect(parseCatalogCurrencyAmount('45,000'), 45000);
      expect(parseCatalogCurrencyAmount(''), isNull);
    });
  });
}
