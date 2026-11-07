// ignore_for_file: depend_on_referenced_packages

import 'package:vet45_sales_application/application.dart';

/// DTO mặc định cho test sales, giá trị chép từ factory fixture của module sales cũ
/// (`modules/sales/application/lib/src/testing/`), thay cho nó khi module bị xoá.
/// Kiểu chưa có ở đây thì thêm cùng giá trị gốc; kiểu lạ ném [UnsupportedError].
T salesFixture<T>() {
  final Object value = switch (T) {
    const (AvailablePostSaleActionsDto) => const AvailablePostSaleActionsDto(
      canCancel: true,
      canReturnExchange: true,
    ),
    const (CheckoutResultDto) => const CheckoutResultDto(
      idempotencyKey: 'fake-checkout-attempt',
      salesOrderId: 'fake-sales-order',
      salesOrderVersion: 1,
      status: CheckoutResultStatus.succeeded,
    ),
    const (SalesOrderResultDto) => _orderResult,
    const (SalesOrderPaymentSummaryDto) => _paymentSummary,
    const (SalesOrderSettlementDto) => const SalesOrderSettlementDto(
      settlementId: 'fake-settlement',
      salesOrderId: 'fake-sales-order',
      version: 1,
      status: SalesSettlementStatus.paid,
      orderTotal: _total,
      paidTotal: _total,
      refundedTotal: _zero,
      outstanding: _zero,
    ),
    const (SalesPaymentTransactionsDto) => SalesPaymentTransactionsDto(
      page: OpaqueCursorPageDto<SalesPaymentTransactionDto>(
        items: <SalesPaymentTransactionDto>[
          SalesPaymentTransactionDto(
            transactionId: 'fake-payment',
            method: SalesPaymentMethod.cash,
            amount: _total,
            status: SalesPaymentStatus.confirmed,
            recordedAt: _now,
          ),
        ],
        hasMore: false,
      ),
    ),
    const (SalesOrderTimelineDto) => SalesOrderTimelineDto(
      salesOrderId: 'fake-sales-order',
      entries: <SalesOrderTimelineEntryDto>[
        SalesOrderTimelineEntryDto(
          eventId: 'fake-event',
          eventType: 'sales_order_confirmed',
          occurredAt: _now,
          sourceVersion: 1,
          actor: _actor,
          description: 'Đơn đã xác nhận',
          amount: _total,
        ),
      ],
    ),
    const (SalesOrderReturnSummaryDto) => SalesOrderReturnSummaryDto(
      salesOrderId: 'fake-sales-order',
      returns: const <ReturnExchangeSummaryDto>[],
    ),
    const (ReturnExchangeDetailDto) => ReturnExchangeDetailDto(
      result: const ReturnExchangeResultDto(
        returnExchangeId: 'fake-return-exchange',
        salesOrderId: 'fake-sales-order',
        version: 2,
        status: ReturnExchangeStatus.draft,
      ),
      referenceNumber: 'RE-FAKE-001',
      entrySource: ReturnExchangeEntrySource.standard,
      createdAt: _now,
      confirmedByActorId: null,
      confirmedAt: null,
      completedAt: null,
      lines: const <ReturnExchangeDetailLineDto>[],
      valuation: _valuation,
      settlementPlan: _plan,
      completionReady: false,
    ),
    const (ReturnExchangeValuationDto) => _valuation,
    _ => throw UnsupportedError('salesFixture<$T>() chưa hỗ trợ'),
  };
  return value as T;
}

final DateTime _now = DateTime.utc(2026, 7, 28);
const MoneyDto _zero = MoneyDto(amountMinor: 0, currencyCode: 'VND');
const MoneyDto _total = MoneyDto(amountMinor: 125000, currencyCode: 'VND');
const ActorSnapshotDto _actor = ActorSnapshotDto(
  actorId: 'fake-actor',
  displayName: 'Fake actor',
);

const ReturnExchangeSettlementPlanDto _plan = ReturnExchangeSettlementPlanDto(
  currencyCode: 'VND',
  netDifferenceMinor: 0,
  collectAmountMinor: 0,
  refundAmountMinor: 0,
  receivableCreateAmountMinor: 0,
  receivableReverseAmountMinor: 0,
  processedCollectMinor: 0,
  processedRefundMinor: 0,
  pendingReceivableCreateMinor: 0,
  pendingReceivableReverseMinor: 0,
  remainderCollectMinor: 0,
  remainderRefundMinor: 0,
  sourceOrderVersion: 1,
  sourceSettlementVersion: 1,
);

const ReturnExchangeValuationDto _valuation = ReturnExchangeValuationDto(
  returnValue: _total,
  exchangeValue: _total,
  settlementDifference: _zero,
  settlementPlan: _plan,
  sourceOrderVersion: 1,
);

final SalesOrderResultDto _orderResult = SalesOrderResultDto(
  order: const SalesOrderDto(
    salesOrderId: 'order-1',
    orderNumber: 'SO-000129',
    version: 3,
    lifecycleStatus: SalesOrderLifecycleStatus.completed,
    lockStatus: SalesOrderLockStatus.unlocked,
    total: MoneyDto(amountMinor: 4445238, currencyCode: 'VND'),
  ),
  committedAt: DateTime.utc(2026, 8, 12, 2, 41),
  store: const StoreSnapshotDto(
    storeId: 'store-1',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh Quận 1',
  ),
  seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
  customer: const CustomerSnapshotDto(
    customerId: 'customer-1',
    displayName: 'Nguyễn Văn An',
    phoneNumber: '0903456789',
  ),
);

const SalesOrderPaymentSummaryDto _paymentSummary = SalesOrderPaymentSummaryDto(
  status: SalesSettlementStatus.paid,
  orderTotal: _total,
  paidTotal: _total,
  outstandingTotal: _zero,
);
