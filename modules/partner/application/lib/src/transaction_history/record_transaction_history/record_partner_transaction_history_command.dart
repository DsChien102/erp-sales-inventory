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
}
