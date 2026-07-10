import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/partner_transaction_type.dart';

/// Internal projection upsert — consumed by integration event handlers.
@PublicAccess()
final class RecordPartnerHistoryCommand extends InternalCommandBase<void>
    implements ICommand<void> {
  RecordPartnerHistoryCommand({
    String? id,
    required this.tenantId,
    required this.partnerId,
    required this.role,
    required this.transactionType,
    required this.sourceModule,
    required this.sourceId,
    required this.referenceCode,
    required this.transactionDate,
    required this.status,
    this.amount,
    this.currency,
    required this.canOpenSource,
  }) : super(id);

  final String tenantId;
  final String partnerId;
  final PartnerRoleType role;
  final PartnerTransactionType transactionType;
  final String sourceModule;
  final String sourceId;
  final String referenceCode;
  final DateTime transactionDate;
  final String status;
  final double? amount;
  final String? currency;
  final bool canOpenSource;
}
