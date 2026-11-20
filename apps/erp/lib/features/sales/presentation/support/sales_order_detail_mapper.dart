import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/sales/data/models.dart' as app;

import '../models/sales_order_cancellation/sales_order_cancellation_vm.dart';
import '../models/sales_order/sales_order_detail_vm.dart';
import '../models/sales_order/sales_order_history_vm.dart';
import '../models/sales_order_settlement/sales_order_payment_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';

final class SalesOrderDetailMapper {
  const SalesOrderDetailMapper._();

  static SalesOrderDetailVm toVm(
    app.SalesOrderDetailDto dto, {
    SalesEInvoiceStatus eInvoiceStatus = SalesEInvoiceStatus.notIssued,
  }) {
    return SalesOrderDetailVm(
      orderId: dto.order.salesOrderId,
      orderNumber: dto.order.orderNumber,
      orderVersion: dto.order.version,
      createdAtFormatted: formatCommittedAt(dto.committedAt),
      customerName: dto.customer?.displayName ?? 'Khách lẻ',
      customerPhone: dto.customer?.phoneNumber ?? '',
      customerId: dto.customer?.customerId,
      storeName: dto.store.displayName,
      sellerName: dto.seller.displayName,
      totalAmountMinor: dto.order.total.amountMinor,
      paidAmountMinor: 0,
      lifecycleStatus: _lifecycle(dto.order.lifecycleStatus),
      settlementStatus: SalesSettlementStatus.unpaid,
      eInvoiceStatus: eInvoiceStatus,
      items: dto.lines.map(_line).toList(growable: false),
      currentItems: dto.currentLines.map((line) => _currentLine(line)).toList(growable: false),
      timeline: const [],
      note: dto.orderNote,
      currentReceiptId: dto.currentReceiptId,
    );
  }

  static SalesOrderPaymentVm toPaymentVm({
    required app.SalesOrderPaymentSummaryDto summary,
    required app.SalesOrderSettlementDto settlement,
    required app.SalesPaymentTransactionsDto transactions,
  }) {
    final rows = transactions.page.items;
    var cash = 0;
    var bank = 0;
    final mapped = <SalesOrderPaymentTransactionVm>[];
    for (final tx in rows) {
      mapped.add(_transactionVm(tx));
    }
    if (summary.collectedCash != null || summary.collectedBank != null) {
      cash = summary.collectedCash?.amountMinor ?? 0;
      bank = summary.collectedBank?.amountMinor ?? 0;
    } else {
      for (final tx in rows) {
        if (!tx.countsAsCollected) continue;
        switch (tx.method) {
          case app.SalesPaymentMethod.cash:
            cash += tx.amount.amountMinor;
          case app.SalesPaymentMethod.manualBankTransfer:
            bank += tx.amount.amountMinor;
          case app.SalesPaymentMethod.offset:
            break;
        }
      }
    }

    final dueAt = summary.dueAt ?? settlement.dueAt;
    return SalesOrderPaymentVm(
      orderTotalMinor: summary.orderTotal.amountMinor,
      paidTotalMinor: summary.paidTotal.amountMinor,
      outstandingMinor: summary.outstandingTotal.amountMinor,
      paidCashAmountMinor: cash,
      paidBankAmountMinor: bank,
      dueDateFormatted: dueAt == null ? null : formatDateOnly(dueAt),
      settlementStatus: _settlement(summary.status),
      offsetMinor: summary.collectedOffset.amountMinor + summary.refundedOffset.amountMinor,
      transactions: mapped,
      hasMoreTransactions: transactions.page.hasMore,
      nextTransactionsCursor: transactions.page.nextCursor,
      originalOrderBreakdown: summary.originalOrder == null
          ? null
          : SalesOrderPaymentOriginalBreakdownVm(
              orderTotalMinor: summary.originalOrder!.orderTotal.amountMinor,
              paidCashMinor: summary.originalOrder!.paidCash.amountMinor,
              paidBankMinor: summary.originalOrder!.paidBank.amountMinor,
              outstandingMinor: summary.originalOrder!.outstanding.amountMinor,
            ),
      returnSlipBreakdowns: summary.returnSlips
          .map(
            (slip) => SalesOrderPaymentReturnSlipBreakdownVm(
              slipNumber: slip.slipNumber,
              customerPaysExtraMinor: slip.customerPaysExtra.amountMinor,
              paidCashExtraMinor: slip.paidCashExtra?.amountMinor ?? 0,
              paidBankExtraMinor: slip.paidBankExtra?.amountMinor ?? 0,
            ),
          )
          .toList(growable: false),
    );
  }

