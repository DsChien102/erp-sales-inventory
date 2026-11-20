import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/rebate_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rebate_rules', () {
    test('parse_amount', () {
      expect(parseMoneyInput('5.000.000'), 5000000);
      expect(parseMoneyInput('5000000'), 5000000);
      expect(parseMoneyInput('5 000 000 đ'), 5000000);
      expect(parseMoneyInput(''), isNull);
      expect(parseMoneyInput('   '), isNull);
      expect(parseMoneyInput('5,5'), isNull);
      expect(parseMoneyInput('abc'), isNull);
      expect(parseMoneyInput('-100'), isNull);
    });

    test('amount_errors', () {
      const base = 100000000;
      final expectedRangeMsg =
          'Số tiền từ 1 đ đến ${MoneyFormatter.formatMinor(base)}';
      expect(rebateAmountError(null, base), 'Nhập số tiền ghi nhận');
      expect(rebateAmountError(0, base), expectedRangeMsg);
      expect(rebateAmountError(-5, base), expectedRangeMsg);
      expect(rebateAmountError(100000001, base), expectedRangeMsg);
      expect(rebateAmountError(1, base), isNull);
      expect(rebateAmountError(5000000, base), isNull);
      expect(rebateAmountError(base, base), isNull);
    });

    test('reason_needed_only_when_override', () {
      expect(needsOverrideReason(5000000, 5000000), isFalse);
      expect(needsOverrideReason(4000000, 5000000), isTrue);
      expect(needsOverrideReason(null, 5000000), isFalse);

      expect(overrideReasonError('   ', required: false), isNull);
      expect(
        overrideReasonError('   ', required: true),
        'Nhập lý do khi số tiền khác đề xuất',
      );
      expect(
        overrideReasonError('a' * 301, required: true),
        'Lý do tối đa 300 ký tự',
      );
      expect(overrideReasonError('Thoả thuận lại', required: true), isNull);
    });

    test('document_errors', () {
      expect(documentNoError('  '), 'Nhập số chứng từ');
      expect(documentNoError('a' * 61), 'Số chứng từ tối đa 60 ký tự');
      expect(documentNoError('CK-2026-11'), isNull);

      final startedOn = DateTime(2026, 11, 1);
      final today = DateTime(2026, 11, 12, 15, 30);
      expect(
        documentDateError(DateTime(2026, 11, 13), startedOn, today),
        'Ngày chứng từ không được sau hôm nay hoặc trước ngày bắt đầu chương trình',
      );
      expect(
        documentDateError(DateTime(2026, 10, 31), startedOn, today),
        'Ngày chứng từ không được sau hôm nay hoặc trước ngày bắt đầu chương trình',
      );
      expect(documentDateError(DateTime(2026, 11, 12, 8), startedOn, today), isNull);
      expect(documentDateError(DateTime(2026, 11, 1), startedOn, today), isNull);
    });

    test('cheapest_supplier', () {
      SupplierCompareRow row({
        required String id,
        bool isSystem = false,
        num? avg,
      }) {
        return SupplierCompareRow(
          partnerId: id,
          name: 'NCC $id',
          isSystem: isSystem,
          avgLandedUnitCost: avg,
          receiptCount: 1,
          paidQty: 100,
          freeQty: 0,
        );
      }

      expect(
        cheapestSupplierId([
          row(id: 'A', avg: 97200),
          row(id: 'B', avg: 99000),
          row(id: 'SYS', isSystem: true, avg: 90000),
        ]),
        'A',
      );

      // Tie keeps first row
      expect(
        cheapestSupplierId([
          row(id: 'A', avg: 95000),
          row(id: 'B', avg: 95000),
        ]),
        'A',
      );

      // Only one non-system supplier + system supplier -> null
      expect(
        cheapestSupplierId([
          row(id: 'A', avg: 97200),
          row(id: 'SYS', isSystem: true, avg: 90000),
        ]),
        isNull,
      );

      // Ignores rows with null avg
      expect(
        cheapestSupplierId([
          row(id: 'A', avg: null),
          row(id: 'B', avg: 99000),
          row(id: 'C', avg: 100000),
        ]),
        'B',
      );
    });

    test('stock_changed_since_preview', () {
      expect(stockChangedSincePreview(1500000, 1000000), isTrue);
      expect(stockChangedSincePreview(null, 1000000), isFalse);
      expect(stockChangedSincePreview(1500000, 1500000), isFalse);
    });
  });
}

