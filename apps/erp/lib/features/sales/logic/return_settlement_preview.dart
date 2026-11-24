import 'package:equatable/equatable.dart';

import '../data/models.dart';

/// Phần cấn trừ vào một đơn nhận.
class ReturnOffsetShare extends Equatable {
  const ReturnOffsetShare({
    required this.salesOrderId,
    required this.orderCode,
    required this.amountMinor,
  });

  final String salesOrderId;
  final String orderCode;
  final int amountMinor;

  @override
  List<Object?> get props => [salesOrderId, orderCode, amountMinor];
}

/// Cách chia tiền khách được hưởng khi đổi/trả (SG-13), tính lại trên máy mỗi
/// lần tick; server kiểm lại khi xác nhận.
class ReturnSettlementPreview extends Equatable {
  const ReturnSettlementPreview({
    required this.reduceOwnDebtMinor,
    required this.distributableMinor,
    required this.offsets,
    required this.offsetTotalMinor,
    required this.refundMinor,
    required this.showOffsetBlock,
  });

  /// = `receivableReverseAmountMinor` của server.
  final int reduceOwnDebtMinor;

  /// = `offsetAmountMinor + refundAmountMinor` của server.
  final int distributableMinor;

  /// Một phần tử mỗi ứng viên, đúng thứ tự server (cũ trước).
  final List<ReturnOffsetShare> offsets;
  final int offsetTotalMinor;
  final int refundMinor;
  final bool showOffsetBlock;

  /// Đơn nhận có số trừ > 0, theo thứ tự.
  List<String> get targetOrderIds => [
    for (final o in offsets)
      if (o.amountMinor > 0) o.salesOrderId,
  ];

  @override
  List<Object?> get props => [
    reduceOwnDebtMinor,
    distributableMinor,
    offsets,
    offsetTotalMinor,
    refundMinor,
    showOffsetBlock,
  ];
}

/// Chia `distributableMinor` cho các đơn đang tick, cũ trước (theo thứ tự
/// `candidates`), mỗi đơn nhận tối đa số còn nợ; phần dư là tiền hoàn.
ReturnSettlementPreview planReturnSettlement({
  required int reduceOwnDebtMinor,
  required int distributableMinor,
  required List<ReturnExchangeOffsetCandidateDto> candidates,
  required Set<String> selectedIds,
}) {
  var remaining = distributableMinor;
  final offsets = <ReturnOffsetShare>[];
  for (final c in candidates) {
    var amount = 0;
    if (selectedIds.contains(c.salesOrderId) && remaining > 0) {
      amount = remaining < c.outstandingMinor ? remaining : c.outstandingMinor;
      remaining -= amount;
    }
    offsets.add(
      ReturnOffsetShare(
        salesOrderId: c.salesOrderId,
        orderCode: c.orderCode,
        amountMinor: amount,
      ),
    );
  }
  return ReturnSettlementPreview(
    reduceOwnDebtMinor: reduceOwnDebtMinor,
    distributableMinor: distributableMinor,
    offsets: offsets,
    offsetTotalMinor: distributableMinor - remaining,
    refundMinor: remaining,
    showOffsetBlock: candidates.isNotEmpty && distributableMinor > 0,
  );
}
