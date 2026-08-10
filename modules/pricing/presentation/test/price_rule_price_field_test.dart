import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_pricing_presentation/presentation.dart';

void main() {
  test('PriceRuleMoneySelectionClampFormatter keeps selection in text bounds',
      () {
    const formatter = PriceRuleMoneySelectionClampFormatter();

    const value = TextEditingValue(
      text: '',
      selection: TextSelection(baseOffset: 0, extentOffset: 17),
    );

    final result = formatter.formatEditUpdate(value, value);

    expect(result.text, isEmpty);
    expect(result.selection.baseOffset, 0);
    expect(result.selection.extentOffset, 0);
  });

  test('PriceRuleMoneyMaxFormatter rejects numbers exceeding 32-bit int max', () {
    const formatter = PriceRuleMoneyMaxFormatter(2147483647);

    const oldVal = TextEditingValue(text: '2.147.483.647');
    const newVal = TextEditingValue(text: '2.147.483.648');

    final result = formatter.formatEditUpdate(oldVal, newVal);
    expect(result.text, '2.147.483.647');
  });
}
