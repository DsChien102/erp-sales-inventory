import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../enums/sales_settlement_status.dart';

final class SettlementSummary extends ValueObject {
  SettlementSummary({
    required this.orderGrandTotal,
    required this.collectedTotal,
    required this.refundedTotal,
    required this.outstanding,
    required this.status,
  });

  final Money orderGrandTotal;
  final Money collectedTotal;
  final Money refundedTotal;
  final Money outstanding;
  final SalesSettlementStatus status;

  @override
  List<Object?> get props => [
    orderGrandTotal,
    collectedTotal,
    refundedTotal,
    outstanding,
    status,
  ];
}
