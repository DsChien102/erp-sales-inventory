import 'package:uuid/uuid.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../enums/return_exchange_line_kind.dart';
import '../enums/return_exchange_status.dart';
import '../shared/value_objects/return_exchange_valuation.dart';
import 'entities/return_exchange_line.dart';
import 'events/return_exchange_cancelled_event.dart';
import 'events/return_exchange_completed_event.dart';
import 'events/return_exchange_confirmed_event.dart';
import 'events/return_exchange_started_event.dart';
import 'events/return_exchange_valued_event.dart';
import 'return_exchange_order_id.dart';
import 'rules/exchange_line_must_not_reference_original_line_rule.dart';
import 'rules/return_exchange_line_quantity_must_be_positive_rule.dart';
import 'rules/return_exchange_must_be_draft_for_update_rule.dart';
import 'rules/return_exchange_must_have_returned_item_rule.dart';
import 'rules/return_line_must_reference_original_line_rule.dart';
import 'rules/return_quantity_cannot_exceed_returnable_rule.dart';
import 'value_objects/return_exchange_confirmation_snapshot.dart';
import 'value_objects/return_exchange_settlement_plan.dart';

final class ReturnExchangeOrder extends Entity<ReturnExchangeOrderId> implements IAggregateRoot {
  ReturnExchangeOrder._({
    required super.id,
    required TenantId tenantId,
    required String salesOrderId,
    required String currencyCode,
    required ReturnExchangeStatus status,
    required List<ReturnExchangeLine> lines,
    ReturnExchangeValuation? valuation,
    ReturnExchangeSettlementPlan? settlementPlan,
    ReturnExchangeConfirmationSnapshot? confirmationSnapshot,
    required int version,
  }) : _tenantId = tenantId,
       _salesOrderId = salesOrderId,
       _currencyCode = currencyCode,
       _status = status,
       _lines = List.of(lines),
       _valuation = valuation,
       _settlementPlan = settlementPlan,
       _confirmationSnapshot = confirmationSnapshot,
       _version = version;

  final TenantId _tenantId;
  final String _salesOrderId;
  final String _currencyCode;
  ReturnExchangeStatus _status;
  final List<ReturnExchangeLine> _lines;
  ReturnExchangeValuation? _valuation;
  ReturnExchangeSettlementPlan? _settlementPlan;
  ReturnExchangeConfirmationSnapshot? _confirmationSnapshot;
  int _version;

  TenantId get tenantId => _tenantId;
  String get salesOrderId => _salesOrderId;
  String get currencyCode => _currencyCode;
  ReturnExchangeStatus get status => _status;
  ReturnExchangeValuation? get valuation => _valuation;
  ReturnExchangeSettlementPlan? get settlementPlan => _settlementPlan;
  ReturnExchangeConfirmationSnapshot? get confirmationSnapshot => _confirmationSnapshot;
  int get version => _version;
  List<ReturnExchangeLine> get lines => List.unmodifiable(_lines);

  factory ReturnExchangeOrder.reconstitute({
    required ReturnExchangeOrderId id,
    required TenantId tenantId,
    required String salesOrderId,
    required String currencyCode,
    required ReturnExchangeStatus status,
    required List<ReturnExchangeLine> lines,
    ReturnExchangeValuation? valuation,
    ReturnExchangeSettlementPlan? settlementPlan,
    ReturnExchangeConfirmationSnapshot? confirmationSnapshot,
    required int version,
  }) {
    return ReturnExchangeOrder._(
      id: id,
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      currencyCode: currencyCode,
      status: status,
      lines: lines,
      valuation: valuation,
      settlementPlan: settlementPlan,
      confirmationSnapshot: confirmationSnapshot,
      version: version,
    );
  }

  /// Opens a technical draft session (recovery / in-progress), not a user draft list.
  factory ReturnExchangeOrder.start({
    ReturnExchangeOrderId? id,
    required TenantId tenantId,
    required String salesOrderId,
    required String currencyCode,
    List<ReturnExchangeLine> lines = const [],
  }) {
    final order = ReturnExchangeOrder._(
      id: id ?? ReturnExchangeOrderId(const Uuid().v4()),
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      currencyCode: currencyCode.trim().toUpperCase(),
      status: ReturnExchangeStatus.draft,
      lines: lines,
      valuation: null,
      settlementPlan: null,
      confirmationSnapshot: null,
      version: 1,
    );
    order._validateLines(
      lines,
      returnableQuantityByOrderLineId: const {},
    );
    order.addDomainEvent(
      ReturnExchangeStartedEvent(returnExchangeId: order.id),
    );
    return order;
  }

