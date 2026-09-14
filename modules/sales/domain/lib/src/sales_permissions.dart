/// Canonical permission codes owned by the Sales bounded context.
abstract final class SalesPermissions {
  static const createDraft = 'sales.draft.create';
  static const updateDraft = 'sales.draft.update';
  static const deleteDraft = 'sales.draft.delete';
  static const restoreDraft = 'sales.draft.restore';

  static const finalizeCheckout = 'sales.checkout.create';

  static const viewOrder = 'sales.order.view';
  static const viewOrderHistory = 'sales.order.history.view';
  static const lockOrder = 'sales.order.lock';
  static const unlockOrder = 'sales.order.unlock';
  static const cancelOrder = 'sales.order.cancel';

  static const viewPayment = 'sales.payment.view';
  static const recordPayment = 'sales.payment.record';
  static const refundPayment = 'sales.payment.refund';
  static const reconcileSettlement = 'sales.settlement.reconcile';

  static const viewReceipt = 'sales.receipt.view';
  static const generateReceipt = 'sales.receipt.generate';
  static const printReceipt = 'sales.receipt.print';
  static const shareReceipt = 'sales.receipt.share';
  static const archiveReceipt = 'sales.receipt.archive';

  static const createReturnExchange = 'sales.return_exchange.create';
  static const updateReturnExchange = 'sales.return_exchange.update';
  static const cancelReturnExchange = 'sales.return_exchange.cancel';
  static const confirmReturnExchange = 'sales.return_exchange.confirm';
  static const completeReturnExchange = 'sales.return_exchange.complete';
  static const viewReturnExchange = 'sales.return_exchange.view';

  static const values = <String>{
    createDraft,
    updateDraft,
    deleteDraft,
    restoreDraft,
    finalizeCheckout,
    viewOrder,
    viewOrderHistory,
    lockOrder,
    unlockOrder,
    cancelOrder,
    viewPayment,
    recordPayment,
    refundPayment,
    reconcileSettlement,
    viewReceipt,
    generateReceipt,
    printReceipt,
    shareReceipt,
    archiveReceipt,
    createReturnExchange,
    updateReturnExchange,
    cancelReturnExchange,
    confirmReturnExchange,
    completeReturnExchange,
    viewReturnExchange,
  };
}
