import 'package:uuid/uuid.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../enums/sales_receipt_activity_type.dart';
import '../enums/sales_receipt_status.dart';
import 'entities/sales_receipt_activity.dart';
import 'events/sales_receipt_archived_event.dart';
import 'events/sales_receipt_generated_event.dart';
import 'events/sales_receipt_printed_event.dart';
import 'events/sales_receipt_shared_event.dart';
import 'rules/receipt_must_be_generated_for_activity_rule.dart';
import 'rules/receipt_must_use_committed_snapshot_rule.dart';
import 'sales_receipt_activity_id.dart';
import 'sales_receipt_id.dart';

final class SalesReceipt extends Entity<SalesReceiptId> implements IAggregateRoot {
  SalesReceipt._({
    required super.id,
    required TenantId tenantId,
    required String salesOrderId,
    required String contentHash,
    required int versionNumber,
    required SalesReceiptStatus status,
    required List<SalesReceiptActivity> activities,
    required int version,
  }) : _tenantId = tenantId,
       _salesOrderId = salesOrderId,
       _contentHash = contentHash,
       _versionNumber = versionNumber,
       _status = status,
       _activities = List.of(activities),
       _version = version;

  final TenantId _tenantId;
  final String _salesOrderId;
  final String _contentHash;
  final int _versionNumber;
  SalesReceiptStatus _status;
  final List<SalesReceiptActivity> _activities;
  int _version;

  TenantId get tenantId => _tenantId;
  String get salesOrderId => _salesOrderId;
  String get contentHash => _contentHash;
  int get versionNumber => _versionNumber;
  SalesReceiptStatus get status => _status;
  int get version => _version;
  List<SalesReceiptActivity> get activities => List.unmodifiable(_activities);

  factory SalesReceipt.reconstitute({
    required SalesReceiptId id,
    required TenantId tenantId,
    required String salesOrderId,
    required String contentHash,
    required int versionNumber,
    required SalesReceiptStatus status,
    required List<SalesReceiptActivity> activities,
    required int version,
  }) {
    return SalesReceipt._(
      id: id,
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      contentHash: contentHash,
      versionNumber: versionNumber,
      status: status,
      activities: activities,
      version: version,
    );
  }

  factory SalesReceipt.generate({
    SalesReceiptId? id,
    required TenantId tenantId,
    required String salesOrderId,
    required String contentHash,
    int versionNumber = 1,
  }) {
    _enforce(
      ReceiptMustUseCommittedSnapshotRule(
        hasCommittedOrderId: salesOrderId.trim().isNotEmpty,
        contentHash: contentHash,
      ),
    );
    final receipt = SalesReceipt._(
      id: id ?? SalesReceiptId(const Uuid().v4()),
      tenantId: tenantId,
      salesOrderId: salesOrderId,
      contentHash: contentHash,
      versionNumber: versionNumber,
      status: SalesReceiptStatus.generated,
      activities: const [],
      version: 1,
    );
    receipt.addDomainEvent(SalesReceiptGeneratedEvent(receiptId: receipt.id));
    return receipt;
  }

  void recordPrinted({DateTime? occurredAt, String? channel}) {
    checkRule(ReceiptMustBeGeneratedForActivityRule(_status));
    _activities.add(
      SalesReceiptActivity(
        id: SalesReceiptActivityId(const Uuid().v4()),
        type: SalesReceiptActivityType.printed,
        occurredAt: occurredAt ?? DateTime.now(),
        channel: channel,
      ),
    );
    _version++;
    addDomainEvent(SalesReceiptPrintedEvent(receiptId: id));
  }

  void recordShared({DateTime? occurredAt, String? channel}) {
    checkRule(ReceiptMustBeGeneratedForActivityRule(_status));
    _activities.add(
      SalesReceiptActivity(
        id: SalesReceiptActivityId(const Uuid().v4()),
        type: SalesReceiptActivityType.shared,
        occurredAt: occurredAt ?? DateTime.now(),
        channel: channel,
      ),
    );
    _version++;
    addDomainEvent(SalesReceiptSharedEvent(receiptId: id));
  }

  void archive() {
    if (_status == SalesReceiptStatus.archived) {
      return;
    }
    _status = SalesReceiptStatus.archived;
    _version++;
    addDomainEvent(SalesReceiptArchivedEvent(receiptId: id));
  }

  static void _enforce(IBusinessRule rule) {
    if (rule.isBroken()) {
      throw BusinessRuleValidationException(rule);
    }
  }
}
