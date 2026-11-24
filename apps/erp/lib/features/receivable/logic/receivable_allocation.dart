import 'package:equatable/equatable.dart';

import '../data/receivable_models.dart';

class CollectionAllocation extends Equatable {
  const CollectionAllocation({
    required this.salesOrderId,
    required this.allocatedMinor,
    required this.outstandingAfterMinor,
  });

  final String salesOrderId;
  final int allocatedMinor;
  final int outstandingAfterMinor;

  @override
  List<Object?> get props => [salesOrderId, allocatedMinor, outstandingAfterMinor];
}

/// Chia cũ trước (`allocate.js`).
List<CollectionAllocation> allocateOldestFirst(List<OpenReceivableOrder> orders, int amountMinor) {
  var left = amountMinor;
  final out = <CollectionAllocation>[];
  for (final o in orders) {
    if (left <= 0) break;
    final a = left < o.outstandingMinor ? left : o.outstandingMinor;
    if (a > 0) {
      out.add(
        CollectionAllocation(
          salesOrderId: o.salesOrderId,
          allocatedMinor: a,
          outstandingAfterMinor: o.outstandingMinor - a,
        ),
      );
      left -= a;
    }
  }
  return out;
}

class CollectionPreview extends Equatable {
  const CollectionPreview({
    required this.applicable,
    required this.scopeTotal,
    required this.customerTotal,
    required this.over,
    required this.allocations,
    required this.afterMinor,
    required this.canSubmit,
  });

  final List<OpenReceivableOrder> applicable;
  final int scopeTotal;
  final int customerTotal;
  final bool over;
  final List<CollectionAllocation> allocations;
  final int afterMinor;
  final bool canSubmit;

  @override
  List<Object?> get props => [
    applicable,
    scopeTotal,
    customerTotal,
    over,
    allocations,
    afterMinor,
    canSubmit,
  ];
}

/// `cn03Scope` + `cn03Calc` của prototype.
CollectionPreview collectionPreview({
  required List<OpenReceivableOrder> orders,
  required Set<String> selectedIds,
  required int amountMinor,
}) {
  final applicable = [
    for (final o in orders)
      if (selectedIds.contains(o.salesOrderId)) o,
  ];
  final scopeTotal = applicable.fold<int>(0, (s, o) => s + o.outstandingMinor);
  final customerTotal = orders.fold<int>(0, (s, o) => s + o.outstandingMinor);
  final over = amountMinor > scopeTotal;
  final allocations = amountMinor > 0 && !over
      ? allocateOldestFirst(applicable, amountMinor)
      : const <CollectionAllocation>[];
  return CollectionPreview(
    applicable: applicable,
    scopeTotal: scopeTotal,
    customerTotal: customerTotal,
    over: over,
    allocations: allocations,
    afterMinor: customerTotal - (over ? 0 : amountMinor),
    canSubmit: amountMinor > 0 && !over,
  );
}
