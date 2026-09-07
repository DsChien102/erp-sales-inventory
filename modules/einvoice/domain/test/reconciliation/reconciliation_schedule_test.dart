import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';

void main() {
  group('ReconciliationSchedule', () {
    test('maxChecks constant is 5', () {
      expect(ReconciliationSchedule.maxChecks, equals(5));
    });

    test('poll cadence is exact and one-based', () {
      expect(
        ReconciliationSchedule.delayBeforeCheck(1),
        equals(const Duration(seconds: 30)),
      );
      expect(
        ReconciliationSchedule.delayBeforeCheck(2),
        equals(const Duration(minutes: 2)),
      );
      expect(
        ReconciliationSchedule.delayBeforeCheck(3),
        equals(const Duration(minutes: 10)),
      );
      expect(
        ReconciliationSchedule.delayBeforeCheck(4),
        equals(const Duration(minutes: 30)),
      );
      expect(
        ReconciliationSchedule.delayBeforeCheck(5),
        equals(const Duration(hours: 2)),
      );
    });

    test('throws RangeError when checkSequence is out of bounds (< 1 or > 5)', () {
      expect(
        () => ReconciliationSchedule.delayBeforeCheck(0),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => ReconciliationSchedule.delayBeforeCheck(-1),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => ReconciliationSchedule.delayBeforeCheck(6),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => ReconciliationSchedule.delayBeforeCheck(10),
        throwsA(isA<RangeError>()),
      );
    });

    test('shouldMarkUnresolved marks unresolved starting at maxChecks', () {
      expect(ReconciliationSchedule.shouldMarkUnresolved(0), isFalse);
      expect(ReconciliationSchedule.shouldMarkUnresolved(1), isFalse);
      expect(ReconciliationSchedule.shouldMarkUnresolved(2), isFalse);
      expect(ReconciliationSchedule.shouldMarkUnresolved(3), isFalse);
      expect(ReconciliationSchedule.shouldMarkUnresolved(4), isFalse);
      expect(ReconciliationSchedule.shouldMarkUnresolved(5), isTrue);
      expect(ReconciliationSchedule.shouldMarkUnresolved(6), isTrue);
    });
  });
}
