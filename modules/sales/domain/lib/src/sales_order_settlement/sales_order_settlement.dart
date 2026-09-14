import 'package:uuid/uuid.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../enums/sales_payment_method.dart';
import '../enums/sales_payment_status.dart';
import '../enums/sales_payment_transaction_kind.dart';
import '../enums/sales_settlement_status.dart';
import '../shared/settlement_summary_calculator.dart';
import '../shared/value_objects/customer_ref_snapshot.dart';
import '../shared/value_objects/settlement_summary.dart';
import 'entities/sales_payment_transaction.dart';
import 'events/sales_order_settlement_initialized_event.dart';
import 'events/sales_payment_recorded_event.dart';
import 'events/sales_receivable_cleared_event.dart';
import 'events/sales_receivable_required_event.dart';
import 'events/sales_refund_recorded_event.dart';
import 'events/sales_settlement_changed_event.dart';
import 'events/sales_settlement_reconciled_event.dart';
import 'rules/payment_amount_must_be_positive_rule.dart';
import 'rules/refund_cannot_exceed_refundable_amount_rule.dart';
import 'rules/walk_in_customer_cannot_create_receivable_rule.dart';
import 'sales_order_settlement_id.dart';
import 'sales_payment_transaction_id.dart';

final class SalesOrderSettlement extends Entity<SalesOrderSettlementId> implements IAggregateRoot {
  SalesOrderSettlement._({
    required super.id,
    required TenantId tenantId,
    required String salesOrderId,
    required Money orderGrandTotal,
    required CustomerRefSnapshot? customer,
    required List<SalesPaymentTransaction> transactions,
    required SettlementSummary summary,
    required int version,
  }) : _tenantId = tenantId,
       _salesOrderId = salesOrderId,
       _orderGrandTotal = orderGrandTotal,
       _customer = customer,
       _transactions = List.of(transactions),
       _summary = summary,
       _version = version;

  final TenantId _tenantId;
  final String _salesOrderId;
  final Money _orderGrandTotal;
  final CustomerRefSnapshot? _customer;
  final List<SalesPaymentTransaction> _transactions;
  SettlementSummary _summary;
  int _version;

  static const _calculator = SettlementSummaryCalculator();

  TenantId get tenantId => _tenantId;
  String get salesOrderId => _salesOrderId;
  Money get orderGrandTotal => _orderGrandTotal;
  CustomerRefSnapshot? get customer => _customer;
  SettlementSummary get summary => _summary;
  SalesSettlementStatus get status => _summary.status;
  int get version => _version;
  List<SalesPaymentTransaction> get transactions => List.unmodifiable(_transactions);

  factory SalesOrderSettlement.reconstitute({
    required SalesOrderSettlementId id,
    required TenantId tenantId,
    required String salesOrderId,
    required Money orderGrandTotal,
    CustomerRefSnapshot? customer,
    required List<SalesPaymentTransaction> transactions,
    required SettlementSummary summary,
    required int version,
  }) {
    return SalesOrderSettlement._(
      id: id,
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      orderGrandTotal: orderGrandTotal,
      customer: customer,
      transactions: transactions,
      summary: summary,
      version: version,
    );
  }

  factory SalesOrderSettlement.initialize({
    SalesOrderSettlementId? id,
    required TenantId tenantId,
    required String salesOrderId,
    required Money orderGrandTotal,
    CustomerRefSnapshot? customer,
    required List<SalesPaymentTransaction> initialCollections,
  }) {
    for (final tx in initialCollections) {
      _enforce(PaymentAmountMustBePositiveRule(tx.amount));
    }
    final settlement = SalesOrderSettlement._(
      id: id ?? SalesOrderSettlementId(const Uuid().v4()),
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      orderGrandTotal: orderGrandTotal,
      customer: customer,
      transactions: initialCollections,
      summary: _calculator.calculate(
        orderGrandTotal: orderGrandTotal,
        confirmedCollected: _sumConfirmed(
          initialCollections,
          SalesPaymentTransactionKind.collection,
          currencyCode: orderGrandTotal.currencyCode,
        ),
        confirmedRefunded: Money.zero(orderGrandTotal.currencyCode),
      ),
      version: 1,
    );
    settlement._assertReceivablePolicy();
    settlement.addDomainEvent(
      SalesOrderSettlementInitializedEvent(settlementId: settlement.id),
    );
    if (settlement._summary.outstanding.isNotZero) {
      settlement.addDomainEvent(
        SalesReceivableRequiredEvent(settlementId: settlement.id),
      );
    }
    return settlement;
  }

