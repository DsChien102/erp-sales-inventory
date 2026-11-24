import 'package:erp/core/validation/tax_code_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final formatter = TaxCodeInputFormatter();

  TextEditingValue format(String value, [String oldValue = '']) {
    return formatter.formatEditUpdate(
      TextEditingValue(text: oldValue),
      TextEditingValue(text: value),
    );
  }

  test('keeps 10 and 12 digits without a dash', () {
    expect(format('0123456789').text, '0123456789');
    expect(format('012345678901').text, '012345678901');
  });

  test('inserts a dash for 13 digits', () {
    expect(format('0123456789001').text, '0123456789-001');
  });

  test('normalizes pasted dashes and whitespace', () {
    expect(format('0123456789-001').text, '0123456789-001');
    expect(format('0123 456 789 001').text, '0123456789-001');
  });

  test('limits input to 13 digits', () {
    expect(format('012345678900123').text, '0123456789-001');
  });

  test('removing the dash from a branch code returns 12 digits', () {
    expect(format('012345678900', '0123456789-001').text, '012345678900');
  });
}