  static SalesOrderPaymentVm mergeTransactionsPage({
    required SalesOrderPaymentVm current,
    required app.SalesPaymentTransactionsDto page,
  }) {
    final appended = [
      ...current.transactions,
      ...page.page.items.map(_transactionVm),
    ];

    return current.copyWith(
      transactions: appended,
      hasMoreTransactions: page.page.hasMore,
      nextTransactionsCursor: page.page.nextCursor,
      clearNextTransactionsCursor: page.page.nextCursor == null,
      transactionsLoadMoreError: false,
    );
  }

  static SalesOrderHistoryVm toHistoryVm({
    required app.SalesOrderTimelineDto timeline,
    required app.SalesOrderReturnSummaryDto returns,
  }) {
    return SalesOrderHistoryVm(
      timeline: timeline.entries.map(_timelineEntry).toList(growable: false),
      returns: returns.returns.map(_returnSlip).toList(growable: false),
    );
  }

  static SalesOrderHistoryVm mergeTimeline({
    required SalesOrderHistoryVm? current,
    required app.SalesOrderTimelineDto timeline,
  }) {
    return SalesOrderHistoryVm(
      timeline: timeline.entries.map(_timelineEntry).toList(growable: false),
      returns: current?.returns ?? const [],
    );
  }

  static SalesOrderHistoryVm mergeReturns({
    required SalesOrderHistoryVm? current,
    required app.SalesOrderReturnSummaryDto returns,
  }) {
    return SalesOrderHistoryVm(
      timeline: current?.timeline ?? const [],
      returns: returns.returns.map(_returnSlip).toList(growable: false),
    );
  }

  static String formatCommittedAt(DateTime value) {
    final ict = VDateTime.toIct(value);
    return '${_pad(ict.day)}/${_pad(ict.month)}/${ict.year} '
        '${_pad(ict.hour)}:${_pad(ict.minute)}';
  }

  static String formatDateOnly(DateTime value) {
    return VDateTime.calendarDate(value);
  }

  static SalesOrderDetailItemVm _line(app.SalesOrderLineDto line) {
    final quantity = line.quantity.quantityMicros ~/ app.QuantityDto.scale;
    final discount = line.discountTotal?.amountMinor ?? 0;
    final hasDiscount = discount > 0 && quantity > 0;
    return SalesOrderDetailItemVm(
      lineId: line.lineId,
      productName: line.product.displayName,
      unitName: line.unit.unitName,
      quantity: quantity,
      unitPriceMinor: hasDiscount
          ? (line.lineTotal.amountMinor / quantity).round()
          : line.unitPrice.amountMinor,
      originalUnitPriceMinor: hasDiscount ? line.unitPrice.amountMinor : null,
      totalAmountMinor: line.lineTotal.amountMinor,
    );
  }

  static SalesOrderDetailItemVm _currentLine(app.SalesOrderCurrentLineDto line) {
    // TODO(P3b): surface a "Hàng đổi vào" badge when line.source == exchange
    // once SalesOrderDetailItemVm gains a source marker.
    return SalesOrderDetailItemVm(
      lineId: '${line.product.productId}-${line.unit.productUnitId}',
      productName: line.product.displayName,
      unitName: line.unit.unitName,
      quantity: line.heldQuantity.quantityMicros ~/ app.QuantityDto.scale,
      unitPriceMinor: line.unitPrice.amountMinor,
      originalUnitPriceMinor: line.originalUnitPrice?.amountMinor,
      totalAmountMinor:
          line.unitPrice.amountMinor * (line.heldQuantity.quantityMicros ~/ app.QuantityDto.scale),
    );
  }

  static SalesOrderDetailTimelineVm _timelineEntry(app.SalesOrderTimelineEntryDto entry) {
    final rawTitle = (entry.description != null && entry.description!.trim().isNotEmpty)
        ? entry.description!.trim()
        : entry.eventType;
    final title = _timelineTitle(rawTitle);
    return SalesOrderDetailTimelineVm(
      title: title,
      timestamp: formatCommittedAt(entry.occurredAt),
      actorName: entry.actor?.displayName ?? 'Không rõ',
      description: entry.description,
      amountMinor: entry.amount?.amountMinor,
    );
  }

