enum SalesDraftStatus { active, converted, cancelled, expired }

enum CheckoutResultStatus {
  processing,
  succeeded,
  blocked,
  failed,
  uncertain,
}

enum SalesOrderLifecycleStatus { completed, cancelled }

enum SalesOrderLockStatus { unlocked, locked }

enum SalesSettlementStatus {
  unpaid,
  partiallyPaid,
  paid,
  partiallyRefunded,
  refunded,
  noBalance,
}

enum SalesPaymentStatus { pending, confirmed, failed, voided }

enum SalesPaymentMethod { cash, manualBankTransfer }

/// Stored payment row kind. Product UI only labels collection and refund.
enum SalesPaymentTransactionType { collection, refund, reversal }

enum SalesPaymentDirection { inflow, outflow }

enum SalesOrderCancellationStatus {
  requested,
  validating,
  confirmed,
  processing,
  completed,
  blocked,
  failed,
  cancelled,
}

enum ReturnExchangeStatus {
  /// Technical recovery only — not a user-managed draft list item (Phase 1).
  draft,
  confirmed,
  processing,
  completed,
  cancelled,
  blocked,
  failed,
}

enum SalesReceiptStatus { generated, superseded, archived }

enum IntegrationDeliveryStatus {
  notRequired,
  queued,
  delivered,
  retryScheduled,
  failed,
  deadLetter,
  unknown,
}

enum ReturnExchangeLineKind { returnLine, exchangeLine }

enum ReturnExchangeEntrySource {
  standard,
  fullReturnFromCancelAttempt,
}

enum SalesOrderReturnProjectionStatus { none, partiallyReturned, fullyReturned }
