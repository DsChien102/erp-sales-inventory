import '../enums/sales_order_lifecycle_status.dart';

/// Phase 1: order note updates allowed on completed orders; lock does not block.
final class SalesOrderEditPolicy {
  const SalesOrderEditPolicy();

  bool canUpdateOrderNote({
    required SalesOrderLifecycleStatus lifecycleStatus,
  }) => lifecycleStatus == SalesOrderLifecycleStatus.completed;

  String? normalizeNote(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  bool isNoOp({required String? currentNote, required String? nextNote}) {
    final left = normalizeNote(currentNote);
    final right = normalizeNote(nextNote);
    return left == right;
  }
}
