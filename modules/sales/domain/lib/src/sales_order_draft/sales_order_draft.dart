import 'package:uuid/uuid.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../enums/sales_draft_status.dart';
import '../shared/value_objects/customer_ref_snapshot.dart';
import 'entities/sales_order_draft_line.dart';
import 'events/sales_order_draft_cancelled_event.dart';
import 'events/sales_order_draft_converted_event.dart';
import 'events/sales_order_draft_expired_event.dart';
import 'events/sales_order_draft_saved_event.dart';
import 'events/sales_order_draft_updated_event.dart';
import 'rules/draft_must_be_active_for_mutation_rule.dart';
import 'rules/draft_must_contain_valid_line_rule.dart';
import 'sales_order_draft_id.dart';

final class SalesOrderDraft extends Entity<SalesOrderDraftId> implements IAggregateRoot {
  SalesOrderDraft._({
    required super.id,
    required TenantId tenantId,
    required String storeId,
    required String currencyCode,
    required SalesDraftStatus status,
    required List<SalesOrderDraftLine> lines,
    CustomerRefSnapshot? customer,
    String? orderNote,
    required int version,
  }) : _tenantId = tenantId,
       _storeId = storeId,
       _currencyCode = currencyCode,
       _status = status,
       _lines = List.of(lines),
       _customer = customer,
       _orderNote = orderNote,
       _version = version;

  final TenantId _tenantId;
  final String _storeId;
  final String _currencyCode;
  SalesDraftStatus _status;
  final List<SalesOrderDraftLine> _lines;
  CustomerRefSnapshot? _customer;
  String? _orderNote;
  int _version;

  TenantId get tenantId => _tenantId;
  String get storeId => _storeId;
  String get currencyCode => _currencyCode;
  SalesDraftStatus get status => _status;
  CustomerRefSnapshot? get customer => _customer;
  String? get orderNote => _orderNote;
  int get version => _version;
  List<SalesOrderDraftLine> get lines => List.unmodifiable(_lines);

  factory SalesOrderDraft.reconstitute({
    required SalesOrderDraftId id,
    required TenantId tenantId,
    required String storeId,
    required String currencyCode,
    required SalesDraftStatus status,
    required List<SalesOrderDraftLine> lines,
    CustomerRefSnapshot? customer,
    String? orderNote,
    required int version,
  }) {
    return SalesOrderDraft._(
      id: id,
      tenantId: tenantId,
      storeId: storeId,
      currencyCode: currencyCode,
      status: status,
      lines: lines,
      customer: customer,
      orderNote: orderNote,
      version: version,
    );
  }

  factory SalesOrderDraft.save({
    SalesOrderDraftId? id,
    required TenantId tenantId,
    required String storeId,
    required String currencyCode,
    required List<SalesOrderDraftLine> lines,
    CustomerRefSnapshot? customer,
    String? orderNote,
  }) {
    _enforce(DraftMustContainValidLineRule(lines));
    final draft = SalesOrderDraft._(
      id: id ?? SalesOrderDraftId(const Uuid().v4()),
      tenantId: tenantId,
      storeId: storeId,
      currencyCode: currencyCode.trim().toUpperCase(),
      status: SalesDraftStatus.active,
      lines: lines,
      customer: customer,
      orderNote: orderNote,
      version: 1,
    );
    draft.addDomainEvent(SalesOrderDraftSavedEvent(draftId: draft.id));
    return draft;
  }

  void update({
    required List<SalesOrderDraftLine> lines,
    CustomerRefSnapshot? customer,
    String? orderNote,
    required int expectedVersion,
  }) {
    checkRule(DraftMustBeActiveForMutationRule(_status));
    checkRule(DraftMustContainValidLineRule(lines));
    _ensureExpectedVersion(expectedVersion);
    _lines
      ..clear()
      ..addAll(lines);
    _customer = customer;
    _orderNote = orderNote;
    _version++;
    addDomainEvent(SalesOrderDraftUpdatedEvent(draftId: id));
  }

  void cancel({required int expectedVersion}) {
    checkRule(DraftMustBeActiveForMutationRule(_status));
    _ensureExpectedVersion(expectedVersion);
    _status = SalesDraftStatus.cancelled;
    _version++;
    addDomainEvent(SalesOrderDraftCancelledEvent(draftId: id));
  }

  void expire({required int expectedVersion}) {
    checkRule(DraftMustBeActiveForMutationRule(_status));
    _ensureExpectedVersion(expectedVersion);
    _status = SalesDraftStatus.expired;
    _version++;
    addDomainEvent(SalesOrderDraftExpiredEvent(draftId: id));
  }

  void markConverted({required int expectedVersion}) {
    checkRule(DraftMustBeActiveForMutationRule(_status));
    checkRule(DraftMustContainValidLineRule(_lines));
    _ensureExpectedVersion(expectedVersion);
    _status = SalesDraftStatus.converted;
    _version++;
    addDomainEvent(SalesOrderDraftConvertedEvent(draftId: id));
  }

  void _ensureExpectedVersion(int expectedVersion) {
    if (_version != expectedVersion) {
      throw DomainException(
        'Draft version mismatch: expected $expectedVersion, was $_version.',
      );
    }
  }

  static void _enforce(IBusinessRule rule) {
    if (rule.isBroken()) {
      throw BusinessRuleValidationException(rule);
    }
  }
}
