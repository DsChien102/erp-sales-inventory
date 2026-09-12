import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../enums/sales_settlement_status.dart';
import 'value_objects/settlement_summary.dart';

/// Derives paid / refunded / outstanding / status from transaction totals.
final class SettlementSummaryCalculator {
  const SettlementSummaryCalculator();

  SettlementSummary calculate({
    required Money orderGrandTotal,
    required Money confirmedCollected,
    required Money confirmedRefunded,
  }) {
    final outstandingMinor =
        orderGrandTotal.amountMinor -
        confirmedCollected.amountMinor +
        confirmedRefunded.amountMinor;
    final outstanding = Money(
      amountMinor: outstandingMinor < 0 ? 0 : outstandingMinor,
      currencyCode: orderGrandTotal.currencyCode,
    );
    final status = _status(
      orderGrandTotal: orderGrandTotal,
      collected: confirmedCollected,
      refunded: confirmedRefunded,
      outstanding: outstanding,
    );
    return SettlementSummary(
      orderGrandTotal: orderGrandTotal,
      collectedTotal: confirmedCollected,
      refundedTotal: confirmedRefunded,
      outstanding: outstanding,
      status: status,
    );
  }

  SalesSettlementStatus _status({
    required Money orderGrandTotal,
    required Money collected,
    required Money refunded,
    required Money outstanding,
  }) {
    // B4c: het nghia vu (orderGrandTotal = current payable = 0) va chua co dong tien
    // nao -> khong con phai thu (vd don huy chua thu).
    if (orderGrandTotal.isZero && collected.isZero && refunded.isZero) {
      return SalesSettlementStatus.noBalance;
    }
    if (refunded.isNotZero && outstanding.isZero && collected <= refunded) {
      return SalesSettlementStatus.refunded;
    }
    if (refunded.isNotZero) {
      return SalesSettlementStatus.partiallyRefunded;
    }
    if (collected.isZero) {
      return SalesSettlementStatus.unpaid;
    }
    if (outstanding.isZero || collected >= orderGrandTotal) {
      return SalesSettlementStatus.paid;
    }
    return SalesSettlementStatus.partiallyPaid;
  }
}
