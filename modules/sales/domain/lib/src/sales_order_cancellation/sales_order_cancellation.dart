import 'package:uuid/uuid.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../enums/sales_order_cancellation_status.dart';
import 'events/sales_order_cancellation_blocked_event.dart';
import 'events/sales_order_cancellation_completed_event.dart';
import 'events/sales_order_cancellation_confirmed_event.dart';
import 'events/sales_order_cancellation_requested_event.dart';
import 'rules/cancellation_must_be_requested_for_confirm_rule.dart';
import 'rules/cancellation_must_pass_precheck_rule.dart';
import 'sales_order_cancellation_id.dart';
import 'value_objects/cancellation_precheck_snapshot.dart';
import 'value_objects/cancellation_reason.dart';

final class SalesOrderCancellation extends Entity<SalesOrderCancellationId>
    implements IAggregateRoot {
  SalesOrderCancellation._({
    required super.id,
    required TenantId tenantId,
    required String salesOrderId,
    required SalesOrderCancellationStatus status,
    required CancellationReason? reason,
    required CancellationPrecheckSnapshot? lastPrecheck,
    required String? confirmedBy,
    required DateTime? confirmedAt,
    required int version,
  }) : _tenantId = tenantId,
       _salesOrderId = salesOrderId,
       _status = status,
       _reason = reason,
       _lastPrecheck = lastPrecheck,
       _confirmedBy = confirmedBy,
       _confirmedAt = confirmedAt,
       _version = version;

  final TenantId _tenantId;
  final String _salesOrderId;
  SalesOrderCancellationStatus _status;
  CancellationReason? _reason;
  CancellationPrecheckSnapshot? _lastPrecheck;
  String? _confirmedBy;
  DateTime? _confirmedAt;
  int _version;

  TenantId get tenantId => _tenantId;
  String get salesOrderId => _salesOrderId;
  SalesOrderCancellationStatus get status => _status;
  CancellationReason? get reason => _reason;
  CancellationPrecheckSnapshot? get lastPrecheck => _lastPrecheck;
  String? get confirmedBy => _confirmedBy;
  DateTime? get confirmedAt => _confirmedAt;
  int get version => _version;

  factory SalesOrderCancellation.reconstitute({
    required SalesOrderCancellationId id,
    required TenantId tenantId,
    required String salesOrderId,
    required SalesOrderCancellationStatus status,
    CancellationReason? reason,
    CancellationPrecheckSnapshot? lastPrecheck,
    String? confirmedBy,
    DateTime? confirmedAt,
    required int version,
  }) {
    return SalesOrderCancellation._(
      id: id,
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      status: status,
      reason: reason,
      lastPrecheck: lastPrecheck,
      confirmedBy: confirmedBy,
      confirmedAt: confirmedAt,
      version: version,
    );
  }

  factory SalesOrderCancellation.request({
    SalesOrderCancellationId? id,
    required TenantId tenantId,
    required String salesOrderId,
  }) {
    final cancellation = SalesOrderCancellation._(
      id: id ?? SalesOrderCancellationId(const Uuid().v4()),
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      status: SalesOrderCancellationStatus.requested,
      reason: null,
      lastPrecheck: null,
      confirmedBy: null,
      confirmedAt: null,
      version: 1,
    );
    cancellation.addDomainEvent(
      SalesOrderCancellationRequestedEvent(cancellationId: cancellation.id),
    );
    return cancellation;
  }

  void confirm({
    required CancellationPrecheckSnapshot precheck,
    required CancellationReason reason,
    required String actorId,
    required DateTime confirmedAt,
  }) {
    checkRule(CancellationMustBeRequestedForConfirmRule(_status));
    _lastPrecheck = precheck;
    if (!precheck.passed) {
      _status = SalesOrderCancellationStatus.blocked;
      _version++;
      addDomainEvent(
        SalesOrderCancellationBlockedEvent(cancellationId: id),
      );
      return;
    }
    checkRule(CancellationMustPassPrecheckRule(precheck));
    _reason = reason;
    _confirmedBy = actorId;
    _confirmedAt = confirmedAt;
    _status = SalesOrderCancellationStatus.confirmed;
    _version++;
    addDomainEvent(
      SalesOrderCancellationConfirmedEvent(cancellationId: id),
    );
  }

  void markProcessing() {
    if (_status != SalesOrderCancellationStatus.confirmed) {
      throw DomainException(
        'Cancellation must be confirmed before processing.',
      );
    }
    _status = SalesOrderCancellationStatus.processing;
    _version++;
  }

  void complete() {
    if (_status != SalesOrderCancellationStatus.processing &&
        _status != SalesOrderCancellationStatus.confirmed) {
      throw DomainException(
        'Cancellation can only complete from confirmed/processing.',
      );
    }
    _status = SalesOrderCancellationStatus.completed;
    _version++;
    addDomainEvent(
      SalesOrderCancellationCompletedEvent(cancellationId: id),
    );
  }

  void markBlocked({required CancellationPrecheckSnapshot precheck}) {
    _lastPrecheck = precheck;
    _status = SalesOrderCancellationStatus.blocked;
    _version++;
    addDomainEvent(SalesOrderCancellationBlockedEvent(cancellationId: id));
  }
}
