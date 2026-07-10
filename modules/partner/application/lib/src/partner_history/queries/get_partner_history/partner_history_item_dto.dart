import 'package:vet45_partner_domain/domain.dart';

import '../../shared/partner_transaction_type.dart';

/// Partner history list row (read model).
final class PartnerHistoryItemDto {
  const PartnerHistoryItemDto({
    required this.historyId,
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
  });

  final String historyId;
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
