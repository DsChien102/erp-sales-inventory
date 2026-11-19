import 'package:erp/features/receivable/logic/receivable_allocation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/receivable_fixtures.dart' as fx;

List<(String, int, int)> _t(List<CollectionAllocation> l) =>
    [for (final a in l) (a.salesOrderId, a.allocatedMinor, a.outstandingAfterMinor)];

void main() {
  final orders = fx.tuanOrders;

  group('allocateOldestFirst', () {
    test('chia cũ trước', () {
      final r = allocateOldestFirst([orders[0], orders[1]], 10000000);
      expect(_t(r), [('so-001', 4000000, 0), ('so-002', 6000000, 2000000)]);
    });
    test('số tiền 0 → rỗng', () {
      expect(allocateOldestFirst(orders, 0), isEmpty);
    });
    test('đúng tổng → mọi đơn hết nợ', () {
      final r = allocateOldestFirst(orders, 18000000);
      expect(r, hasLength(3));
      expect(r.every((a) => a.outstandingAfterMinor == 0), isTrue);
    });
  });

  group('collectionPreview', () {
    test('chọn cả 3, 10tr', () {
      final p = collectionPreview(
        orders: orders,
        selectedIds: {'so-001', 'so-002', 'so-003'},
        amountMinor: 10000000,
      );
      expect(_t(p.allocations), [('so-001', 4000000, 0), ('so-002', 6000000, 2000000)]);
      expect(p.afterMinor, 8000000);
      expect(p.canSubmit, isTrue);
      expect(p.scopeTotal, 18000000);
      expect(p.customerTotal, 18000000);
    });
    test('chọn một đơn, đúng còn nợ', () {
      final p = collectionPreview(orders: orders, selectedIds: {'so-002'}, amountMinor: 8000000);
      expect(_t(p.allocations), [('so-002', 8000000, 0)]);
      expect(p.afterMinor, 10000000);
    });
    test('chọn đơn 1 và 3, 5tr', () {
      final p = collectionPreview(
        orders: orders,
        selectedIds: {'so-001', 'so-003'},
        amountMinor: 5000000,
      );
      expect(_t(p.allocations), [('so-001', 4000000, 0), ('so-003', 1000000, 5000000)]);
      expect(p.afterMinor, 13000000);
    });
    test('vượt', () {
      final p = collectionPreview(orders: orders, selectedIds: {'so-002'}, amountMinor: 8000001);
      expect(p.over, isTrue);
      expect(p.allocations, isEmpty);
      expect(p.afterMinor, 18000000);
      expect(p.canSubmit, isFalse);
    });
    test('không chọn đơn', () {
      final p = collectionPreview(orders: orders, selectedIds: {}, amountMinor: 0);
      expect(p.scopeTotal, 0);
      expect(p.canSubmit, isFalse);
    });
    test('applicable giữ thứ tự orders', () {
      final p = collectionPreview(
        orders: orders,
        selectedIds: {'so-003', 'so-001'},
        amountMinor: 1,
      );
      expect([for (final o in p.applicable) o.salesOrderId], ['so-001', 'so-003']);
    });
  });
}