  static SalesReturnExchangeSlipItemVm _returnSlip(app.ReturnExchangeSummaryDto dto) {
    return SalesReturnExchangeSlipItemVm(
      returnExchangeId: dto.returnExchangeId,
      slipNumber: dto.referenceNumber,
      typeText: 'Đổi/trả',
      dateFormatted: formatCommittedAt(dto.completedAt),
      statusText: _returnStatus(dto.status),
      diffText: _diffText(dto.settlementDifference),
    );
  }

  static SalesOrderCancellationVm toCancellationVm(
    app.SalesOrderCancellationDetailDto dto,
  ) {
    final reasonText = dto.reason.reasonText.trim();
    return SalesOrderCancellationVm(
      cancellationId: dto.result.cancellationId,
      reason: reasonText,
      statusLabel: _cancellationStatusLabel(dto.result.status),
      isProcessing: dto.result.status == app.SalesOrderCancellationStatus.processing,
      cancelledByActorId: dto.cancelledByActorId,
      cancelledByActorName: dto.cancelledByActorName,
      cancelledAtFormatted: formatCommittedAt(dto.cancelledAt),
      netConfirmedCollectionFormatted: MoneyFormatter.formatMinor(
        dto.netConfirmedCollectionMinor,
      ),
    );
  }

  static String _cancellationStatusLabel(app.SalesOrderCancellationStatus s) {
    return switch (s) {
      app.SalesOrderCancellationStatus.confirmed => 'Đã hủy',
      app.SalesOrderCancellationStatus.completed => 'Đã hủy',
      app.SalesOrderCancellationStatus.processing => 'Đang xử lý hủy',
      app.SalesOrderCancellationStatus.requested => 'Chờ xử lý',
      app.SalesOrderCancellationStatus.validating => 'Đang kiểm tra',
      app.SalesOrderCancellationStatus.blocked => 'Bị chặn',
      app.SalesOrderCancellationStatus.failed => 'Thất bại',
      app.SalesOrderCancellationStatus.cancelled => 'Đã hủy yêu cầu',
    };
  }

  static String _diffText(app.MoneyDto difference) {
    final amount = MoneyFormatter.formatMinor(difference.amountMinor.abs());
    if (difference.amountMinor > 0) return 'Khách trả thêm $amount';
    if (difference.amountMinor < 0) return 'Hoàn lại $amount';
    return 'Không chênh lệch';
  }

  static String _timelineTitle(String value) {
    final normalized = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
        .replaceFirst(RegExp(r'_V[0-9]+$'), '')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return switch (normalized) {
      'ORDER_COMPLETED' ||
      'SALES_ORDER_COMPLETED' ||
      'SALES_ORDER_FINALIZED' => 'Hoàn tất đơn hàng',
      'ORDER_CREATED' || 'SALES_ORDER_CREATED' => 'Tạo đơn hàng',
      'ORDER_CONFIRMED' || 'SALES_ORDER_CONFIRMED' => 'Xác nhận đơn hàng',
      'PAYMENT_CASH_RECORDED' ||
      'CASH_PAYMENT_RECORDED' ||
      'SALES_PAYMENT_CASH_RECORDED' => 'Ghi nhận thanh toán tiền mặt',
      'PAYMENT_BANK_RECORDED' ||
      'BANK_PAYMENT_RECORDED' ||
      'SALES_PAYMENT_BANK_RECORDED' => 'Ghi nhận thanh toán chuyển khoản',
      'PAYMENT_RECORDED' || 'SALES_PAYMENT_RECORDED' => 'Ghi nhận thanh toán',
      'REFUND_RECORDED' || 'SALES_REFUND_RECORDED' => 'Ghi nhận hoàn tiền',
      'PAYMENT_VOIDED' || 'SALES_PAYMENT_VOIDED' => 'Hủy thanh toán',
      'RECEIVABLE_OFFSET_RECORDED' => 'Cấn trừ công nợ',
      'SETTLEMENT_CHANGED' || 'SALES_SETTLEMENT_CHANGED' => 'Cập nhật quyết toán',
      'SETTLEMENT_RECOMPUTED' || 'SALES_SETTLEMENT_RECOMPUTED' => 'Tính lại quyết toán',
      'RECEIPT_PRINTED' || 'SALES_RECEIPT_PRINTED' => 'In phiếu bán hàng',
      'RECEIPT_SHARED' || 'SALES_RECEIPT_SHARED' => 'Chia sẻ phiếu bán hàng',
      'RECEIPT_ARCHIVED' || 'SALES_RECEIPT_ARCHIVED' => 'Lưu trữ phiếu bán hàng',
      'RECEIPT_GENERATED' || 'SALES_RECEIPT_GENERATED' => 'Tạo phiếu bán hàng',
      'RETURN_EXCHANGE_COMPLETED' ||
      'RETURN_EXCHANGE_CONFIRMED' ||
      'RETURN_COMPLETED' ||
      'RETURN_CONFIRMED' => 'Hoàn tất đổi/trả',
      'ORDER_NOTE_UPDATED' || 'SALES_ORDER_NOTE_UPDATED' => 'Cập nhật ghi chú đơn hàng',
      'ORDER_ADJUSTED' || 'SALES_ORDER_ADJUSTED' => 'Điều chỉnh đơn hàng',
      'ORDER_CANCELLED' ||
      'SALES_ORDER_CANCELLED' ||
      'SALES_ORDER_CANCELLATION_CONFIRMED' => 'Hủy đơn hàng',
      'SALES_ORDER_PRICING_REVERSAL_REQUESTED' => 'Yêu cầu hoàn tác giá bán',
      'SALES_ORDER_REPORTING_CANCELLATION_RECORDED' => 'Ghi nhận báo cáo hủy đơn',
      _ => value,
    };
  }

