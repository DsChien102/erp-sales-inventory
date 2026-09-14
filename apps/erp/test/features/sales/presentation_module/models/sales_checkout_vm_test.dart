import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  group('SalesCheckoutVm.canFinalizePayment', () {
    SalesCheckoutVm vm({
      bool isWalkIn = false,
      int provisionalTotal = 1000000,
      int cash = 0,
      int bank = 0,
      DateTime? dueDate,
    }) {
      return SalesCheckoutVm(
        runtimeDraftId: 'draft-1',
        provisionalTotalAmountMinor: provisionalTotal,
        isWalkIn: isWalkIn,
        cashPaidMinor: cash,
        bankPaidMinor: bank,
        dueDate: dueDate,
      );
    }

    test('fully paid customer order can finalize', () {
      expect(vm(cash: 1000000).canFinalizePayment, isTrue);
    });

    test('customer order with receivable but no due date cannot finalize', () {
      expect(vm(cash: 400000).canFinalizePayment, isFalse);
    });

    test('customer order with receivable and a due date can finalize', () {
      expect(
        vm(cash: 400000, dueDate: DateTime(2026, 8, 30)).canFinalizePayment,
        isTrue,
      );
    });

    test('mixed split leaving a receivable without due date cannot finalize', () {
      expect(vm(cash: 400000, bank: 100000).canFinalizePayment, isFalse);
    });

    test('walk-in must be fully paid regardless of due date', () {
      expect(vm(isWalkIn: true, cash: 400000).canFinalizePayment, isFalse);
      expect(vm(isWalkIn: true, cash: 1000000).canFinalizePayment, isTrue);
    });
  });
}
