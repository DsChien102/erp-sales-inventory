import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Idempotent projection write from integration events / internal commands.
final class RecordPartnerTransactionHistoryCommand extends InternalCommandBase<void>
    implements ISerializableInternalCommand {
  RecordPartnerTransactionHistoryCommand({
    String? id,
    required this.tenantId,
    required this.businessPartnerId,
    required this.transactionRole,
    required this.sourceModule,
    required this.sourceType,
    required this.sourceId,
    required this.transactionDate,
    this.sourceCode,
    this.amount,
    this.status,
    this.description,
  }) : super(id);

  static const type = 'partner.record_transaction_history';

  @override
  String get commandType => type;

  @override
  final String tenantId;
  final String businessPartnerId;
  final PartnerRole transactionRole;
  final String sourceModule;
  final String sourceType;
  final String sourceId;
  final DateTime transactionDate;
  final String? sourceCode;
  final double? amount;
  final String? status;
  final String? description;

  /// Rebuilds the command from a persisted internal-command payload row.
  factory RecordPartnerTransactionHistoryCommand.fromJson(
    Map<String, dynamic> payload, {
    required String id,
  }) {
    final json = normalizeInternalCommandDeserializeJson(payload, rowId: id);
    return RecordPartnerTransactionHistoryCommand(
      id: json['id'] as String?,
      tenantId: json['tenant_id'] as String,
      businessPartnerId: json['business_partner_id'] as String,
      transactionRole: PartnerRole.values.byName(
        json['transaction_role'] as String,
      ),
      sourceModule: json['source_module'] as String,
      sourceType: json['source_type'] as String,
      sourceId: json['source_id'] as String,
      sourceCode: json['source_code'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      amount: (json['amount'] as num?)?.toDouble(),
      status: json['status'] as String?,
      description: json['description'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = {
      'tenant_id': tenantId,
      'business_partner_id': businessPartnerId,
      'transaction_role': transactionRole.name,
      'source_module': sourceModule,
      'source_type': sourceType,
      'source_id': sourceId,
      if (sourceCode != null) 'source_code': sourceCode,
      'transaction_date': transactionDate.toUtc().toIso8601String(),
      if (amount != null) 'amount': amount,
      if (status != null) 'status': status,
      if (description != null) 'description': description,
    };
    return stripInternalCommandRowId(map);
  }
}