  static SalesOrderPaymentTransactionVm _transactionVm(app.SalesPaymentTransactionDto tx) {
    final isOffset = tx.method == app.SalesPaymentMethod.offset;
    final code = tx.counterpartOrderCode;
    final direction = tx.transactionType == app.SalesPaymentTransactionType.refund ? 'sang' : 'từ';
    return SalesOrderPaymentTransactionVm(
      transactionId: tx.transactionId,
      methodLabel: isOffset && code != null && code.isNotEmpty
          ? 'Cấn trừ · $direction $code'
          : _paymentMethodLabel(tx.method),
      kindLabel: isOffset ? null : _paymentKindLabel(tx.transactionType),
      amountMinor: tx.amount.amountMinor,
      recordedAtFormatted: formatCommittedAt(tx.recordedAt),
      actorId: tx.actorId,
      counterpartSalesOrderId: isOffset ? tx.counterpartSalesOrderId : null,
    );
  }

  static String? _paymentKindLabel(app.SalesPaymentTransactionType type) {
    return switch (type) {
      app.SalesPaymentTransactionType.collection => 'Thu tiền',
      app.SalesPaymentTransactionType.refund => 'Hoàn tiền',
      app.SalesPaymentTransactionType.reversal => null,
    };
  }

  static String _paymentMethodLabel(app.SalesPaymentMethod method) {
    return switch (method) {
      app.SalesPaymentMethod.cash => 'Tiền mặt',
      app.SalesPaymentMethod.manualBankTransfer => 'Chuyển khoản',
      app.SalesPaymentMethod.offset => 'Cấn trừ',
    };
  }

  static String _returnStatus(app.ReturnExchangeStatus status) {
    return switch (status) {
      app.ReturnExchangeStatus.draft => 'Nháp',
      app.ReturnExchangeStatus.confirmed => 'Đã xác nhận',
      app.ReturnExchangeStatus.processing => 'Đang xử lý',
      app.ReturnExchangeStatus.completed => 'Hoàn tất',
      app.ReturnExchangeStatus.cancelled => 'Đã hủy',
      app.ReturnExchangeStatus.blocked => 'Bị chặn',
      app.ReturnExchangeStatus.failed => 'Thất bại',
    };
  }

  static SalesOrderLifecycleStatus _lifecycle(app.SalesOrderLifecycleStatus status) {
    return switch (status) {
      app.SalesOrderLifecycleStatus.completed => SalesOrderLifecycleStatus.committed,
      app.SalesOrderLifecycleStatus.cancelled => SalesOrderLifecycleStatus.cancelled,
    };
  }

  static SalesSettlementStatus _settlement(app.SalesSettlementStatus status) {
    return switch (status) {
      app.SalesSettlementStatus.unpaid => SalesSettlementStatus.unpaid,
      app.SalesSettlementStatus.partiallyPaid => SalesSettlementStatus.partiallyPaid,
      app.SalesSettlementStatus.paid => SalesSettlementStatus.fullyPaid,
      app.SalesSettlementStatus.partiallyRefunded => SalesSettlementStatus.partiallyRefunded,
      app.SalesSettlementStatus.refunded => SalesSettlementStatus.refunded,
      app.SalesSettlementStatus.noBalance => SalesSettlementStatus.noBalance,
    };
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');
}