  factory SalesOrderSettlement.initializeForOrder({
    required SalesOrderSettlementId id,
    required TenantId tenantId,
    required String salesOrderId,
    required int grandTotalMinor,
    required String currencyCode,
    CustomerRefSnapshot? customer,
    required List<SalesPaymentTransaction> payments,
  }) {
    return SalesOrderSettlement.initialize(
      id: id,
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      orderGrandTotal: Money(
        amountMinor: grandTotalMinor,
        currencyCode: currencyCode.trim().toUpperCase(),
      ),
      customer: customer,
      initialCollections: payments,
    );
  }

  void recordPayment({
    required SalesPaymentMethod method,
    required Money amount,
    SalesPaymentStatus status = SalesPaymentStatus.confirmed,
  }) {
    checkRule(PaymentAmountMustBePositiveRule(amount));
    final txId = SalesPaymentTransactionId(const Uuid().v4());
    _transactions.add(
      SalesPaymentTransaction(
        id: txId,
        kind: SalesPaymentTransactionKind.collection,
        method: method,
        amount: amount,
        status: status,
      ),
    );
    _refreshSummary();
    _version++;
    addDomainEvent(
      SalesPaymentRecordedEvent(settlementId: id, transactionId: txId),
    );
    addDomainEvent(SalesSettlementChangedEvent(settlementId: id));
    _emitReceivableTransitions();
  }

  void recordRefund({
    required SalesPaymentMethod method,
    required Money amount,
  }) {
    checkRule(PaymentAmountMustBePositiveRule(amount));
    final refundable = _refundableAmount();
    checkRule(
      RefundCannotExceedRefundableAmountRule(
        refundAmount: amount,
        refundableAmount: refundable,
      ),
    );
    final txId = SalesPaymentTransactionId(const Uuid().v4());
    _transactions.add(
      SalesPaymentTransaction(
        id: txId,
        kind: SalesPaymentTransactionKind.refund,
        method: method,
        amount: amount,
        status: SalesPaymentStatus.confirmed,
      ),
    );
    _refreshSummary();
    _version++;
    addDomainEvent(
      SalesRefundRecordedEvent(settlementId: id, transactionId: txId),
    );
    addDomainEvent(SalesSettlementChangedEvent(settlementId: id));
    _emitReceivableTransitions();
  }

  void reconcile() {
    _refreshSummary();
    _version++;
    addDomainEvent(SalesSettlementReconciledEvent(settlementId: id));
    addDomainEvent(SalesSettlementChangedEvent(settlementId: id));
  }

  void _refreshSummary() {
    _summary = _calculator.calculate(
      orderGrandTotal: _orderGrandTotal,
      confirmedCollected: _sumConfirmed(
        _transactions,
        SalesPaymentTransactionKind.collection,
        currencyCode: _orderGrandTotal.currencyCode,
      ),
      confirmedRefunded: _sumConfirmed(
        _transactions,
        SalesPaymentTransactionKind.refund,
        currencyCode: _orderGrandTotal.currencyCode,
      ),
    );
    _assertReceivablePolicy();
  }

  void _assertReceivablePolicy() {
    checkRule(
      WalkInCustomerCannotCreateReceivableRule(
        customer: _customer,
        createsReceivable: _summary.outstanding.isNotZero,
      ),
    );
  }

  Money _refundableAmount() {
    final collected = _sumConfirmed(
      _transactions,
      SalesPaymentTransactionKind.collection,
      currencyCode: _orderGrandTotal.currencyCode,
    );
    final refunded = _sumConfirmed(
      _transactions,
      SalesPaymentTransactionKind.refund,
      currencyCode: _orderGrandTotal.currencyCode,
    );
    final minor = collected.amountMinor - refunded.amountMinor;
    return Money(
      amountMinor: minor < 0 ? 0 : minor,
      currencyCode: _orderGrandTotal.currencyCode,
    );
  }

  void _emitReceivableTransitions() {
    if (_summary.outstanding.isZero) {
      addDomainEvent(SalesReceivableClearedEvent(settlementId: id));
    } else {
      addDomainEvent(SalesReceivableRequiredEvent(settlementId: id));
    }
  }

  static Money _sumConfirmed(
    List<SalesPaymentTransaction> txs,
    SalesPaymentTransactionKind kind, {
    required String currencyCode,
  }) {
    var total = 0;
    for (final tx in txs) {
      if (tx.kind != kind) continue;
      if (tx.status != SalesPaymentStatus.confirmed) continue;
      total += tx.amount.amountMinor;
    }
    return Money(amountMinor: total, currencyCode: currencyCode);
  }

  static void _enforce(IBusinessRule rule) {
    if (rule.isBroken()) {
      throw BusinessRuleValidationException(rule);
    }
  }
}
