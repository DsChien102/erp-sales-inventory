import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Idempotent projection write from integration events / internal commands.
final class RecordPartnerTransactionHistoryCommand extends InternalCommandBase<void> {
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

  static const commandType = 'partner.record_transaction_history';

  /// Rebuilds the command from a persisted internal-command payload row.
  factory RecordPartnerTransactionHistoryCommand.fromJson(
    Map<String, dynamic> payload, {
    String? id,
  }) {
    return RecordPartnerTransactionHistoryCommand(
      id: id,
      tenantId: payload['tenant_id'] as String,
      businessPartnerId: payload['business_partner_id'] as String,
      transactionRole: PartnerRole.values.byName(
        payload['transaction_role'] as String,
      ),
      sourceModule: payload['source_module'] as String,
      sourceType: payload['source_type'] as String,
      sourceId: payload['source_id'] as String,
      sourceCode: payload['source_code'] as String?,
      transactionDate: DateTime.parse(payload['transaction_date'] as String),
      amount: (payload['amount'] as num?)?.toDouble(),
      status: payload['status'] as String?,
      description: payload['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
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
}
