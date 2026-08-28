/// Blocked response codes surfaced at the presentation boundary (TH-08).
abstract final class EInvoiceBlockedCodes {
  static const noPermission = 'NO_PERMISSION';
  static const notFound = 'NOT_FOUND';
  static const validationError = 'VALIDATION_ERROR';
  static const invalidStatus = 'INVALID_STATUS';
  static const stateChanged = 'STATE_CHANGED';
  static const systemError = 'SYSTEM_ERROR';
  static const providerNotConnected = 'PROVIDER_NOT_CONNECTED';
  static const providerAuthFailed = 'PROVIDER_AUTH_FAILED';
  static const providerUnavailable = 'PROVIDER_UNAVAILABLE';
  static const configNotReady = 'CONFIG_NOT_READY';
  static const issuanceNotReady = 'ISSUANCE_NOT_READY';
  static const buyerDataIncomplete = 'BUYER_DATA_INCOMPLETE';
  static const buyerTaxCodeRequired = 'BUYER_TAX_CODE_REQUIRED';
  static const orderNotCompleted = 'ORDER_NOT_COMPLETED';
  static const alreadyIssued = 'ALREADY_ISSUED';
  static const operationInProgress = 'OPERATION_IN_PROGRESS';
  static const resultUndetermined = 'RESULT_UNDETERMINED';
  static const documentUnavailable = 'DOCUMENT_UNAVAILABLE';
  static const deliveryNotSupported = 'DELIVERY_NOT_SUPPORTED';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
}
