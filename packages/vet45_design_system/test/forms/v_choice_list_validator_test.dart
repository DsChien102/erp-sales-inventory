import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';

void main() {
  group('VChoiceListValidator', () {
    test('optional empty selection is valid', () {
      expect(
        VChoiceListValidator.validate(<String>[], isRequired: false),
        isNull,
      );
    });

    test('required empty selection returns message', () {
      expect(
        VChoiceListValidator.validate(<String>[], isRequired: true),
        VChoiceListValidator.defaultRequiredMessage,
      );
    });

    test('rejects fewer than minSelections', () {
      expect(
        VChoiceListValidator.validate(
          ['a'],
          isRequired: false,
          minSelections: 2,
        ),
        VChoiceListValidator.defaultMinSelectionsMessage(2),
      );
    });

    test('rejects more than maxSelections', () {
      expect(
        VChoiceListValidator.validate(
          ['a', 'b', 'c'],
          isRequired: false,
          maxSelections: 2,
        ),
        VChoiceListValidator.defaultMaxSelectionsMessage(2),
      );
    });

    test('updateSelected single choice replaces selection', () {
      expect(
        VChoiceListValidator.updateSelected(
          'b',
          true,
          const ['a'],
          allowMultiple: false,
        ),
        ['b'],
      );
    });

    test('updateSelected multiple choice toggles values', () {
      expect(
        VChoiceListValidator.updateSelected(
          'b',
          true,
          const ['a'],
          allowMultiple: true,
        ),
        ['a', 'b'],
      );
      expect(
        VChoiceListValidator.updateSelected(
          'a',
          false,
          const ['a', 'b'],
          allowMultiple: true,
        ),
        ['b'],
      );
    });
  });
}
