import 'package:uuid/uuid.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../enums/sales_order_lifecycle_status.dart';
import '../enums/sales_order_lock_status.dart';
import '../shared/rules/commercial_snapshot_must_balance_rule.dart';
import '../shared/value_objects/customer_ref_snapshot.dart';
import '../shared/value_objects/monetary_summary.dart';
import 'entities/sales_order_line.dart';
import 'events/sales_order_cancelled_event.dart';
import 'events/sales_order_finalized_event.dart';
import 'events/sales_order_locked_event.dart';
import 'events/sales_order_unlocked_event.dart';
import 'rules/sales_order_must_be_completed_for_lock_rule.dart';
import 'rules/sales_order_must_not_already_be_cancelled_rule.dart';
import 'sales_order_id.dart';
import 'value_objects/sales_order_draft_ref.dart';

final class SalesOrder extends Entity<SalesOrderId> implements IAggregateRoot {
  SalesOrder._({
    required super.id,
    required TenantId tenantId,
    required String storeId,
    required String currencyCode,
    required SalesOrderLifecycleStatus lifecycleStatus,
    required SalesOrderLockStatus lockStatus,
    required List<SalesOrderLine> lines,
    required MonetarySummary monetarySummary,
    CustomerRefSnapshot? customer,
    String? orderNote,
    SalesOrderDraftRef? sourceDraft,
    required int version,
  }) : _tenantId = tenantId,
       _storeId = storeId,
       _currencyCode = currencyCode,
       _lifecycleStatus = lifecycleStatus,
       _lockStatus = lockStatus,
       _lines = List.unmodifiable(lines),
       _monetarySummary = monetarySummary,
       _customer = customer,
       _orderNote = orderNote,
       _sourceDraft = sourceDraft,
       _version = version;

  final TenantId _tenantId;
  final String _storeId;
  final String _currencyCode;
  SalesOrderLifecycleStatus _lifecycleStatus;
  SalesOrderLockStatus _lockStatus;
  final List<SalesOrderLine> _lines;
  final MonetarySummary _monetarySummary;
  CustomerRefSnapshot? _customer;
  String? _orderNote;
  final SalesOrderDraftRef? _sourceDraft;
  int _version;

  TenantId get tenantId => _tenantId;
  String get storeId => _storeId;
  String get currencyCode => _currencyCode;
  SalesOrderLifecycleStatus get lifecycleStatus => _lifecycleStatus;
  SalesOrderLockStatus get lockStatus => _lockStatus;
  List<SalesOrderLine> get lines => _lines;
  MonetarySummary get monetarySummary => _monetarySummary;
  CustomerRefSnapshot? get customer => _customer;
  String? get orderNote => _orderNote;
  SalesOrderDraftRef? get sourceDraft => _sourceDraft;
  int get version => _version;

  /// Updates note only (Phase 1 adjustment) — does not mutate commercial lines.
  void replaceOrderNote(String? note) {
    checkRule(SalesOrderMustNotAlreadyBeCancelledRule(_lifecycleStatus));
    if (_lifecycleStatus != SalesOrderLifecycleStatus.completed) {
      throw DomainException(
        'Order note can only be updated on completed orders.',
      );
    }
    _orderNote = note;
    _version++;
  }

  factory SalesOrder.reconstitute({
    required SalesOrderId id,
    required TenantId tenantId,
    required String storeId,
    required String currencyCode,
    required SalesOrderLifecycleStatus lifecycleStatus,
    required SalesOrderLockStatus lockStatus,
    required List<SalesOrderLine> lines,
    required MonetarySummary monetarySummary,
    CustomerRefSnapshot? customer,
    String? orderNote,
    SalesOrderDraftRef? sourceDraft,
    required int version,
  }) {
    return SalesOrder._(
      id: id,
      tenantId: tenantId,
      storeId: storeId,
      currencyCode: currencyCode,
      lifecycleStatus: lifecycleStatus,
      lockStatus: lockStatus,
      lines: lines,
      monetarySummary: monetarySummary,
      customer: customer,
      orderNote: orderNote,
      sourceDraft: sourceDraft,
      version: version,
    );
  }

  factory SalesOrder.finalize({
    SalesOrderId? id,
    required TenantId tenantId,
    required String storeId,
    required String currencyCode,
    required List<SalesOrderLine> lines,
    required MonetarySummary monetarySummary,
    CustomerRefSnapshot? customer,
    String? orderNote,
    SalesOrderDraftRef? sourceDraft,
  }) {
    if (lines.isEmpty) {
      throw DomainException('Finalized order requires at least one line.');
    }
    _enforce(CommercialSnapshotMustBalanceRule(monetarySummary));
    final order = SalesOrder._(
      id: id ?? SalesOrderId(const Uuid().v4()),
      tenantId: tenantId,
      storeId: storeId,
      currencyCode: currencyCode.trim().toUpperCase(),
      lifecycleStatus: SalesOrderLifecycleStatus.completed,
      lockStatus: SalesOrderLockStatus.unlocked,
      lines: lines,
      monetarySummary: monetarySummary,
      customer: customer,
      orderNote: orderNote,
      sourceDraft: sourceDraft,
      version: 1,
    );
    order.addDomainEvent(SalesOrderFinalizedEvent(orderId: order.id));
    return order;
  }

  void markCancelled() {
    checkRule(SalesOrderMustNotAlreadyBeCancelledRule(_lifecycleStatus));
    _lifecycleStatus = SalesOrderLifecycleStatus.cancelled;
    _version++;
    addDomainEvent(SalesOrderCancelledEvent(orderId: id));
  }

  void lock() {
    checkRule(SalesOrderMustBeCompletedForLockRule(_lifecycleStatus));
    if (_lockStatus == SalesOrderLockStatus.locked) {
      return;
    }
    _lockStatus = SalesOrderLockStatus.locked;
    _version++;
    addDomainEvent(SalesOrderLockedEvent(orderId: id));
  }

  void unlock() {
    checkRule(SalesOrderMustBeCompletedForLockRule(_lifecycleStatus));
    if (_lockStatus == SalesOrderLockStatus.unlocked) {
      return;
    }
    _lockStatus = SalesOrderLockStatus.unlocked;
    _version++;
    addDomainEvent(SalesOrderUnlockedEvent(orderId: id));
  }

  static void _enforce(IBusinessRule rule) {
    if (rule.isBroken()) {
      throw BusinessRuleValidationException(rule);
    }
  }
}
