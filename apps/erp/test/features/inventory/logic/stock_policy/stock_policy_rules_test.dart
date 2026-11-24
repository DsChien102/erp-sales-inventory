import 'package:erp/features/inventory/logic/stock_policy/stock_policy_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stock_policy_rules', () {
    test('row_error_cases', () {
      expect(thresholdRowError('', '', configured: false), isNull);
      expect(thresholdRowError('', '', configured: true), capRowError);
      expect(thresholdRowError('10', '', configured: false), capRowError);
      expect(thresholdRowError('10', '5', configured: false), capRowError);
      expect(thresholdRowError('-1', '5', configured: false), capRowError);
      expect(thresholdRowError('1.5', '5', configured: false), capRowError);
      expect(thresholdRowError('10', '10', configured: false), isNull);
      expect(thresholdRowError('10', '20', configured: false), isNull);
    });

    test('days_errors', () {
      expect(defaultDaysError(''), isNull);
      expect(defaultDaysError('0'), capDaysError);
      expect(defaultDaysError('-5'), capDaysError);
      expect(defaultDaysError('abc'), capDaysError);
      expect(defaultDaysError('30'), isNull);

      expect(overrideDaysError(''), capDaysError);
      expect(overrideDaysError('0'), capDaysError);
      expect(overrideDaysError('60'), isNull);
    });

    test('single_blocked', () {
      expect(singleBlocked('', '', configured: false), isTrue);
      expect(singleBlocked('', '', configured: true), isTrue);
      expect(singleBlocked('10', '5', configured: false), isTrue);
      expect(singleBlocked('10', '20', configured: false), isFalse);
    });

    test('low_count', () {
      final items = [
        (available: 0, threshold: 10, hasExpired: false, hasNearExpiry: false), // out, not low
        (available: 5, threshold: 10, hasExpired: false, hasNearExpiry: false), // low
        (available: 10, threshold: 10, hasExpired: false, hasNearExpiry: false), // low
        (available: 15, threshold: 10, hasExpired: false, hasNearExpiry: false), // normal
        (available: 8, threshold: null, hasExpired: false, hasNearExpiry: false), // notConfigured
      ];
      expect(lowCount(items), 2);
    });
  });
}