  void updateLines({
    required List<ReturnExchangeLine> lines,
    required Map<String, int> returnableQuantityByOrderLineId,
  }) {
    checkRule(ReturnExchangeMustBeDraftForUpdateRule(_status));
    _validateLines(
      lines,
      returnableQuantityByOrderLineId: returnableQuantityByOrderLineId,
    );
    _lines
      ..clear()
      ..addAll(lines);
    _valuation = null;
    _settlementPlan = null;
    _version++;
  }

  void applyValuation({
    required ReturnExchangeValuation valuation,
    required ReturnExchangeSettlementPlan settlementPlan,
  }) {
    checkRule(ReturnExchangeMustBeDraftForUpdateRule(_status));
    if (valuation.netDifferenceMinor != settlementPlan.netDifferenceMinor) {
      throw DomainException(
        'Settlement plan net difference must match valuation.',
      );
    }
    if (valuation.currencyCode != _currencyCode || settlementPlan.currencyCode != _currencyCode) {
      throw DomainException(
        'Valuation and settlement plan currency must match the return/exchange order.',
      );
    }
    _valuation = valuation;
    _settlementPlan = settlementPlan;
    _version++;
    addDomainEvent(ReturnExchangeValuedEvent(returnExchangeId: id));
  }

  void confirm({
    required Map<String, int> returnableQuantityByOrderLineId,
    required ReturnExchangeConfirmationSnapshot confirmationSnapshot,
  }) {
    checkRule(ReturnExchangeMustBeDraftForUpdateRule(_status));
    checkRule(ReturnExchangeMustHaveReturnedItemRule(_lines));
    checkRule(ReturnLineMustReferenceOriginalLineRule(_lines));
    _assertReturnableQuantities(_lines, returnableQuantityByOrderLineId);
    if (_valuation == null || _settlementPlan == null) {
      throw DomainException(
        'Return/exchange confirmation requires valuation and settlement plan.',
      );
    }
    _confirmationSnapshot = confirmationSnapshot;
    _status = ReturnExchangeStatus.confirmed;
    _version++;
    addDomainEvent(ReturnExchangeConfirmedEvent(returnExchangeId: id));
  }

  void cancel() {
    if (_status == ReturnExchangeStatus.cancelled) return;
    checkRule(ReturnExchangeMustBeDraftForUpdateRule(_status));
    _status = ReturnExchangeStatus.cancelled;
    _version++;
    addDomainEvent(ReturnExchangeCancelledEvent(returnExchangeId: id));
  }

  void _validateLines(
    List<ReturnExchangeLine> lines, {
    required Map<String, int> returnableQuantityByOrderLineId,
  }) {
    checkRule(ReturnExchangeLineQuantityMustBePositiveRule(lines));
    checkRule(ReturnLineMustReferenceOriginalLineRule(lines));
    checkRule(ExchangeLineMustNotReferenceOriginalLineRule(lines));
    _assertReturnableQuantities(lines, returnableQuantityByOrderLineId);
  }

  void complete() {
    if (_status != ReturnExchangeStatus.confirmed && _status != ReturnExchangeStatus.processing) {
      throw DomainException(
        'Return/exchange must be confirmed before completion.',
      );
    }
    _status = ReturnExchangeStatus.completed;
    _version++;
    addDomainEvent(ReturnExchangeCompletedEvent(returnExchangeId: id));
  }

  void markProcessing() {
    if (_status != ReturnExchangeStatus.confirmed) {
      throw DomainException(
        'Return/exchange must be confirmed before processing.',
      );
    }
    _status = ReturnExchangeStatus.processing;
    _version++;
  }

  void _assertReturnableQuantities(
    List<ReturnExchangeLine> lines,
    Map<String, int> returnableQuantityByOrderLineId,
  ) {
    final requested = <String, int>{};
    for (final line in lines) {
      if (line.kind != ReturnExchangeLineKind.returned) continue;
      final sourceId = line.sourceOrderLineId!;
      requested[sourceId] = (requested[sourceId] ?? 0) + line.quantity.quantityMicros;
    }
    for (final entry in requested.entries) {
      final returnable = returnableQuantityByOrderLineId[entry.key] ?? 0;
      checkRule(
        ReturnQuantityCannotExceedReturnableRule(
          requestedMicros: entry.value,
          returnableMicros: returnable,
        ),
      );
    }
  }
}
